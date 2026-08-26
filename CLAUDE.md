# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Docker project that builds a single, self-contained MinIO image from source. It bundles the MinIO server, the Admin Console (UI), and the MinIO client (`mc`) into one image. Pre-built images are published to Docker Hub as `firstfinger/minio`.

**Why it exists:** MinIO stopped shipping a usable community distribution. `minio/minio` is archived on GitHub (read-only; last code change 2025-10-24, last release `RELEASE.2025-10-15T17-29-55Z`), the full-featured web console was stripped out of the community server, and `minio/object-browser` was deleted outright. This repo rebuilds the last open-source server from source and pairs it with a community-maintained console fork, so the resulting image keeps admin features (notably Site Replication) that upstream removed.

## Common Commands

### Build the Docker image locally

```bash
# Build for the local architecture
docker build -t firstfinger/minio:local .

# Build for a specific architecture
docker build --platform linux/amd64 -t firstfinger/minio:local-amd64 .
docker build --platform linux/arm64 -t firstfinger/minio:local-arm64 .

# Build with a specific MinIO version
docker build --build-arg MINIO_VERSION=RELEASE.2025-10-15T17-29-55Z -t firstfinger/minio:local .

# Build with a specific console version (e.g. the Site Replication build)
docker build \
  --build-arg CONSOLE_VERSION=v1.7.3 \
  --build-arg MDS_COMMIT=3025ce83976c286fb1e9c55095336d75ad82d8e6 \
  -t firstfinger/minio:local-1.7.3 .
```

### Build arguments

| Arg | Default | Purpose |
|-----|---------|---------|
| `MINIO_VERSION` | `latest` | Git ref of `minio/minio` to build. `latest` = shallow clone of master. |
| `CONSOLE_VERSION` | `v1.7.6` | Tag of the `Harsh-2002/MinIO-Object-Browser` fork to build the console from. |
| `MDS_COMMIT` | `027fb7f…fbe1` | Commit of the `Harsh-2002/mds` fork, side-loaded as the console's design-system dependency. |

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

1. **`console-ui-builder`** — Node.js/Yarn build of the Admin Console frontend from the `Harsh-2002/MinIO-Object-Browser` fork at `CONSOLE_VERSION` (upstream `minio/object-browser` is deleted). It also clones the `Harsh-2002/mds` fork at `MDS_COMMIT` and rewrites `web-app/package.json` with `jq` so the `mds` design-system dependency resolves to that local checkout instead of npm.
2. **`console-builder`** — Go build of the Admin Console binary (`console`), embedding the UI assets from stage 1.
3. **`server-builder`** — Go build of `minio` server from source (shallow clone; `minio/minio` is archived so history is never needed). Accepts `MINIO_VERSION` build arg (defaults to `latest`). Also downloads `mc` from `dl.min.io` and verifies it with minisign — `dl.min.io` 302-redirects to GitHub Releases, so those `curl` calls **must** keep `-L`.
4. **Final runtime** — Alpine-based image that combines all three binaries, plus a downloaded `mc` binary (verified with minisign). Runs as root, matching the official MinIO image behaviour.

### `start.sh` — Entrypoint Logic

The script is the container entrypoint and orchestrates the startup sequence:

1. Detects TLS certificates in `${MINIO_CERTS_DIR:-/data/.minio/certs}` (looks for `public.crt` + `private.key`). Switches health-check scheme to `https` automatically.
2. Starts `minio server` in the background.
3. Polls the health endpoint (`/minio/health/live`) up to 30 seconds.
4. Starts the `console` binary after the server is healthy.
5. Monitors both processes; exits if either dies.

### CI/CD Workflows

Two near-identical workflows, each a single `build` job that uses QEMU to cross-compile arm64 on the amd64 runner and pushes one multi-arch manifest. Timeout is 240 minutes to accommodate the arm64 QEMU build time.

| Workflow | Tag | Console | Triggers |
|----------|-----|---------|----------|
| `build-latest.yml` | `firstfinger/minio:latest` | `v1.7.6` | push/PR to `main`, monthly (1st, 06:30 UTC), dispatch |
| `build-v173.yml` | `firstfinger/minio:1.7.3` | `v1.7.3` (Site Replication) | push to `main`, monthly (2nd, 06:30 UTC), dispatch |

**Why monthly, not weekly or daily:** every build input is frozen upstream — `minio/minio` is archived, the console and `mds` refs are pinned, and `mc` on `dl.min.io` has not moved since `RELEASE.2025-08-13`. The only thing a scheduled rebuild can pick up is an Alpine base-image security patch. Rebuilding more often than monthly produces an identical image.

Both use a **registry** build cache (`firstfinger/minio:buildcache-*`) rather than `type=gha`, because GitHub evicts unused caches after 7 days, which would leave every monthly run cold.

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
