FROM mcr.microsoft.com/devcontainers/python:1-3.11-bookworm

ARG INSTALL_EMBEDDING=true
ENV NVM_DIR=/usr/local/nvm
ENV PATH=${NVM_DIR}/versions/node/v20.19.0/bin:${PATH}

# 安装 Node.js 20（Vite 7 需要 Node 20.19+）及必要工具
RUN rm -f /etc/apt/sources.list.d/yarn.list /etc/apt/sources.list.d/yarn.sources \
 && sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources \
 && apt-get -o Acquire::Retries=6 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 update \
 && apt-get install -y --no-install-recommends curl ca-certificates procps wget unzip netcat-openbsd \
 && mkdir -p ${NVM_DIR} \
 && curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
 && bash -lc '. ${NVM_DIR}/nvm.sh && nvm install 20.19.0 && nvm alias default 20.19.0' \
 && ln -sf ${NVM_DIR}/versions/node/v20.19.0/bin/node /usr/local/bin/node \
 && ln -sf ${NVM_DIR}/versions/node/v20.19.0/bin/npm /usr/local/bin/npm \
 && ln -sf ${NVM_DIR}/versions/node/v20.19.0/bin/npx /usr/local/bin/npx \
 && node -v \
 && npm -v \
 && rm -rf /var/lib/apt/lists/*

# 安装 Xray 客户端（用于访问 HuggingFace）
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="64"; \
    elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64-v8a"; \
    fi && \
        (wget -O /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-${ARCH}.zip \
            && unzip /tmp/xray.zip -d /usr/local/bin/ xray \
            && chmod +x /usr/local/bin/xray \
            && rm /tmp/xray.zip) \
        || echo "Xray download skipped due to network limits"

WORKDIR /app

# 先复制依赖描述文件以利用缓存
COPY package.json package-lock.json ./
COPY frontend/package.json frontend/package-lock.json ./frontend/
COPY backend/requirements.txt ./backend/

# 安装前端依赖（官方 npm 源优先，失败时回退镜像）
RUN (npm ci --registry=https://registry.npmjs.org --fetch-retries=5 --fetch-retry-mintimeout=20000 --fetch-retry-maxtimeout=120000 --fetch-timeout=600000 \
 || npm ci --registry=https://registry.npmmirror.com --fetch-retries=5 --fetch-retry-mintimeout=20000 --fetch-retry-maxtimeout=120000 --fetch-timeout=600000) \
 && (npm ci --prefix frontend --registry=https://registry.npmjs.org --fetch-retries=5 --fetch-retry-mintimeout=20000 --fetch-retry-maxtimeout=120000 --fetch-timeout=600000 \
 || npm ci --prefix frontend --registry=https://registry.npmmirror.com --fetch-retries=5 --fetch-retry-mintimeout=20000 --fetch-retry-maxtimeout=120000 --fetch-timeout=600000)

# 安装后端依赖
# 说明：
# 1. sentence-transformers 会拉取 torch；在 Apple Silicon / ARM Linux 上默认索引可能误选到巨大的 CUDA 轮子，导致构建极慢
# 2. 这里对 ARM 平台优先使用 PyTorch CPU wheel 索引，避免下载 nvidia_* / triton 等超大包
# 3. 也支持通过 --build-arg INSTALL_EMBEDDING=false 跳过 embedding 相关依赖，加快首次构建
RUN set -eux; \
 cp backend/requirements.txt /tmp/requirements.txt; \
 if [ "${INSTALL_EMBEDDING}" != "true" ]; then \
     grep -v '^sentence-transformers==' /tmp/requirements.txt > /tmp/requirements.docker.txt; \
 else \
     cp /tmp/requirements.txt /tmp/requirements.docker.txt; \
 fi; \
 ARCH="$(uname -m)"; \
 if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
     export PIP_EXTRA_INDEX_URL="https://download.pytorch.org/whl/cpu"; \
 else \
     export PIP_EXTRA_INDEX_URL=""; \
 fi; \
 for i in 1 2 3; do \
     PIP_CONFIG_FILE=/dev/null PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_DEFAULT_TIMEOUT=1200 PIP_INDEX_URL=https://pypi.org/simple PIP_EXTRA_INDEX_URL="${PIP_EXTRA_INDEX_URL}" pip install --prefer-binary --retries 12 -r /tmp/requirements.docker.txt && break; \
     PIP_CONFIG_FILE=/dev/null PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_DEFAULT_TIMEOUT=1200 PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple PIP_EXTRA_INDEX_URL="${PIP_EXTRA_INDEX_URL}" pip install --prefer-binary --retries 12 -r /tmp/requirements.docker.txt && break; \
     if [ "$i" -eq 3 ]; then exit 1; fi; \
     echo "pip install failed on primary and fallback index, retrying in 20s (attempt $i/3)"; \
     sleep 20; \
 done

# 复制项目源码
COPY . .

# 创建 HuggingFace 缓存目录（本地模型由 docker-compose 卷挂载提供）
RUN mkdir -p /root/.cache/huggingface/hub/local_model

EXPOSE 3000 5001

# 复制入口脚本
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 入口点：先启动代理，再启动应用
ENTRYPOINT ["docker-entrypoint.sh"]
