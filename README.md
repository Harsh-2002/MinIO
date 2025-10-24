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
  -p 9000:9000 \
  -p 9001:9001 \
  -p 9002:9002 \
  -v ./data:/data \
  -e MINIO_ROOT_USER=UL5YXh4vjy3yEAaS4eW8 \
  -e MINIO_ROOT_PASSWORD=36bpUPfiptWp6M7uBFsM75uKbPXZgW \
  firstfinger/minio:latest-amd64
```

## Image Tags

This image is built for multiple architectures. You must select the tag that matches your system's architecture:

- **`latest-amd64`**: The image for `x86-64` (amd64) architectures.
- **`latest-arm64`**: The image for `arm64` architectures.

For example, to run on an `x86-64` machine:
```bash
docker run -d --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -p 9002:9002 \
  -v ./data:/data \
  -e MINIO_ROOT_USER=UL5YXh4vjy3yEAaS4eW8 \
  -e MINIO_ROOT_PASSWORD=36bpUPfiptWp6M7uBFsM75uKbPXZgW \
  firstfinger/minio:latest-amd64
```

### Docker Compose

By default, the `docker-compose.yml` file uses the `latest-amd64` tag. To use the `arm64` image, create a `.env` file in the same directory with the following content:

```
MINIO_IMAGE_TAG=latest-arm64
```

Then, run the standard command:

```bash
docker compose up -d
```

## Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **MinIO API** | http://localhost:9000 | S3-compatible API |
| **MinIO Console** | http://localhost:9001 | Basic built-in UI |
| **MinIO Admin Console** | http://localhost:9002 | Full-featured admin UI ⭐ |

## Essential Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MINIO_ROOT_USER` | Root username | `admin` |
| `MINIO_ROOT_PASSWORD` | Root password | `SecurePass123!` |
| `MINIO_REGION` | AWS S3 region (defaults to us-east-1) | `us-east-1` |

## Port Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIO_API_PORT` | `9000` | MinIO API port |
| `MINIO_CONSOLE_PORT` | `9001` | MinIO console port |
| `MINIO_ADMIN_CONSOLE_PORT` | `9002` | MinIO admin console port |

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
- Console secrets are auto-generated if not provided

## Troubleshooting

**Permission denied:** `sudo chown -R 1000:1000 ./data`

**Port conflicts:** Use custom ports with `-e MINIO_API_PORT=8000`

**Service not starting:** Check logs with `docker logs minio`

**Region errors:** Ensure `MINIO_REGION` is set (e.g., `us-east-1`, `ap-south-1`)

## License
You just DO WHAT THE FUCK YOU WANT TO. 
