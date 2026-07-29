# Blazebuzz — your next steps

Personal checklist after the FOXTROT bootstrap. Tick items as you go.  
Environment path: `/mnt/FastSSD/main/code/active/blazebuzz`  
Fork: https://github.com/Blazenetic/blazebuzz  

Related docs: [RUNBOOK.md](RUNBOOK.md) · [BLAZEBUZZ.md](../../BLAZEBUZZ.md) · [SYNC.md](SYNC.md)

---

## 1. Confirm the stack (5 minutes)

After reboot or a long break:

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just bb-up
just bb-doctor
```

- [ ] Hermit activates without errors  
- [ ] `just bb-doctor` is OK (warnings about busy ports are fine if services are up)  
- [ ] Postgres + Redis healthy  

Start or verify the relay:

```bash
# If nothing is listening on :3000:
just relay
# Other terminal:
just bb-smoke
```

- [ ] `just bb-smoke` shows health `ok` and readiness `ready`  
- [ ] You know how to stop the relay (`Ctrl+C` in that terminal, or `pkill -x buzz-relay`)

| URL | Check |
|-----|--------|
| http://localhost:3000/health | should return `ok` |
| http://localhost:8080/_readiness | should return ready |
| http://localhost:8082 | Adminer DB UI |

---

## 2. Open a client (10–20 minutes)

### Recommended first path — full desktop

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
# Either let just own the stack:
just dev
# Or keep an existing relay and only start UI:
# just desktop-dev
```

- [ ] Desktop/UI launches  
- [ ] Connected to `ws://localhost:3000` (default)  
- [ ] You can create/join a community and send a message  

### Alternate — web Vite only

```bash
just bb-up
just relay          # terminal 1
just desktop-dev    # terminal 2
```

- [ ] Prefer this when iterating on UI without full Tauri rebuilds  

### Optional — packaged desktop binary

