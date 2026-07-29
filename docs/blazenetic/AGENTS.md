# Blazenetic agent rules (Blazebuzz fork)

Read this **before** making changes on the Blazenetic fork. For Buzz internals (crates, kinds, desktop patterns), follow the root [AGENTS.md](../../AGENTS.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md).

---

## Identity

- **Repo:** Blazenetic/blazebuzz (fork of block/buzz)  
- **Name:** Blazebuzz is the *fork*, not a rename of the product code  
- **Do not** mass-rename `buzz` → `blazebuzz` in crates, packages, or UI strings — that destroys upstream mergeability  
- **Do** keep Blazenetic-owned files under `docs/blazenetic/`, `scripts/blazenetic/`, `justfile.blazenetic`, and `BLAZEBUZZ.md`

---

## Shell / toolchain

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit    # REQUIRED before cargo/node/pnpm/just for hermit-pinned tools
```

- Prefer Hermit binaries over system ones for reproducible agent runs  
- Host is **CachyOS**; container CLI is **Podman emulating Docker** — see [CACHYOS.md](CACHYOS.md)  
- Before coding: `just bb-doctor`  
- Minimum quality gate: `just test-unit`  
- Full upstream gate (when contributing back or large changes): `just ci`  
- Commits that might go upstream need DCO: `git commit -s`

---

## Git remotes (hard rules)

| Remote | URL | Push? |
|--------|-----|-------|
| `origin` | Blazenetic/blazebuzz | **yes** |
| `upstream` | block/buzz | **never** |

```bash
# good
git push -u origin HEAD
just bb-push

# bad
git push upstream …
```

Use `just bb-sync*` for bringing in upstream — do not invent one-off force-push workflows.

---

## Where to put Blazenetic work

| Kind of change | Where |
|----------------|--------|
| Fork docs, agent notes | `docs/blazenetic/` |
| Sync / doctor scripts | `scripts/blazenetic/` |
| Fork just recipes | `justfile.blazenetic` (`bb-*` names only) |
| Product/code features | normal Buzz paths (crates/, desktop/, …) so they can be upstreamed later |

When editing root `Justfile` or root `AGENTS.md`, keep the delta **minimal** (import line + pointer header). Bulk fork docs stay out of those files so merges are calm.

---

## Sync expectations

- Default: **merge** `upstream/main` via `just bb-sync`  
- Dry-run first if unsure: `just bb-sync-dry`  
- Protected paths are listed in `scripts/blazenetic/protect.list`  
- After sync: `just bb-doctor` and `just test-unit`  
- Details: [SYNC.md](SYNC.md)

---

## Scope discipline

This environment is set up for **fork + local agent productivity**, not necessarily a live community.

- Prefer unit tests and `cargo check` over full `just dev` unless the task needs the relay UI  
- Do not run `just reset` without explicit human approval (destructive to dev data)  
- Do not force-push `main` on origin without explicit approval  
- Mobile/Flutter is optional and may be absent on this host  

---

## Upstream contribution posture

If a change is generally useful to Buzz:

1. Implement cleanly against upstream conventions  
2. Keep Blazenetic-only glue out of the same commit when possible  
3. Open a PR to **block/buzz** from a branch on the fork (or a clean export branch)  
4. Use Conventional Commits + DCO sign-off  

If a change is Blazenetic-only (sync tooling, host docs), keep it in the protect list paths and never try to upstream it.

---

## Quick command card

```bash
. ./bin/activate-hermit
just bb-doctor
just bb-up
just bb-sync-status
just bb-sync-dry
just bb-sync
just test-unit
just bb-agent-ready
just relay          # local relay ws://localhost:3000
just bb-smoke       # after relay is up
just bb-push
```

Operator runbook: [RUNBOOK.md](RUNBOOK.md).
