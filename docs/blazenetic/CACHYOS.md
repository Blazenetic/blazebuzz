# CachyOS / FOXTROT notes for Blazebuzz

Host: **FOXTROT** · OS: **CachyOS** (Arch-like) · Containers: **Podman** (Docker CLI shim)

---

## Container runtime

On this machine, `/usr/bin/docker` is the Podman Docker-emulation wrapper. Compose goes through `podman-compose` unless a Docker Compose v2 plugin is installed.

Buzz’s root `docker-compose.yml` uses short image names (`postgres:17-alpine`, `redis:7-alpine`, …). Podman will refuse these unless unqualified search is configured.

### Required: registries.conf

User-level file (no root needed):

`~/.config/containers/registries.conf`

```toml
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"

[[registry]]
prefix = "quay.io"
location = "quay.io"
```

Then:

```bash
podman pull postgres:17-alpine   # should work
just setup
```

If short names still fail, pull fully-qualified images once:

```bash
podman pull docker.io/library/postgres:17-alpine
podman pull docker.io/library/redis:7-alpine
podman pull docker.io/library/adminer:latest
podman pull docker.io/minio/minio:latest
podman pull docker.io/minio/mc:latest
podman pull docker.io/prom/prometheus:latest
podman pull quay.io/keycloak/keycloak:26.0
```

### Useful checks

```bash
systemctl --user status podman.socket
podman ps
docker compose ps    # via podman shim
just ps
```

### Known soft differences vs Docker Desktop

- `deploy.resources` limits in compose are often ignored  
- `host.docker.internal:host-gateway` (Prometheus → host) may need Podman host networking tweaks if scraping the relay metrics fails  
- First image pull is slow; subsequent `just setup` is fine  

We do **not** require installing Docker CE unless Podman cannot run the stack at all.

---

## System packages

### Required for general / relay work

Usually already present via Hermit + base system:

- Rust 1.88+ (Hermit pins)  
- Node 24+, pnpm 10+, just  
- base-devel, openssl  

### For desktop Tauri builds

```bash
sudo pacman -S --needed \
  webkit2gtk-4.1 gtk3 base-devel openssl \
  libappindicator-gtk3 librsvg \
  patchelf xdotool
```

`xdotool` provides the X11 automation bits often referenced as libxdo on other distros.

### Not required for this fork bootstrap

- Flutter / mobile SDK  
- Docker Engine CE  

---

## Ports (dev compose)

| Port | Service |
|------|---------|
| 5432 | Postgres |
| 6379 | Redis |
| 3000 | Relay (when running) |
| 8082 | Adminer |
| 8180 | Keycloak |
| 9000/9001 | MinIO |
| 9090 | Prometheus |

---

## Disk

Clone lives on **FastSSD** (`/mnt/FastSSD/main/code/active/blazebuzz`). Rust `target/` can grow large — keep builds on this volume, not a small root partition.

---

## Hermit

```bash
. ./bin/activate-hermit
```

First activation downloads pinned tools into `~/.cache/hermit` and repo `bin/`. Always activate in a new shell before `just` / `cargo` / `pnpm` for agent work.
