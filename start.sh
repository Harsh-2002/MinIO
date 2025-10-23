#!/bin/bash
set -e

# Default port configuration
MINIO_API_PORT=${MINIO_API_PORT:-9000}
MINIO_CONSOLE_PORT=${MINIO_CONSOLE_PORT:-9001}
OPENMAXIO_CONSOLE_PORT=${OPENMAXIO_CONSOLE_PORT:-9090}

echo "Starting object storage with web console..."
echo "API Port: ${MINIO_API_PORT}"
echo "Console Port: ${MINIO_CONSOLE_PORT}"
echo "Web Console Port: ${OPENMAXIO_CONSOLE_PORT}"

# Start storage server
minio server /data --address ":${MINIO_API_PORT}" --console-address ":${MINIO_CONSOLE_PORT}" &
SERVER_PID=$!

# Wait for server to be ready
echo "Waiting for server to start..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -sf http://localhost:${MINIO_API_PORT}/minio/health/live >/dev/null 2>&1; then
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
echo "Starting web console on port ${OPENMAXIO_CONSOLE_PORT}..."
export CONSOLE_MINIO_SERVER="http://localhost:${MINIO_API_PORT}"
export CONSOLE_PBKDF_PASSPHRASE="${CONSOLE_PBKDF_PASSPHRASE:-SECRET}"
export CONSOLE_PBKDF_SALT="${CONSOLE_PBKDF_SALT:-SECRET}"

console server --port ${OPENMAXIO_CONSOLE_PORT} &
CONSOLE_PID=$!

echo "✓ All services started successfully!"
echo "  - API: http://localhost:${MINIO_API_PORT}"
echo "  - Console: http://localhost:${MINIO_CONSOLE_PORT}"
echo "  - Web Console: http://localhost:${OPENMAXIO_CONSOLE_PORT}"

# Wait for processes and handle exit
wait -n $SERVER_PID $CONSOLE_PID
EXIT_CODE=$?

echo "A service has stopped unexpectedly (exit code: ${EXIT_CODE})"
exit $EXIT_CODE