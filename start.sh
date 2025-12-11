#!/bin/bash
set -e

# Default port configuration
MINIO_API_PORT=${MINIO_API_PORT:-9000}
MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT:-9001}
MINIO_ADMIN_CONSOLE_PORT=${MINIO_ADMIN_CONSOLE_PORT:-9002}

# Default region configuration
export MINIO_REGION=${MINIO_REGION:-us-east-1}
export CONSOLE_MINIO_REGION=${CONSOLE_MINIO_REGION:-$MINIO_REGION}

# TLS configuration
MINIO_CERTS_DIR=${MINIO_CERTS_DIR:-/data/.minio/certs}
CERT_PUBLIC="${MINIO_CERTS_DIR}/public.crt"
CERT_PRIVATE="${MINIO_CERTS_DIR}/private.key"
USE_TLS=false
HEALTH_SCHEME=http
HEALTH_FLAGS="-sf"
SERVER_SCHEME=http

if [ -f "${CERT_PUBLIC}" ] && [ -f "${CERT_PRIVATE}" ]; then
    USE_TLS=true
    HEALTH_SCHEME=https
    HEALTH_FLAGS="-sfk"
    SERVER_SCHEME=https
    echo "TLS certificates detected in ${MINIO_CERTS_DIR}"
fi

mkdir -p "${MINIO_CERTS_DIR}" >/dev/null 2>&1 || true

echo "Starting object storage with web console..."
echo "API Port: ${MINIO_API_PORT}"
echo "Console Port: ${MINIO_CONSOLE_PORT}"
echo "Admin Console Port: ${MINIO_ADMIN_CONSOLE_PORT}"

# Start storage server
minio server --certs-dir "${MINIO_CERTS_DIR}" /data \
    --address ":${MINIO_API_PORT}" \
    --console-address ":${MINIO_CONSOLE_PORT}" &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to start..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl ${HEALTH_FLAGS} ${HEALTH_SCHEME}://localhost:${MINIO_API_PORT}/minio/health/live >/dev/null 2>&1; then
        echo "✓ Server is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "✗ Server failed to start within ${MAX_RETRIES} seconds"
    exit 1
fi

# Start web console
echo "Starting admin console on port ${MINIO_ADMIN_CONSOLE_PORT}..."
export CONSOLE_MINIO_SERVER="${SERVER_SCHEME}://localhost:${MINIO_API_PORT}"
export CONSOLE_PBKDF_PASSPHRASE=${CONSOLE_PBKDF_PASSPHRASE:-$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)}
export CONSOLE_PBKDF_SALT=${CONSOLE_PBKDF_SALT:-$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 48)}

export CONSOLE_MINIO_REGION=${CONSOLE_MINIO_REGION:-$MINIO_REGION}
console server --port ${MINIO_ADMIN_CONSOLE_PORT} &
CONSOLE_PID=$!

echo "✓ All services started successfully!"
echo "  - API: ${SERVER_SCHEME}://localhost:${MINIO_API_PORT}"
echo "  - Console: ${SERVER_SCHEME}://localhost:${MINIO_CONSOLE_PORT}"
echo "  - Admin Console: http://localhost:${MINIO_ADMIN_CONSOLE_PORT}"

# Wait for processes and handle exit
wait -n $SERVER_PID $CONSOLE_PID
EXIT_CODE=$?

echo "A service has stopped unexpectedly (exit code: ${EXIT_CODE})"
exit $EXIT_CODE