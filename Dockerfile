FROM --platform=$TARGETPLATFORM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

# 创建目录并设置权限
RUN mkdir -p /app && addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# 复制二进制文件
COPY production_version_linux_amd64 /app/binary_amd64
COPY production_version_linux_arm64 /app/binary_arm64

# 【关键改动】直接在这里给二进制文件加权限，避免启动时权限不足
RUN chmod +x /app/binary_amd64 /app/binary_arm64

# 创建启动脚本 (使用更可靠的写入方式)
RUN printf '#!/bin/sh\n\
ARCH=$(uname -m)\n\
case "$ARCH" in\n\
  x86_64|amd64) BINARY="/app/binary_amd64" ;;\n\
  aarch64|arm64) BINARY="/app/binary_arm64" ;;\n\
  *) echo "Unsupported: $ARCH"; exit 1 ;;\n\
esac\n\
exec "$BINARY"\n' > /app/start.sh && chmod +x /app/start.sh

# 确保 appuser 拥有这些文件的所有权
RUN chown -R appuser:appgroup /app

USER 1001:1001

EXPOSE 8080

ENTRYPOINT ["/bin/sh", "/app/start.sh"]