Grab a release from [block/buzz releases](https://github.com/block/buzz/releases) and point it at your local relay (`BUZZ_RELAY_URL=ws://localhost:3000`) if you want a “normal app” feel without building.

---

## 3. Lock in durable local config (15 minutes)

`.env` is gitignored — safe for secrets. Already has a **stable** `BUZZ_RELAY_PRIVATE_KEY` from bootstrap; keep it.

- [ ] Open `.env` and skim defaults (do not commit this file)  
- [ ] Confirm `BUZZ_RELAY_PRIVATE_KEY` is set (so identity survives restarts)  
- [ ] Optional: generate a personal Nostr key for agents/CLI:

```bash
# Example only — use any Nostr key tool you trust, or buzz-related helpers later
openssl rand -hex 32
# put result in .env as:
# BUZZ_PRIVATE_KEY=<64 hex chars>
```

- [ ] Optional later: set `RELAY_OWNER_PUBKEY` if you want closed-relay / owner experiments  
- [ ] Note Adminer login: user `buzz`, password `buzz_dev`, DB `buzz`

---

## 4. Agent surface (`buzz` CLI) (20 minutes)

With the relay up:

```bash
. ./bin/activate-hermit
export PATH="$PWD/target/debug:$PATH"
export BUZZ_RELAY_URL=ws://localhost:3000
export BUZZ_PRIVATE_KEY=...   # from step 3

buzz --help
buzz --format compact channels list   # once auth/key works
```

- [ ] `buzz --help` works  
- [ ] You understand: JSON out, exit codes, global `--format compact` goes **before** the subcommand  
- [ ] You can list or create something small (channel / message) once keyed  
- [ ] Skim `crates/buzz-cli` and root `AGENTS.md` § Agent CLI  
- [ ] Optional: try ACP harness (`buzz-acp` / `just goose`) when you want an LLM agent in-room  

---

## 5. Learn the fork workflow (10 minutes)

```bash
just bb-sync-status     # ahead/behind Block
just bb-sync-dry        # preview without merging
# weekly when ready:
# just bb-sync && just test-unit && just bb-push
```

- [ ] You can explain origin vs upstream  
- [ ] You know: **push only to origin**, never upstream  
- [ ] You know protected paths: `BLAZEBUZZ.md`, `justfile.blazenetic`, `docs/blazenetic/`, `scripts/blazenetic/`  
- [ ] You will not mass-rename `buzz` → `blazebuzz` in crates (breaks sync)  

---

## 6. First customizations (pick 1–2)

Stay small so upstream merges stay easy.

### Easy wins

- [ ] Seed or rename local community copy (seed script already targets `localhost:3000`)  
- [ ] Desktop/web branding strings or logo assets only (no crate renames)  
- [ ] A small `buzz-cli` script or shell alias for your common ops  
- [ ] Document *your* preferred start commands in a personal note (or extend this file)  

### Medium

- [ ] Custom agent persona pack (`buzz-persona` / pack CLI)  
- [ ] A workflow YAML (message/reaction/schedule trigger)  
- [ ] Local policy markdown (`BUZZ_TERMS_OF_SERVICE_MARKDOWN` etc. in `.env`)  
- [ ] Closed relay + owner key for a private Blazebuzz community  

### Bigger (plan first)

- [ ] Production-ish always-on host via `deploy/compose/`  
- [ ] NetBird/Tailscale-only access instead of LAN ports  
- [ ] Phone pairing: public/mesh `wss://` (store Android rejects `localhost` + private IPs) — [MOBILE-PAIRING.md](MOBILE-PAIRING.md)  
- [ ] Upstream PR for a fix you want in `block/buzz`  
- [ ] UI rebrand “Blazebuzz” product surface (careful merge strategy)  

---

## 7. Production / always-on (when ready)

Dev compose (`docker-compose.yml` at repo root) is **not** production.

```bash
cd deploy/compose
cp .env.example .env
# fill every CHANGE_ME
./run.sh config
./run.sh start
```

- [ ] Read [deploy/compose/README.md](../../deploy/compose/README.md)  
- [ ] Stable secrets and owner pubkey decided  
- [ ] TLS decision (local only vs `BUZZ_COMPOSE_TLS=true` on a public VPS)  
- [ ] Backup plan (`./run.sh backup-hint`)  

---

## 8. Cadence (make it stick)

### Daily / when coding

```bash
. ./bin/activate-hermit
just bb-up
just bb-sync-status
# work…
just test-unit
```

### Weekly

```bash
just bb-sync
just bb-agent-ready    # doctor + unit tests
just bb-push
```

- [ ] Calendar or habit: weekly sync  
- [ ] Know that pre-push hooks can take several minutes (desktop/mobile tests)  

---

## 9. Troubleshooting shortcuts

| Problem | Action |
|---------|--------|
| Ports free but doctor warns services down | `just bb-up` or `just setup` |
| Short image name errors under Podman | See [CACHYOS.md](CACHYOS.md) — registries.conf |
| Relay won’t bind | `pkill -x buzz-relay`; check `lsof -iTCP:3000,8080,9102 -sTCP:LISTEN` |
| Hermit tools “missing” | Forgot `. ./bin/activate-hermit` |
| Dirty tree blocks sync | Commit/stash, or `just bb-sync --stash` |
| Want a clean DB | `just reset` (destructive — confirm first) |

Logs for the background smoke relay (if you started one that way): `/tmp/blazebuzz-relay.log`.

---

## 10. Suggested order for *this week*

1. [ ] Step 1 — stack + `bb-smoke`  
2. [ ] Step 2 — `just dev` or `desktop-dev`, send a real message  
3. [ ] Step 3 — personal `BUZZ_PRIVATE_KEY` in `.env`  
4. [ ] Step 4 — one successful `buzz` CLI write  
5. [ ] Step 5 — run `bb-sync-status` once so the habit exists  
6. [ ] Step 6 — one tiny customization (branding or script)  
7. [ ] Decide: stay local-dev only, or schedule `deploy/compose` later  

---

## Quick reference

| Command | Purpose |
|---------|---------|
| `just bb-up` | Infra + migrations |
| `just relay` / `just dev` | Run relay / full desktop stack |
| `just bb-smoke` | Health checks |
| `just bb-sync-status` / `just bb-sync` | Upstream awareness / merge |
| `just bb-push` | Update GitHub fork |
| `just test-unit` | Fast quality gate |
| `just bb-doctor` | Environment preflight |
| `just down` | Stop containers, keep data |
| `just reset` | Wipe dev data (careful) |

When in doubt: **[RUNBOOK.md](RUNBOOK.md)**.
