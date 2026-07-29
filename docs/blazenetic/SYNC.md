# Syncing Blazebuzz with upstream

Keep [Blazenetic/blazebuzz](https://github.com/Blazenetic/blazebuzz) current with [block/buzz](https://github.com/block/buzz) without losing fork-layer tooling.

---

## Remotes

```bash
git remote -v
# origin    https://github.com/Blazenetic/blazebuzz.git
# upstream  https://github.com/block/buzz.git
```

If `upstream` is missing:

```bash
git remote add upstream https://github.com/block/buzz.git
git fetch upstream
```

---

## Recommended cadence

| When | Command |
|------|---------|
| Start of a session | `just bb-sync-status` |
| Before large feature work | `just bb-sync-dry` then `just bb-sync` |
| Weekly | `just bb-sync` → `just bb-agent-ready` → `just bb-push` |

---

## Safe merge (default)

```bash
. ./bin/activate-hermit
just bb-sync-status
just bb-sync-dry          # preview
just bb-sync              # merge upstream/main into main
just bb-doctor
just test-unit
just bb-push              # update GitHub fork
```

### What `bb-sync` does

1. Requires a clean working tree (or `--stash`)  
2. Defaults to branch `main` (override with `--allow-branch`)  
3. `git fetch upstream --tags`  
4. **Merge** `upstream/main` (not rebase, unless you ask)  
5. Prefer restoring paths in `scripts/blazenetic/protect.list` on conflict  
6. Re-inject the root `AGENTS.md` Blazenetic pointer if upstream wiped it  

### Rebase (optional)

```bash
just bb-sync-rebase
```

Only when you intentionally want a linear history. Avoid if others share the branch.

---

## Protected paths

Listed in `scripts/blazenetic/protect.list`:

- `BLAZEBUZZ.md`
- `justfile.blazenetic`
- `docs/blazenetic/`
- `scripts/blazenetic/`

Plus a **special case**: the short Blazenetic pointer at the top of root `AGENTS.md`.

---

## Conflict strategy

1. Let git merge run  
2. For protected paths → keep **ours** (Blazenetic) unless upstream has a deliberate reason to change structure  
3. For product code → resolve normally; prefer upstream behavior unless we have a documented fork change  
4. Never resolve by deleting `scripts/blazenetic/` or the justfile import  

---

## After a big upstream jump

```bash
just setup              # if migrations / deps changed
just hooks              # if lefthook config changed
just test-unit
cargo check -p buzz-relay -p buzz-core -p buzz-cli
```

---

## Contributing a fix *to* upstream

1. Branch from a commit close to upstream/main  
2. Avoid bundling Blazenetic-only files in that PR  
3. `git commit -s` (DCO)  
4. Open PR against `block/buzz`  

```bash
git fetch upstream
git switch -c fix/my-thing upstream/main
# …minimal patch…
git push -u origin fix/my-thing
gh pr create --repo block/buzz --base main
```
