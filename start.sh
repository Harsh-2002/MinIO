#!/bin/bash
set -e

# Default port configuration
MINIO_API_PORT=${MINIO_API_PORT:-9000}
MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT:-9001}
MINIO_ADMIN_CONSOLE_PORT=${MINIO_ADMIN_CONSOLE_PORT:-9002}

# Default region configuration
export MINIO_REGION=${MINIO_REGION:-us-east-1}
export CONSOLE_MINIO_REGION=${CONSOLE_MINIO_REGION:-$MINIO_REGION}

echo "Starting object storage with web console..."
echo "API Port: ${MINIO_API_PORT}"
echo "Console Port: ${MINIO_CONSOLE_PORT}"
echo "Admin Console Port: ${MINIO_ADMIN_CONSOLE_PORT}"

# Start storage server
minio server /data --address ":${MINIO_API_PORT}" --console-address ":${MINIO_CONSOLE_PORT}" &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to start..."
MAX_RETRIES=30
RETRY_COUNT=0
FAST_POLL_ATTEMPTS=5

while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
    if curl -sf "http://localhost:${MINIO_API_PORT}/minio/health/live" >/dev/null 2>&1; then
        echo "✓ Server is ready!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    # Use sleep with fractional seconds for faster initial checks
    if [ "$RETRY_COUNT" -lt "$FAST_POLL_ATTEMPTS" ]; then
        sleep 0.5
    else
        sleep 1
    fi
done

if [ "$RETRY_COUNT" -eq "$MAX_RETRIES" ]; then
    echo "✗ Server failed to start within ${MAX_RETRIES} seconds"
    exit 1
fi

# Start web console
echo "Starting admin console on port ${MINIO_ADMIN_CONSOLE_PORT}..."
export CONSOLE_MINIO_SERVER="http://localhost:${MINIO_API_PORT}"
# Use more efficient random string generation
export CONSOLE_PBKDF_PASSPHRASE=${CONSOLE_PBKDF_PASSPHRASE:-$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)}
export CONSOLE_PBKDF_SALT=${CONSOLE_PBKDF_SALT:-$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 48)}

export CONSOLE_MINIO_REGION=${CONSOLE_MINIO_REGION:-$MINIO_REGION}
console server --port "${MINIO_ADMIN_CONSOLE_PORT}" &
CONSOLE_PID=$!

echo "✓ All services started successfully!"
echo "  - API: http://localhost:${MINIO_API_PORT}"
echo "  - Console: http://localhost:${MINIO_CONSOLE_PORT}"
echo "  - Admin Console: http://localhost:${MINIO_ADMIN_CONSOLE_PORT}"

# Wait for processes and handle exit
wait -n $SERVER_PID $CONSOLE_PID
EXIT_CODE=$?

echo "A service has stopped unexpectedly (exit code: ${EXIT_CODE})"
exit $EXIT_CODE