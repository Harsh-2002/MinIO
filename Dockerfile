# Multi-stage build for object storage with web console
ARG MINIO_VERSION=latest

# Build web console UI
FROM node:18-alpine AS console-ui-builder
WORKDIR /app
ENV GIT_TERMINAL_PROMPT=0
RUN apk add --no-cache git jq && \
    git clone https://github.com/OpenMaxIO/openmaxio-object-browser.git . && \
    git checkout openMaxIO-main && \
    MDS_REF=$(jq -r '.dependencies.mds' web-app/package.json) && \
    MDS_URL=$(echo "$MDS_REF" | cut -d'#' -f1) && \
    MDS_COMMIT=$(echo "$MDS_REF" | cut -d'#' -f2) && \
    git clone "$MDS_URL" /tmp/mds && \
    cd /tmp/mds && git checkout "$MDS_COMMIT" && \
    cd /app/web-app && \
    jq '.dependencies.mds = "file:///tmp/mds"' package.json > /tmp/pkg.json && \
    mv /tmp/pkg.json package.json && \
    corepack enable && \
    yarn install && \
    yarn build

# Build console binary
FROM golang:1.24-alpine AS console-builder

# Add architecture arguments
ARG TARGETARCH
ARG TARGETOS=linux
WORKDIR /app
RUN apk add --no-cache git make && \
    git clone https://github.com/OpenMaxIO/openmaxio-object-browser.git . && \
    git checkout openMaxIO-main
COPY --from=console-ui-builder /app/web-app/build ./web-app/build

# Set GOOS and GOARCH for proper cross-compilation
ENV GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=0
RUN make console

# Build storage server from source
FROM golang:1.24-alpine AS server-builder

ARG MINIO_VERSION=latest

# Add architecture arguments
ARG TARGETARCH
ARG TARGETOS=linux

ENV GOPATH=/go
ENV CGO_ENABLED=0

# Set GOOS and GOARCH for proper cross-compilation
ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}

WORKDIR /workspace

# Install build dependencies
RUN apk add --no-cache ca-certificates git make curl bash && \
    go install aead.dev/minisign/cmd/minisign@v0.2.1

# Clone and build server
RUN git clone https://github.com/minio/minio.git . && \
    if [ "$MINIO_VERSION" != "latest" ]; then \
        echo "Checking out version: $MINIO_VERSION" && \
        git checkout ${MINIO_VERSION}; \
    else \
        echo "Building from latest master"; \
    fi

# Build server binary
RUN COMMIT_ID=$(git rev-parse --short HEAD) && \
    echo "Building version: $MINIO_VERSION commit: $COMMIT_ID" && \
    CGO_ENABLED=0 go build -trimpath \
    -ldflags "-s -w -X github.com/minio/minio/cmd.ReleaseTag=${MINIO_VERSION}" \
    -o /usr/bin/minio . && \
    /usr/bin/minio --version

# Download and verify client binary - use TARGETARCH instead of BUILDARCH
RUN curl -s -q https://dl.min.io/client/mc/release/linux-${TARGETARCH}/mc -o /usr/bin/mc && \
    curl -s -q https://dl.min.io/client/mc/release/linux-${TARGETARCH}/mc.minisig -o /usr/bin/mc.minisig && \
    chmod +x /usr/bin/mc && \
    /go/bin/minisign -Vqm /usr/bin/mc -x /usr/bin/mc.minisig -P RWTx5Zr1tiHQLwG9keckT0c45M3AGeHD6IvimQHpyRywVWGbP1aVSGav && \
    /usr/bin/mc --version

# Final runtime image
FROM alpine:latest

ARG MINIO_VERSION=latest
ARG TARGETARCH

LABEL maintainer="Anurag Vishwakarma <av7312002@gmail.com>" \
      version="${MINIO_VERSION}" \
      org.opencontainers.image.source="https://github.com/minio/minio" \
      org.opencontainers.image.version="${MINIO_VERSION}" \
      org.opencontainers.image.licenses="AGPL-3.0"

# Install runtime dependencies
RUN apk add --no-cache ca-certificates curl bash && \
    mkdir -p /data /etc/minio/console

# Copy binaries
COPY --from=server-builder /usr/bin/minio /usr/bin/minio
COPY --from=server-builder /usr/bin/mc /usr/bin/mc
COPY --from=console-builder /app/console /usr/bin/console

# Copy license files
COPY --from=server-builder /workspace/CREDITS /licenses/CREDITS
COPY --from=server-builder /workspace/LICENSE /licenses/LICENSE

# Copy startup script
COPY start.sh /usr/bin/start.sh
RUN chmod +x /usr/bin/start.sh

# Server configuration
ENV MINIO_UPDATE_MINISIGN_PUBKEY="RWTx5Zr1tiHQLwG9keckT0c45M3AGeHD6IvimQHpyRywVWGbP1aVSGav" \
    MC_CONFIG_DIR=/tmp/.mc

# Console configuration
ENV CONSOLE_MINIO_SERVER=http://localhost:9000

# Configurable ports
ENV MINIO_API_PORT=9000 \
    MINIO_CONSOLE_PORT=9001 \
    MINIO_ADMIN_CONSOLE_PORT=9002

# Expose ports
EXPOSE 9000 9001 9002

# Health check (respects TLS certificates if present)
HEALTHCHECK --interval=30s --timeout=20s --start-period=5s --retries=3 \
    CMD sh -c 'CERT_DIR="${MINIO_CERTS_DIR:-/data/.minio/certs}"; SCHEME="http"; FLAGS="-sf"; \
    if [ -f "${CERT_DIR}/public.crt" ] && [ -f "${CERT_DIR}/private.key" ]; then \
      SCHEME="https"; FLAGS="-sfk"; \
    fi; \
    curl ${FLAGS} ${SCHEME}://localhost:${MINIO_API_PORT}/minio/health/live || exit 1'

WORKDIR /data

# Start services
CMD ["/usr/bin/start.sh"]