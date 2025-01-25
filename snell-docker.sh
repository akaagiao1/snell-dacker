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

# 安装基础依赖
install_deps() {
    echo -e "${CYAN}安装必要依赖...${RESET}"
    apk update
    apk add --no-cache curl docker docker-cli-compose coreutils
    rc-update add docker boot
    service docker start
}

# 检测是否已安装 Docker
check_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}Docker 已安装${RESET}"
        docker --version
    else
        echo -e "${YELLOW}正在安装 Docker...${RESET}"
        install_deps
        if ! command -v docker >/dev/null 2>&1; then
            echo -e "${RED}Docker 安装失败，请检查日志${RESET}"
            exit 1
        fi
    fi
}

# 清理旧版本 Docker Compose
cleanup_compose() {
    if [ -f "/usr/bin/docker-compose" ]; then
        echo -e "${YELLOW}移除旧版 docker-compose...${RESET}"
        apk del docker-compose >/dev/null 2>&1
    fi
}

# 生成随机数据
generate_random() {
    echo -e "${CYAN}生成随机配置...${RESET}"
    RANDOM_PORT=$(awk -v min=30000 -v max=65000 'BEGIN{srand(); print int(min+rand()*(max-min+1))}')
    RANDOM_PSK=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
}

# 检测架构并设置URL
set_arch() {
    case "$(uname -m)" in
        x86_64) DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v4.1.1-linux-amd64.zip" ;;
        aarch64|arm64) DOWNLOAD_URL="https://dl.nssurge.com/snell/snell-server-v4.1.1-linux-aarch64.zip" ;;
        *) echo -e "${RED}不支持的架构: $(uname -m)${RESET}"; exit 1 ;;
    esac
}

# 创建配置文件
create_config() {
    mkdir -p /root/snell-docker/snell-conf
    echo -e "${BLUE}创建 docker-compose.yml...${RESET}"
    cat > /root/snell-docker/docker-compose.yml << EOF
services:
  snell:
    image: accors/snell:latest
    container_name: snell
    restart: always
    network_mode: "host"
    volumes:
      - ./snell-conf/snell.conf:/etc/snell-server.conf
    environment:
      - SNELL_URL=$DOWNLOAD_URL
EOF

    echo -e "${BLUE}生成 snell.conf...${RESET}"
    cat > /root/snell-docker/snell-conf/snell.conf << EOF
[snell-server]
listen = 0.0.0.0:$RANDOM_PORT
psk = $RANDOM_PSK
ipv6 = false
EOF
}

# 获取公网信息
get_network_info() {
    HOST_IP=$(curl -s --connect-timeout 5 http://checkip.amazonaws.com || echo "IP查询失败")
    IP_COUNTRY=$(curl -s --connect-timeout 5 http://ipinfo.io/$HOST_IP/country || echo "国家未知")
}

# 输出配置信息
show_config() {
    echo -e "\n${GREEN}=== 部署完成 ===${RESET}"
    echo -e "服务器IP:   ${CYAN}$HOST_IP${RESET}"
    echo -e "监听端口:   ${YELLOW}$RANDOM_PORT${RESET}"
    echo -e "预共享密钥: ${PURPLE}$RANDOM_PSK${RESET}"
    echo -e "国家地区:   ${BLUE}$IP_COUNTRY${RESET}"

    echo -e "\n${GREEN}=== Surge 客户端配置 ===${RESET}"
    echo "${IP_COUNTRY} = snell, ${HOST_IP}, ${RANDOM_PORT}, psk = ${RANDOM_PSK}, version = 4, reuse = true" | tee /root/snell-docker/snell-conf/client.conf
}

# 主执行流程
main() {
    check_root
    check_docker
    cleanup_compose
    generate_random
    set_arch
    create_config

    echo -e "${CYAN}启动容器...${RESET}"
    cd /root/snell-docker && \
    docker compose pull && \
    docker compose up -d && \
    sleep 3 && \
    docker logs snell

    get_network_info
    show_config

    echo -e "\n${GREEN}配置文件路径: /root/snell-docker/snell-conf/snell.conf${RESET}"
    echo -e "${YELLOW}如需修改配置，请编辑后执行: docker compose restart${RESET}"
}

main
