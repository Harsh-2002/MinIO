# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Docker project that builds a single, self-contained MinIO image from source. It bundles the MinIO server, the Admin Console (UI), and the MinIO client (`mc`) into one image. Pre-built images are published to Docker Hub as `firstfinger/minio`.

## Common Commands

### Build the Docker image locally

```bash
# Build for the local architecture
docker build -t firstfinger/minio:local .

# Build for a specific architecture
docker build --platform linux/amd64 -t firstfinger/minio:local-amd64 .
docker build --platform linux/arm64 -t firstfinger/minio:local-arm64 .

# Build with a specific MinIO version
docker build --build-arg MINIO_VERSION=RELEASE.2024-01-01T00-00-00Z -t firstfinger/minio:local .
```

### Run with Docker Compose

```bash
# Start
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

### Run directly

```bash
docker run -d \
  -p 9000:9000 -p 9001:9001 -p 9002:9002 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  -v $(pwd)/data:/data \
  firstfinger/minio:latest
```

### Access points after startup

| Port | Service |
|------|---------|
| 9000 | MinIO API (S3-compatible) |
| 9001 | MinIO Console (built-in UI) |
| 9002 | MinIO Admin Console (full-featured UI) |

## Architecture

### Multi-stage Dockerfile

The `Dockerfile` has four stages:

1. **`console-ui-builder`** — Node.js/Yarn build of the Admin Console frontend from `minio/object-browser` v1.7.3.
2. **`console-builder`** — Go build of the Admin Console binary (`console`), embedding the UI assets from stage 1.
3. **`server-builder`** — Go build of `minio` server from source. Accepts `MINIO_VERSION` build arg (defaults to `latest`).
4. **Final runtime** — Alpine-based image that combines all three binaries, plus a downloaded `mc` binary (verified with minisign). Runs as root, matching the official MinIO image behaviour.

### `start.sh` — Entrypoint Logic

The script is the container entrypoint and orchestrates the startup sequence:

1. Detects TLS certificates in `${MINIO_CERTS_DIR:-/data/.minio/certs}` (looks for `public.crt` + `private.key`). Switches health-check scheme to `https` automatically.
2. Starts `minio server` in the background.
3. Polls the health endpoint (`/minio/health/live`) up to 30 seconds.
4. Starts the `console` binary after the server is healthy.
5. Monitors both processes; exits if either dies.

### CI/CD Workflow (`.github/workflows/docker-build-push.yml`)

Single `build` job. Uses QEMU to cross-compile arm64 on the amd64 runner, then pushes a single multi-arch manifest as `firstfinger/minio:latest`. Timeout is 240 minutes to accommodate the arm64 QEMU build time.

Triggers: push/PR to `main`, daily schedule (06:30 UTC), and manual dispatch.

## TLS Configuration

Place certificates inside the container at `${MINIO_CERTS_DIR}` (default `/data/.minio/certs`):

```
certs/
├── public.crt    # Server certificate (must include SANs for all hostnames)
├── private.key   # Private key
└── CAs/          # Optional: additional CA certificates to trust
    └── ca.crt
```

`start.sh` auto-detects these files and enables HTTPS. Mount the host cert directory via volume, e.g., `-v /path/to/certs:/data/.minio/certs:ro`.

## Key Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `MINIO_ROOT_USER` | (required) | S3 access key |
| `MINIO_ROOT_PASSWORD` | (required) | S3 secret key |
| `MINIO_REGION` | `us-east-1` | AWS region string |
| `MINIO_CERTS_DIR` | `/data/.minio/certs` | TLS certificate directory |
| `MINIO_API_PORT` | `9000` | Override API port |
| `MINIO_CONSOLE_PORT` | `9001` | Override built-in console port |
| `MINIO_ADMIN_CONSOLE_PORT` | `9002` | Override Admin Console port |
