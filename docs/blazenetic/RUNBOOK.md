# Blazebuzz runbook — run, customize, iterate

Practical guide for FOXTROT after the fork bootstrap. Start at
[BLAZEBUZZ.md](../../BLAZEBUZZ.md) if you have never opened this tree.

---

## 60-second cold start

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit

just bb-up              # ensure Postgres/Redis/etc are healthy
just relay              # terminal 1 — ws://localhost:3000
# optional second terminal:
just desktop-dev        # Vite UI only (faster)
# or full native shell:
just dev                # relay + Tauri desktop together
```

Smoke checks while relay is up:

```bash
curl -sS http://127.0.0.1:3000/health
curl -sS http://127.0.0.1:8080/_readiness
# NIP-11 relay info
curl -sS http://127.0.0.1:3000/ | head
```

| URL | What |
|-----|------|
| `ws://localhost:3000` | Relay (clients + agents) |
| http://localhost:3000/health | App-port health |
| http://localhost:8080/_readiness | K8s-style readiness |
| http://localhost:8082 | Adminer (DB browser) — user `buzz` / `buzz_dev` |
| http://localhost:8180 | Keycloak (local OAuth) — `admin` / `admin` |
| http://localhost:9001 | MinIO console — `buzz_dev` / `buzz_dev_secret` |
| http://localhost:9090 | Prometheus |

Stop infra (keep volumes): `just down`  
Wipe dev data (destructive): `just reset` — **ask first**

---

## Daily loop (humans + agents)

```bash
. ./bin/activate-hermit
just bb-sync-status     # how far behind block/buzz?
just bb-up              # services
# edit code…
just test-unit          # minimum gate
just bb-push            # when you want origin updated
```

Weekly:

```bash
just bb-sync            # merge upstream/main
just bb-agent-ready     # doctor + unit tests
just bb-push
```

---

## Customize without merge hell

| Goal | Do this | Avoid |
|------|---------|--------|
| Host docs, sync tooling | `docs/blazenetic/`, `scripts/blazenetic/`, `justfile.blazenetic` | Editing huge chunks of root `AGENTS.md` |
| Product features you may upstream | Normal `crates/`, `desktop/`, `web/` paths | Renaming Buzz → Blazebuzz tree-wide |
| Local config | `.env` (gitignored) | Committing secrets |
| Community / branding later | Persona packs, seed scripts, web assets | Mass search-replace of crate names |

Protected paths (sync tooling prefers ours):

- `BLAZEBUZZ.md`
- `justfile.blazenetic`
- `docs/blazenetic/`
- `scripts/blazenetic/`

---

## Agent CLI (`buzz`)

```bash
. ./bin/activate-hermit
cargo build -p buzz-cli
export PATH="$PWD/target/debug:$PATH"
export BUZZ_RELAY_URL=ws://localhost:3000
# export BUZZ_PRIVATE_KEY=<32-byte hex or nsec1…>   # required for writes
buzz --help
```

JSON in / JSON out. See `crates/buzz-cli` and root `AGENTS.md` § Agent CLI.

---

## Desktop app paths

| Command | Use when |
|---------|----------|
| `just desktop-dev` | UI iteration (Vite only; needs a relay already running) |
| `just dev` | Full stack: builds agents, starts relay, launches Tauri |
| `just desktop-standalone` | App only — connect to any community URL later |

Linux Tauri deps on this host: `patchelf`, `xdotool`, `webkit2gtk-4.1`, `gtk3` (already installed after bootstrap).

---

## Self-host later (not required for local dev)

When you want a durable community on this machine or a VPS:

```bash
cd deploy/compose
cp .env.example .env
# edit CHANGE_ME secrets, owner pubkey, ports
./run.sh start
```

See [deploy/compose/README.md](../../deploy/compose/README.md). Dev compose
(`docker-compose.yml` at repo root) is **not** production.

---

## FOXTROT / Podman notes

- `docker` → Podman shim; compose via `podman-compose`
- Unqualified Hub names need `~/.config/containers/registries.conf` (already set)
- If services die overnight: `just bb-up`
- Details: [CACHYOS.md](CACHYOS.md)

---

## Suggested first customizations

1. **Stable relay key** — set `BUZZ_RELAY_PRIVATE_KEY` in `.env` so REST-created identities survive restarts (see `.env.example`).
2. **Owner pubkey** — for closed-relay experiments, set `RELAY_OWNER_PUBKEY` once you have a Nostr keypair.
3. **Agent identity** — generate a key for `BUZZ_PRIVATE_KEY` and use `buzz-cli` / `buzz-acp`.
4. **Seed community** — already seeded for `localhost:3000` via `scripts/seed-local-community.sh`.
5. **Branding** — web/desktop copy and assets only; keep crate names as `buzz-*` for upstream sync.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `short-name "postgres:…" did not resolve` | Fix `~/.config/containers/registries.conf` (see CACHYOS.md) |
| `buzz-postgres not healthy` | `just bb-up` or `just setup` |
| Port 3000/8080 in use | `pkill -f buzz-relay` or override `BUZZ_BIND_ADDR` / `BUZZ_HEALTH_PORT` |
| Hermit tools missing | `. ./bin/activate-hermit` every new shell |
| Dirty tree blocks sync | Commit/stash, or `just bb-sync --stash` |
| Pre-push slow | Expected — runs rust + desktop unit tests |
| Phone QR pairing: “Could not reach the pairing relay” | Community is almost certainly `ws://localhost:3000` — phone cannot reach your PC’s localhost. Use a public/mesh `wss://` URL. See [MOBILE-PAIRING.md](MOBILE-PAIRING.md) |

---

## Status checklist (after bootstrap)

- [x] Fork cloned with origin + upstream  
- [x] Hermit + `just setup`  
- [x] `bb-*` sync tooling  
- [x] Unit tests green (incl. replica fence microsecond fix)  
- [x] patchelf / xdotool installed  
- [ ] You: `just relay` or `just dev` and connect a client  
- [ ] You: set stable keys in `.env` for a durable local community  
- [ ] Optional: `deploy/compose` for always-on host  
