FROM --platform=$TARGETPLATFORM alpine:latest

# 安装必要的系统工具
RUN apk --no-cache add ca-certificates tzdata

# 创建非root用户
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 创建应用目录
RUN mkdir -p /app

# 根据构建参数决定复制哪个二进制文件
COPY production_version_linux_amd64 /app/binary_amd64
COPY production_version_linux_arm64 /app/binary_arm64

# 创建启动脚本，根据架构选择正确的二进制文件
RUN echo '#!/bin/sh\n'\
    'ARCH=$(uname -m)\n'\
    'case $ARCH in\n'\
    '  x86_64|amd64)\n'\
    '    BINARY="/app/binary_amd64"\n'\
    '    ;;\n'\
    '  aarch64|arm64)\n'\
    '    BINARY="/app/binary_arm64"\n'\
    '    ;;\n'\
    '  *)\n'\
    '    echo "Unsupported architecture: $ARCH"\n'\
    '    exit 1\n'\
    '    ;;\n'\
    'esac\n'\
    '\n'\
    'chmod +x "$BINARY"\n'\
    'exec "$BINARY"' > /app/start.sh && \
    chmod +x /app/start.sh

# 切换到非root用户
USER 1001:1001

# 暴露端口
EXPOSE 8080

# 启动命令
ENTRYPOINT ["/app/start.sh"]