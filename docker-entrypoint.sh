#!/bin/bash
# Docker 入口脚本 - 启动代理和应用

# VLESS 代理配置（从环境变量读取）
VLESS_UUID=${VLESS_UUID:-"c95f88a7-da3a-481b-8cd1-6dd6e1c03a58"}
VLESS_SERVER=${VLESS_SERVER:-"text.coziai.cn"}
VLESS_PORT=${VLESS_PORT:-"58794"}
VLESS_PBK=${VLESS_PBK:-"x47JvY65CWmQesQuCW1udHKHQOA3cIEsmh0rNuEIn1c"}
VLESS_SNI=${VLESS_SNI:-"yahoo.com"}
VLESS_SID=${VLESS_SID:-"baf5c3"}
VLESS_SPX=${VLESS_SPX:-"/"}

XRAY_LOG=/tmp/xray.log
SOCKS_PORT=20808
PROXY_TEST_URL=${PROXY_TEST_URL:-"https://huggingface.co"}

# 创建 Xray 配置（开启访问日志和错误日志）
cat > /tmp/xray-config.json <<EOFX
{
  "log": {
    "access": "/tmp/xray-access.log",
    "error": "/tmp/xray-error.log",
    "loglevel": "warning"
  },
  "inbounds": [{
    "listen": "127.0.0.1",
    "port": $SOCKS_PORT,
    "protocol": "socks",
    "settings": {
      "auth": "noauth",
      "udp": true
    }
  }],
  "outbounds": [{
    "protocol": "vless",
    "settings": {
      "vnext": [{
        "address": "$VLESS_SERVER",
        "port": $VLESS_PORT,
        "users": [{
          "id": "$VLESS_UUID",
          "encryption": "none",
          "flow": "xtls-rprx-vision"
        }]
      }]
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "publicKey": "$VLESS_PBK",
        "shortId": "$VLESS_SID",
        "serverName": "$VLESS_SNI",
        "fingerprint": "chrome"
      },
      "tcpSettings": {
        "header": {
          "type": "none"
        }
      }
    }
  }]
}
EOFX

# 启动 Xray 代理（后台运行，日志写入文件）
echo "[Proxy] Starting Xray proxy (server: $VLESS_SERVER:$VLESS_PORT)..."
/usr/local/bin/xray run -c /tmp/xray-config.json > "$XRAY_LOG" 2>&1 &
XRAY_PID=$!

# 等待 SOCKS 端口就绪（最多等待 10 秒）
echo "[Proxy] Waiting for SOCKS port $SOCKS_PORT to be ready..."
for i in {1..10}; do
    if nc -z 127.0.0.1 "$SOCKS_PORT" 2>/dev/null; then
        echo "[Proxy] SOCKS port $SOCKS_PORT is ready (took ${i}s)."
        break
    fi
    if [ "$i" -eq 10 ]; then
        echo "[Proxy] WARNING: SOCKS port $SOCKS_PORT not ready after 10s. Xray may have failed to start."
        echo "[Proxy] --- Xray startup log ---"
        cat "$XRAY_LOG" 2>/dev/null || true
        echo "[Proxy] --- End of Xray log ---"
    fi
    sleep 1
done

# 设置代理环境变量
export http_proxy=socks5://127.0.0.1:$SOCKS_PORT
export https_proxy=socks5://127.0.0.1:$SOCKS_PORT
export HTTP_PROXY=socks5://127.0.0.1:$SOCKS_PORT
export HTTPS_PROXY=socks5://127.0.0.1:$SOCKS_PORT
export no_proxy=localhost,127.0.0.1,neo4j,qdrant,dashscope.aliyuncs.com,aliyuncs.com

# 验证代理连通性（通过代理访问测试 URL）
echo "[Proxy] Testing connectivity through proxy -> $PROXY_TEST_URL ..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --socks5-hostname 127.0.0.1:"$SOCKS_PORT" \
    --max-time 15 \
    "$PROXY_TEST_URL" 2>/dev/null)
if [ -z "$HTTP_CODE" ]; then
    echo "[Proxy] ✗ Proxy connectivity test FAILED (no response / curl error)."
    echo "[Proxy] The proxy may be unreachable or curl encountered a network error."
    echo "[Proxy] --- Xray error log ---"
    cat /tmp/xray-error.log 2>/dev/null || true
    echo "[Proxy] --- End of error log ---"
    echo "[Proxy] Tip: check VLESS_SERVER / VLESS_UUID / VLESS_PBK environment variables."
    echo "[Proxy] Continuing application startup anyway..."
elif [[ "$HTTP_CODE" =~ ^[23] ]]; then
    echo "[Proxy] ✓ Proxy connectivity test PASSED (HTTP $HTTP_CODE). Proxy is working."
else
    echo "[Proxy] ✗ Proxy connectivity test FAILED (HTTP $HTTP_CODE)."
    echo "[Proxy] The proxy may be misconfigured or the server is unreachable."
    echo "[Proxy] --- Xray error log ---"
    cat /tmp/xray-error.log 2>/dev/null || true
    echo "[Proxy] --- End of error log ---"
    echo "[Proxy] Tip: check VLESS_SERVER / VLESS_UUID / VLESS_PBK environment variables."
    echo "[Proxy] Continuing application startup anyway..."
fi

echo "[Proxy] Proxy configured. Starting application..."

# 清理函数
cleanup() {
    echo "[Proxy] Stopping Xray (PID $XRAY_PID)..."
    kill $XRAY_PID 2>/dev/null
}

# 注册清理
trap cleanup EXIT TERM INT

# 启动应用
exec npm run dev
