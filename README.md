# MinIO + OpenMaxIO Console Docker Image

A custom Docker image that combines the latest MinIO server with the full-featured OpenMaxIO Console (community fork). This wrapper docker image provides everything you need in one image.

## What's Included

- **Latest MinIO Server** - Built from source (latest version)
- **OpenMaxIO Console** - Full-featured web UI (community fork of MinIO Console)
- **MinIO Client (mc)** - Command-line administration tools

## Why This Image?

MinIO removed pre-compiled binaries and full console features from recent releases. This image solves that by:
- Building MinIO from source with latest features
- Including OpenMaxIO Console with all admin features
- Providing a single, production-ready image

## Quick Start

```bash
# Build
docker build -t minio-openmaxio:latest .

# Run
docker run -d --name minio \
  -p 9000:9000 -p 9001:9001 -p 9090:9090 \
  -v ./data:/data \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=your-password \
  minio-openmaxio:latest
```

## Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **MinIO API** | http://localhost:9000 | S3-compatible API |
| **MinIO Console** | http://localhost:9001 | Basic built-in UI |
| **OpenMaxIO Console** | http://localhost:9090 | Full-featured admin UI ⭐ |

## Configuration

### Ports (Configurable)
```bash
-e MINIO_API_PORT=9000           # MinIO API port
-e MINIO_CONSOLE_PORT=9001       # MinIO console port  
-e OPENMAXIO_CONSOLE_PORT=9090   # OpenMaxIO console port
```

### Credentials
```bash
-e MINIO_ROOT_USER=admin
-e MINIO_ROOT_PASSWORD=your-secure-password
```

### Console Encryption (Optional)
```bash
-e CONSOLE_PBKDF_PASSPHRASE=your-passphrase
-e CONSOLE_PBKDF_SALT=your-salt
```

## Docker Compose

```yaml
services:
  minio:
    image: minio-openmaxio:latest
    ports:
      - "9000:9000"
      - "9001:9001" 
      - "9090:9090"
    volumes:
      - ./data:/data
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: your-password
```

## Building

```bash
# Default (latest MinIO)
docker build -t minio-openmaxio:latest .

# Specific MinIO version
docker build --build-arg MINIO_VERSION=RELEASE.2025-01-15T10-44-24Z -t minio-openmaxio:latest .
```

## Using MinIO Client

```bash
# Configure
docker exec minio mc alias set local http://localhost:9000 admin your-password

# Admin info
docker exec minio mc admin info local

# Create bucket
docker exec minio mc mb local/mybucket

# Upload file
docker exec minio mc cp /path/to/file local/mybucket/
```

## Security Notes

- Runs as non-root user (UID 1000)
- MinIO client binary verified with minisign
- Set proper data directory permissions: `sudo chown -R 1000:1000 ./data`
- Change default credentials in production
- Use TLS certificates by mounting to `/data/.minio/certs/`

## Health Checks

```bash
# Check if running
curl http://localhost:9000/minio/health/live

# View logs
docker logs minio
```

## Troubleshooting

**Permission denied:** `sudo chown -R 1000:1000 ./data`

**Port conflicts:** Use custom ports with `-e MINIO_API_PORT=8000`

**Service not starting:** Check logs with `docker logs minio`

## License

- MinIO: AGPL-3.0
- OpenMaxIO Console: AGPL-3.0  
- This Dockerfile: MIT

## Maintainer

Anurag Vishwakarma <av7312002@gmail.com>

---

**This is a wrapper image combining latest MinIO server with OpenMaxIO Console for a complete object storage solution.**