# MinIO + Admin Console Docker Image

A production-ready Docker image that combines the latest MinIO server with the full-featured MinIO Admin Console. Everything you need for object storage with a complete web interface.

## What's Included

- **Latest MinIO Server** - Built from source
- **MinIO Admin Console** - Full-featured web UI for management
- **MinIO Client (mc)** - Command-line tools

## Why This Image?

MinIO's recent releases removed pre-compiled binaries and full console features. This image provides:

- **Complete MinIO Server** - Built from source with latest features
- **Full Admin Console** - Complete web interface for management
- **Single Image** - No need for separate console containers
- **Production Ready** - Optimized for deployment

## Quick Start

### Docker Run
```bash
docker run -d --name minio \
  -p 9000:9000 -p 9001:9001 -p 9090:9090 \
  -v ./data:/data \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=your-password \
  -e MINIO_REGION=us-east-1 \
  -e CONSOLE_PBKDF_PASSPHRASE=your-passphrase \
  -e CONSOLE_PBKDF_SALT=your-salt \
  firstfinger/minio:latest
```

### Docker Compose
```bash
# Start with Docker Compose
docker compose up -d
```

```yaml
services:
  minio:
    image: firstfinger/minio:latest
    ports:
      - "9000:9000"  # MinIO API
      - "9001:9001"  # MinIO Console
      - "9090:9090"  # MinIO Admin Console
    volumes:
      - ./data:/data
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: your-password
      MINIO_REGION: us-east-1  # REQUIRED: Set your AWS region
      CONSOLE_PBKDF_PASSPHRASE: your-passphrase
      CONSOLE_PBKDF_SALT: your-salt
```

## Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **MinIO API** | http://localhost:9000 | S3-compatible API |
| **MinIO Console** | http://localhost:9001 | Basic built-in UI |
| **MinIO Admin Console** | http://localhost:9090 | Full-featured admin UI ⭐ |

## Essential Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MINIO_ROOT_USER` | Root username | `admin` |
| `MINIO_ROOT_PASSWORD` | Root password | `SecurePass123!` |
| `MINIO_REGION` | **REQUIRED** AWS S3 region | `us-east-1` |
| `CONSOLE_PBKDF_PASSPHRASE` | Console encryption passphrase | `your-secret-passphrase` |
| `CONSOLE_PBKDF_SALT` | Console encryption salt | `your-secret-salt` |

> **Note**: `CONSOLE_MINIO_REGION` automatically inherits from `MINIO_REGION` - no need to set it separately.

## Port Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIO_API_PORT` | `9000` | MinIO API port |
| `MINIO_CONSOLE_PORT` | `9001` | MinIO console port |
| `MINIO_ADMIN_CONSOLE_PORT` | `9090` | MinIO admin console port |

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

**Docker Compose:** Use `docker compose` (not `docker-compose`)

**Region errors:** Ensure `MINIO_REGION` is set (e.g., `us-east-1`, `ap-south-1`)

## Health Check

```bash
curl http://localhost:9000/minio/health/live
```

## License
You just DO WHAT THE FUCK YOU WANT TO. 