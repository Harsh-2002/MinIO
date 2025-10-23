# MinIO + OpenMaxIO Console Docker Image

A custom Docker image that combines the latest MinIO server with the full-featured OpenMaxIO Console (community fork). This wrapper provides everything you need in one image.

## What's Included

- **Latest MinIO Server** - Built from source
- **OpenMaxIO Console** - Full-featured web UI (community fork)
- **MinIO Client (mc)** - Command-line tools

## Why This Image?

MinIO removed pre-compiled binaries and full console features from recent releases. This image solves that by:
- Building MinIO from source with latest features
- Including OpenMaxIO Console with all admin features
- Providing a single, production-ready image

## Quick Start

### Docker Run
```bash
docker run -d --name minio \
  -p 9000:9000 -p 9001:9001 -p 9090:9090 \
  -v ./data:/data \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=your-password \
  firstfinger/minio-openmaxio:latest
```

### Docker Compose
```yaml
services:
  minio:
    image: firstfinger/minio-openmaxio:latest
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

## Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **MinIO API** | http://localhost:9000 | S3-compatible API |
| **MinIO Console** | http://localhost:9001 | Basic built-in UI |
| **OpenMaxIO Console** | http://localhost:9090 | Full-featured admin UI ⭐ |

## Essential Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MINIO_ROOT_USER` | Root username | `admin` |
| `MINIO_ROOT_PASSWORD` | Root password | `SecurePass123!` |
| `CONSOLE_PBKDF_PASSPHRASE` | Console encryption passphrase | `your-secret-passphrase` |
| `CONSOLE_PBKDF_SALT` | Console encryption salt | `your-secret-salt` |

## Port Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIO_API_PORT` | `9000` | MinIO API port |
| `MINIO_CONSOLE_PORT` | `9001` | MinIO console port |
| `OPENMAXIO_CONSOLE_PORT` | `9090` | OpenMaxIO console port |

## Using MinIO Client

```bash
# Configure
docker exec minio mc alias set local http://localhost:9000 admin your-password

# Create bucket
docker exec minio mc mb local/mybucket

# Upload file
docker exec minio mc cp /path/to/file local/mybucket/
```

## Security Notes

- Runs as non-root user (UID 1000)
- Set proper data directory permissions: `sudo chown -R 1000:1000 ./data`
- Change default credentials in production
- Use TLS certificates by mounting to `/data/.minio/certs/`

## Troubleshooting

**Permission denied:** `sudo chown -R 1000:1000 ./data`

**Port conflicts:** Use custom ports with `-e MINIO_API_PORT=8000`

**Service not starting:** Check logs with `docker logs minio`

## Health Check

```bash
curl http://localhost:9000/minio/health/live
```

## License
- You just DO WHAT THE FUCK YOU WANT TO. 