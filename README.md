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

# 由deepseek 改编 适用于alpine linux 
## 直接重启
```
rc-service docker restart
```

## 或分步操作（停止 → 启动）
```
rc-service docker stop
```
```
rc-service docker start
```
