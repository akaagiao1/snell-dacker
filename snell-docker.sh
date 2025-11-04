#!/bin/sh
# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# 检查是否以 root 权限运行
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}请以 root 权限运行此脚本${RESET}"
        exit 1
    fi
}

# 更新系统包和升级 (Alpine 使用 apk)
apk update && apk upgrade

# 检测是否已安装 Docker (Alpine 社区版仓库提供 Docker)
if command -v docker >/dev/null 2>&1; then
    echo "Docker 已经安装"
    docker --version
else
    echo "正在安装 Docker"
    # 安装 Docker (Alpine 方式)
    apk add docker
    if [ $? -ne 0 ]; then
        echo "Docker 安装失败，请检查网络连接或安装脚本"
        exit 1
    fi
    # 将当前用户加入 docker 组 (可选，按需调整用户名)
    addgroup $USER docker
    # 启动 Docker 服务并设置开机自启
    rc-update add docker boot
    service docker start
    echo "Docker 安装成功！"
fi

# 判断并卸载不同版本的 Docker Compose（如果有）
if [ -f "/usr/local/bin/docker-compose" ]; then
    rm /usr/local/bin/docker-compose
fi

if [ -d "$HOME/.docker/cli-plugins/" ]; then
    rm -rf $HOME/.docker/cli-plugins/
fi

# 安装 Docker Compose (Alpine 可 apk 安装或直接下载二进制文件)
if command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose 已经安装"
    docker-compose --version
else
    echo "正在安装 Docker Compose"
    apk add docker-compose
    if [ $? -ne 0 ]; then
        echo "Docker Compose 安装失败，请检查网络连接或安装脚本"
        exit 1
    fi
    echo "Docker Compose 安装成功！"
fi

# 创建所需目录
mkdir -p /root/snell-docker/snell-conf

# 生成随机端口和密码 (确保使用兼容的命令)
RANDOM_PORT=$(awk 'BEGIN{srand(); print int(rand()*(65000-30000+1))+30000}')
RANDOM_PSK=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)

# 检测系统架构
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v5.0.0-linux-amd64.zip"
elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v5.0.0-linux-aarch64.zip"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

# 创建 docker-compose.yml
cat > /root/snell-docker/docker-compose.yml << EOF
services:
  snell:
    image: accors/snell:latest
    container_name: snell
    restart: always
    network_mode: host
    volumes:
      - ./snell-conf/snell.conf:/etc/snell-server.conf
    environment:
      - SNELL_URL=$DOWNLOAD_URL
EOF

# 创建 snell.conf 配置文件
cat > /root/snell-docker/snell-conf/snell.conf << EOF
[snell-server]
listen = ::0:$RANDOM_PORT
psk = $RANDOM_PSK
ipv6 = true
EOF

# 切换目录
cd /root/snell-docker

# 拉取并启动 Docker 容器
docker compose pull && docker compose up -d && sleep 3 && docker logs snell

# 获取本机IP地址 (确保 curl 已安装)
HOST_IP=$(curl -s http://checkip.amazonaws.com || echo "无法获取 IP 地址")

# 获取IP所在国家
IP_COUNTRY=$(curl -s http://ipinfo.io/$HOST_IP/country || echo "无法获取国家信息")

# 输出客户端信息
echo -e "${GREEN}Snell 示例配置${RESET}"
cat << EOF > /root/snell-docker/snell-conf/snell.txt
${IP_COUNTRY} = snell, ${HOST_IP}, ${RANDOM_PORT}, psk = ${RANDOM_PSK}, version = 5, reuse = true
EOF
cat /root/snell-docker/snell-conf/snell.txt
