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

## Read first (agents)

1. **This file** — fork layout and daily commands  
2. **[docs/blazenetic/AGENTS.md](docs/blazenetic/AGENTS.md)** — Blazenetic rules for agents  
3. **[AGENTS.md](AGENTS.md)** — upstream Buzz agent guide (crate map, patterns, quality gates)  
4. **[CONTRIBUTING.md](CONTRIBUTING.md)** — setup, style, PR process  
5. **[docs/blazenetic/SYNC.md](docs/blazenetic/SYNC.md)** — keeping the fork current  
6. **[docs/blazenetic/CACHYOS.md](docs/blazenetic/CACHYOS.md)** — host-specific notes  

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

## Daily workflow

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just bb-sync-status     # how far behind upstream?
# …edit…
just test-unit          # minimum gate
# just relay            # when you want the local relay (ws://localhost:3000)
```

### Fork sync (Blazenetic tooling)

| Command | Purpose |
|---------|---------|
| `just bb-doctor` | Preflight (tools, remotes, podman, protected paths) |
| `just bb-sync-status` | Ahead/behind origin + upstream |
| `just bb-sync-dry` | Preview upstream commits without merging |
| `just bb-sync` | Merge `upstream/main` into `main` (safe default) |
| `just bb-sync-rebase` | Rebase onto upstream (explicit, rewrite-y) |
| `just bb-push` | Push current branch to origin only |
| `just bb-agent-ready` | doctor + unit tests |

---

## What we intentionally defer

- Full product boot (`just dev`) and production self-host (`deploy/compose`)  
- Flutter/mobile toolchain  
- UI rebrand Buzz → Blazebuzz  

When ready to self-host for real, use [`deploy/compose/`](deploy/compose/README.md).

---

## Handoff for the next agent

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just bb-sync-status
just bb-doctor
# weekly: just bb-sync && just bb-agent-ready
```

Protected paths (never casually overwrite; sync tooling preserves them):

- `BLAZEBUZZ.md`
- `justfile.blazenetic`
- `docs/blazenetic/`
- `scripts/blazenetic/`
