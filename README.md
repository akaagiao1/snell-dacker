# snell-dacker
适配于alpine

## 安装必要依赖
```bash
apk add --no-cache curl docker
```
## 下载并执行脚本（国内服务器若无法访问GitHub，请替换 raw.githubusercontent.com 为代理地址）
```bash
curl -sSL https://raw.githubusercontent.com/akaagiao1/snell-dacker/refs/heads/main/snell-docker.sh | sh -
```
## 或分步执行（推荐用于调试）
```
wget https://raw.githubusercontent.com/akaagiao1/snell-dacker/refs/heads/main/snell-docker.sh
```
```
chmod +x snell-docker.sh
```
```
./snell-docker.sh
```

由deepseek 改编 适用于alpine linux 
# 如需查找修改配置

1. 重启 Docker Compose 管理的服务
如果是通过 docker-compose.yml 或 docker compose 启动的服务，需使用以下命令：

# 进入项目目录（包含 docker-compose.yml）
```
cd /root/snell-docker
```
# 重启所有服务
```
docker compose restart
```

# 或指定服务名称（例如只重启 snell 服务）
```
docker compose restart snell
```
2. 完整停止后重新启动
如果需强制重建容器（例如配置文件修改后）：


# 停止并删除容器
```
docker compose down
```
# 重新构建镜像并启动
```
docker compose up -d --build
```
3. 仅重启单个容器
直接通过容器名称操作：

# 查找容器名称
```
docker ps --filter "name=snell"
```
# 重启容器
```
docker restart snell
```
