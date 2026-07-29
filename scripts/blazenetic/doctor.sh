#!/usr/bin/env bash
# Blazebuzz preflight: remotes, tools, container runtime, ports, protected layer.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

RED=$'\033[0;31m'
GRN=$'\033[0;32m'
YLW=$'\033[0;33m'
BLU=$'\033[0;34m'
RST=$'\033[0m'

pass=0
warn=0
fail=0

ok()   { echo "${GRN}✓${RST} $*"; pass=$((pass + 1)); }
warn() { echo "${YLW}!${RST} $*"; warn=$((warn + 1)); }
bad()  { echo "${RED}✗${RST} $*"; fail=$((fail + 1)); }
hdr()  { echo; echo "${BLU}==>${RST} $*"; }

hdr "Repository"
if [[ -d .git ]]; then
  ok "git repo at $ROOT"
else
  bad "not a git repository"
fi

origin_url="$(git remote get-url origin 2>/dev/null || true)"
upstream_url="$(git remote get-url upstream 2>/dev/null || true)"
if [[ "$origin_url" == *"Blazenetic/blazebuzz"* ]]; then
  ok "origin → $origin_url"
else
  bad "origin should be Blazenetic/blazebuzz (got: ${origin_url:-missing})"
fi
if [[ "$upstream_url" == *"block/buzz"* ]]; then
  ok "upstream → $upstream_url"
else
  bad "upstream should be block/buzz (got: ${upstream_url:-missing})"
fi

branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo detached)"
ok "branch: $branch @ $(git rev-parse --short HEAD 2>/dev/null || echo '?')"

hdr "Hermit / toolchain"
if [[ -f bin/activate-hermit ]]; then
  # shellcheck disable=SC1091
  source ./bin/activate-hermit >/dev/null 2>&1 || true
  ok "hermit activate script present"
else
  bad "bin/activate-hermit missing"
fi

for tool in cargo node pnpm just git; do
  if command -v "$tool" >/dev/null 2>&1; then
    ver="$("$tool" --version 2>/dev/null | head -1)"
    ok "$tool: $ver"
  else
    bad "$tool not on PATH (activate hermit: . ./bin/activate-hermit)"
  fi
done

hdr "Container runtime (Podman-as-Docker on CachyOS)"
if command -v docker >/dev/null 2>&1; then
  docker_info="$(docker version --format '{{.Server.Version}}' 2>/dev/null || docker info 2>/dev/null | head -3 || true)"
  ok "docker CLI present ($(command -v docker))"
  if docker info >/dev/null 2>&1; then
    ok "container engine reachable"
  else
    bad "docker info failed — is podman.socket active?"
  fi
else
  bad "docker CLI missing"
fi

if [[ -f "${HOME}/.config/containers/registries.conf" ]]; then
  if grep -q 'unqualified-search-registries' "${HOME}/.config/containers/registries.conf" 2>/dev/null; then
    ok "podman unqualified-search-registries configured"
  else
    warn "registries.conf exists but may lack unqualified-search-registries"
  fi
else
  warn "no ~/.config/containers/registries.conf — short image names may fail under podman"
  warn "see docs/blazenetic/CACHYOS.md"
fi

hdr "Dev service ports (expected free or owned by buzz-*)"
for port in 5432 6379 3000 8082 8180 9000 9001 9090; do
  if command -v ss >/dev/null 2>&1; then
    if ss -tln | grep -qE ":${port}\\s"; then
      # soft: services may already be up
      warn "port ${port} is listening (ok if buzz services are up)"
    else
      ok "port ${port} free"
    fi
  fi
done

if command -v docker >/dev/null 2>&1; then
  if docker inspect --format '{{.State.Health.Status}}' buzz-postgres 2>/dev/null | grep -q healthy; then
    ok "buzz-postgres healthy"
  else
    warn "buzz-postgres not healthy (run: just setup)"
  fi
  if docker inspect --format '{{.State.Health.Status}}' buzz-redis 2>/dev/null | grep -q healthy; then
    ok "buzz-redis healthy"
  else
    warn "buzz-redis not healthy (run: just setup)"
  fi
fi

hdr "Blazenetic fork layer"
for path in BLAZEBUZZ.md justfile.blazenetic docs/blazenetic/AGENTS.md scripts/blazenetic/sync-upstream.sh scripts/blazenetic/protect.list; do
  if [[ -e "$path" ]]; then
    ok "$path"
  else
    bad "missing $path"
  fi
done

if grep -q 'import? .justfile.blazenetic' Justfile 2>/dev/null || grep -q "import? 'justfile.blazenetic'" Justfile 2>/dev/null; then
  ok "Justfile imports justfile.blazenetic"
else
  warn "Justfile may not import justfile.blazenetic yet"
fi

if head -20 AGENTS.md | grep -qi 'blazebuzz\|blazenetic'; then
  ok "AGENTS.md has Blazenetic pointer"
else
  warn "AGENTS.md missing Blazenetic pointer header"
fi

hdr "Optional desktop/Tauri host libs"
for bin in patchelf xdotool; do
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin installed"
  else
    warn "$bin missing (desktop Tauri builds may need: sudo pacman -S --needed patchelf xdotool)"
  fi
done

if [[ -f .env ]]; then
  ok ".env present"
else
  warn ".env missing (just bootstrap / just setup will create it)"
fi

echo
echo "----------------------------------------"
echo "pass=$pass  warn=$warn  fail=$fail"
if [[ "$fail" -gt 0 ]]; then
  echo "${RED}doctor: FAIL${RST}"
  exit 1
fi
if [[ "$warn" -gt 0 ]]; then
  echo "${YLW}doctor: OK with warnings${RST}"
  exit 0
fi
echo "${GRN}doctor: OK${RST}"
exit 0
