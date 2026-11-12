# Blazebuzz

**Blazenetic’s fork of [block/buzz](https://github.com/block/buzz)** — a self-hostable workspace where humans and AI agents share the same rooms.

| | |
|---|---|
| **Fork** | https://github.com/Blazenetic/blazebuzz |
| **Upstream** | https://github.com/block/buzz |
| **Local path** | `/mnt/FastSSD/main/code/active/blazebuzz` |
| **Primary host** | FOXTROT (CachyOS + Podman) |

This is a **fork identity**, not a tree-wide product rename. Upstream Buzz code, crates, and docs stay named Buzz so sync stays easy. Our additions live under `docs/blazenetic/`, `scripts/blazenetic/`, and `justfile.blazenetic`.

---

## Complex City planning (current direction)

Buzz is the **preferred, not yet adopted** internal staff-and-agent chat platform for Complex City. The canonical decisions, preparation work packages and agent instructions live in the restricted Google Drive workspace. **Read [Complex City preparation handoff](docs/blazenetic/COMPLEX-CITY-HANDOFF.md) before any Complex City-related work.** No pilot, deployment or production integration is authorised by this documentation.

---

## Read first (agents)

1. **This file** — fork layout and daily commands  
2. **[docs/blazenetic/AGENTS.md](docs/blazenetic/AGENTS.md)** — Blazenetic rules for agents  
3. **[AGENTS.md](AGENTS.md)** — upstream Buzz agent guide (crate map, patterns, quality gates)  
4. **[CONTRIBUTING.md](CONTRIBUTING.md)** — setup, style, PR process  
5. **[docs/blazenetic/SYNC.md](docs/blazenetic/SYNC.md)** — keeping the fork current  
6. **[docs/blazenetic/CACHYOS.md](docs/blazenetic/CACHYOS.md)** — host-specific notes  
7. **[docs/blazenetic/COMPLEX-CITY-HANDOFF.md](docs/blazenetic/COMPLEX-CITY-HANDOFF.md)** — current Complex City scope, Drive links and preparation work packages  

---

## Remotes

```text
origin    → git@github.com:Blazenetic/blazebuzz.git   (or https)
upstream  → https://github.com/block/buzz.git
```

- Push only to **origin**  
- Never push to **upstream**  
- Sync with `just bb-sync` (see below)

---

## One-time setup (this machine)

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just setup          # .env, Docker/Podman services, migrations, pnpm
just hooks          # lefthook + DCO sign-off
just bb-doctor      # Blazenetic preflight
just test-unit      # no infra required
```

Podman needs unqualified Docker Hub search — see [CACHYOS.md](docs/blazenetic/CACHYOS.md).

Optional desktop Tauri packages:

```bash
sudo pacman -S --needed patchelf xdotool
```

---

## Run it (local community)

**Your checklist:** [docs/blazenetic/NEXT-STEPS.md](docs/blazenetic/NEXT-STEPS.md)  
**Full ops detail:** [docs/blazenetic/RUNBOOK.md](docs/blazenetic/RUNBOOK.md).

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just bb-up              # Postgres, Redis, migrations
just relay              # ws://localhost:3000  (keep this terminal open)
# other terminal:
just desktop-dev        # web UI only
# or: just dev          # Tauri desktop + relay together
just bb-smoke           # health + readiness once relay is up
```

---

## Daily workflow

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just bb-sync-status     # how far behind upstream?
just bb-up              # services
# …edit…
just test-unit          # minimum gate
just bb-push            # update GitHub fork
```

### Fork sync (Blazenetic tooling)

| Command | Purpose |
|---------|---------|
| `just bb-doctor` | Preflight (tools, remotes, podman, protected paths) |
| `just bb-up` | Start/wait for Postgres + Redis + migrations |
| `just bb-smoke` | Curl relay health/readiness |
| `just bb-sync-status` | Ahead/behind origin + upstream |
| `just bb-sync-dry` | Preview upstream commits without merging |
| `just bb-sync` | Merge `upstream/main` into `main` (safe default) |
| `just bb-sync-rebase` | Rebase onto upstream (explicit, rewrite-y) |
| `just bb-push` | Push current branch to origin only |
| `just bb-agent-ready` | doctor + unit tests |

---

## Customize

See [RUNBOOK.md § Customize](docs/blazenetic/RUNBOOK.md#customize-without-merge-hell).

Short version: put Blazenetic-only work under `docs/blazenetic/` and
`scripts/blazenetic/`; put product features in normal Buzz paths so they can
be upstreamed. Do **not** mass-rename crates to `blazebuzz`.

Later durable host: [`deploy/compose/`](deploy/compose/README.md).

---

## Handoff

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just bb-sync-status
just bb-doctor
just bb-up
# run: just relay   OR   just dev
just bb-smoke
# weekly: just bb-sync && just bb-agent-ready && just bb-push
```

Protected paths (never casually overwrite; sync tooling preserves them):

- `BLAZEBUZZ.md`
- `justfile.blazenetic`
- `docs/blazenetic/`
- `scripts/blazenetic/`
