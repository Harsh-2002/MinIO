# MinIO + Admin Console Docker Image

[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-firstfinger%2Fminio-blue)](https://hub.docker.com/r/firstfinger/minio)

A production-ready Docker image that combines the latest MinIO server with the full-featured MinIO Admin Console — including **Site Replication** support. Everything you need for object storage with a complete web interface, built from source.

## What's Included

- **MinIO Server** — Built from source (latest)
- **MinIO Admin Console** — Full-featured web UI including Site Replication
- **MinIO Client (mc)** — Command-line tools, minisign-verified

## Related project — Cairn

This image exists because MinIO closed down its community edition. [**Cairn**](https://github.com/Harsh-2002/Cairn) is my answer to the same problem, built from scratch: a self-hosted, S3-compatible object store written in **Rust**, Apache-2.0 licensed, with the console built into the binary.

- **One binary, no moving parts.** Object data as plain files on a normal filesystem, metadata in embedded SQLite — no external database, no clustering layer, no separate storage daemon.
- **The console ships inside it** — bucket browser with in-place preview (images, video, PDF, Markdown, JSON, CSV), a validated bucket-policy editor, scoped short-lived credentials, and metrics.
- **S3 API** — versioning, multipart, object lock, lifecycle, tagging, CORS, presigned URLs, SigV4. The `aws` CLI and the standard AWS SDKs work against it unmodified.
- Multi-arch image at `ghcr.io/harsh-2002/cairn`, plus static amd64/arm64 binaries with a `SHA256SUMS` manifest.
- One-shot import to migrate buckets and objects straight from an existing MinIO node.

> **Cairn is under active development and not production-ready yet.** Good for a homelab, a VPS, or a small node you can afford to experiment on. Issues and feedback are very welcome.

[Project site and screenshots](https://harsh-2002.github.io/Cairn/) · [Repository](https://github.com/Harsh-2002/Cairn)

## Image Tags

| Tag | Console Version | When Updated |
|-----|----------------|--------------|
| `latest` | v1.7.6 | Every push to main + monthly (1st) |
| `1.7.3` | v1.7.3 (Site Replication) | Every push to main + monthly (2nd) |

> Rebuilds are monthly rather than weekly because every source input is frozen upstream —
> `minio/minio` is archived, the console and `mds` refs are pinned, and `mc` has not been
> republished since `RELEASE.2025-08-13`. A scheduled rebuild exists to pick up Alpine
> base-image security patches, nothing else.

Both tags are multi-arch OCI manifests — Docker automatically selects the right binary for your platform (`linux/amd64` or `linux/arm64`). No need to specify an architecture tag.

## Quick Start

### Docker Run

```bash
docker run -d --name minio \
  -p 9000:9000 \
  -p 9001:9001 \
  -p 9002:9002 \
  -v ./data:/data \
  -e MINIO_ROOT_USER=your-access-key \
  -e MINIO_ROOT_PASSWORD=your-secret-key \
  firstfinger/minio:latest
```

### Docker Compose

```bash
docker compose up -d
```

The included `docker-compose.yml` uses `firstfinger/minio:latest` and works on both amd64 and arm64 without any extra configuration.

## Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| **MinIO API** | http://localhost:9000 | S3-compatible API |
| **MinIO Console** | http://localhost:9001 | Built-in UI |
| **MinIO Admin Console** | http://localhost:9002 | Full-featured admin UI (Site Replication, etc.) |

## Environment Variables

### Required

| Variable | Description |
|----------|-------------|
| `MINIO_ROOT_USER` | S3 access key / root username |
| `MINIO_ROOT_PASSWORD` | S3 secret key / root password |

### Optional

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIO_REGION` | `us-east-1` | AWS S3 region string |
| `MINIO_CERTS_DIR` | `/data/.minio/certs` | TLS certificate directory |
| `MINIO_API_PORT` | `9000` | Override API port |
| `MINIO_CONSOLE_PORT` | `9001` | Override built-in console port |
| `MINIO_ADMIN_CONSOLE_PORT` | `9002` | Override admin console port |
| `CONSOLE_PBKDF_PASSPHRASE` | auto-generated | Admin console session passphrase |
| `CONSOLE_PBKDF_SALT` | auto-generated | Admin console session salt |

## Using MinIO Client (mc)

```bash
# Configure alias
docker exec minio mc alias set local http://localhost:9000 your-access-key your-secret-key

# Create bucket
docker exec minio mc mb local/mybucket

# Upload file
docker exec minio mc cp /path/to/file local/mybucket/

# List buckets
docker exec minio mc ls local
```

## Enabling TLS

Place your certificates inside the container at `${MINIO_CERTS_DIR}` (default `/data/.minio/certs`):

```
data/.minio/certs/
├── public.crt    # Full certificate chain (leaf + intermediates)
├── private.key   # Private key
└── CAs/          # Optional: additional CA certs to trust
    └── ca.crt
```

The entrypoint auto-detects `public.crt` + `private.key` and switches MinIO and the health probe to HTTPS automatically. No extra flags needed.

```bash
docker run -d --name minio \
  -v $(pwd)/data:/data \
  -p 9000:9000 -p 9001:9001 -p 9002:9002 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=SecurePass123! \
  firstfinger/minio:latest
```

Validate after startup:
```bash
curl -k https://localhost:9000/minio/health/live
```

> For self-signed certificates, ensure the SAN covers every hostname/IP you access (e.g. `localhost`, `192.168.1.10`). Mount the issuing CA into `CAs/` so MinIO trusts it internally.

## Troubleshooting

**Port conflict:** Use custom port env vars — e.g. `-e MINIO_API_PORT=8000`

**Service not starting:** `docker logs minio`

**Region errors:** Set `MINIO_REGION` to match your client config (e.g. `us-east-1`, `ap-south-1`)

**Site Replication not visible:** Use the `1.7.3` tag — `firstfinger/minio:1.7.3`

## License

You just DO WHAT THE FUCK YOU WANT TO.
