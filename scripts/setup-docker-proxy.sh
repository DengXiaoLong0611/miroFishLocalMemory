#!/bin/bash
# 配置 Docker 使用 Clash 代理，解决中国大陆拉取镜像超时问题
# Configure Docker to use Clash proxy to fix TLS timeout when pulling images in China
#
# 使用方法 / Usage:
#   bash scripts/setup-docker-proxy.sh [PROXY_HOST] [PROXY_PORT]
#
# 默认参数 / Defaults:
#   PROXY_HOST=127.0.0.1  (Clash 默认监听本地回环 / Clash default listen address)
#   PROXY_PORT=7890        (Clash 默认 HTTP 代理端口 / Clash default HTTP proxy port)
#
# 示例 / Examples:
#   bash scripts/setup-docker-proxy.sh              # 使用默认 127.0.0.1:7890
#   bash scripts/setup-docker-proxy.sh 127.0.0.1 7890

set -e

PROXY_HOST="${1:-127.0.0.1}"
PROXY_PORT="${2:-7890}"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
DAEMON_JSON="/etc/docker/daemon.json"

echo "=== 配置 Docker 代理 ==="
echo "代理地址: ${PROXY_URL}"
echo ""

# ── 步骤 1: 配置 Docker daemon 代理（通过 systemd drop-in） ──────────────────
# 这是 Docker 官方推荐方式，让 dockerd 自身走代理（影响 docker pull）
DOCKER_SERVICE_DIR="/etc/systemd/system/docker.service.d"
PROXY_CONF="${DOCKER_SERVICE_DIR}/http-proxy.conf"

echo "[1/3] 配置 dockerd 代理 -> ${PROXY_CONF}"
sudo mkdir -p "${DOCKER_SERVICE_DIR}"
sudo tee "${PROXY_CONF}" > /dev/null <<EOF
[Service]
Environment="HTTP_PROXY=${PROXY_URL}"
Environment="HTTPS_PROXY=${PROXY_URL}"
Environment="NO_PROXY=localhost,127.0.0.1,::1"
EOF
echo "      完成 ✓"

# ── 步骤 2: 清除 daemon.json 中的国内镜像加速器（已失效的会导致 TLS 超时） ──
echo "[2/3] 清理 daemon.json 中的失效镜像加速器 -> ${DAEMON_JSON}"
if [ -f "${DAEMON_JSON}" ]; then
    # 备份原文件
    sudo cp "${DAEMON_JSON}" "${DAEMON_JSON}.bak.$(date +%Y%m%d%H%M%S).$$"
    echo "      已备份原文件"
    # 移除 registry-mirrors 字段，保留其余配置
    sudo python3 - <<'PYEOF'
import json
path = "/etc/docker/daemon.json"
try:
    with open(path) as f:
        cfg = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    cfg = {}
if "registry-mirrors" in cfg:
    cfg.pop("registry-mirrors")
    print("      已移除 registry-mirrors 字段")
else:
    print("      registry-mirrors 字段不存在，无需移除")
with open(path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
else
    echo "      ${DAEMON_JSON} 不存在，跳过"
fi
echo "      完成 ✓"

# ── 步骤 3: 重启 Docker daemon ────────────────────────────────────────────────
echo "[3/3] 重启 Docker daemon ..."
sudo systemctl daemon-reload
sudo systemctl restart docker
echo "      完成 ✓"

echo ""
echo "=== 配置完成 ==="
echo "现在可以运行: docker compose up -d"
echo ""
echo "验证代理是否生效:"
echo "  docker info | grep -A3 'HTTP Proxy'"
