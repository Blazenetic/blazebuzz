# Phase 1 — Collaboration loop operator guide

**Goal:** Prove that a human request in Blazebuzz can become a reviewed **draft** PR with evidence posted back to the room — without autonomous merges.

**Host:** FOXTROT · **Repo:** `/mnt/FastSSD/main/code/active/blazebuzz` · **Fork:** [Blazenetic/blazebuzz](https://github.com/Blazenetic/blazebuzz)

Related: [ARCHITECTURE_HANDOVER.md](ARCHITECTURE_HANDOVER.md) · [CAPABILITY_MATRIX.md](CAPABILITY_MATRIX.md) · [RUNBOOK.md](RUNBOOK.md)

---

## 1. The loop (target)

```text
1. Human posts a bounded request in a Blazebuzz room
2. Agent receives / claims it (Dispatcher or Builder)
3. Agent identifies repo + reads local instructions
4. Agent creates isolated Git worktree + feature branch
5. Agent performs a small, low-risk task
6. Repository checks run
7. Commit + push to origin (Blazenetic fork only)
8. Open draft GitHub PR with evidence + handover
9. Concise result posted back to the originating channel
10. Human approves / requests changes / merges
```

**Never automate merge** in Phase 1.

---

## 2. How to launch the loop

### 2.1 Preconditions

```bash
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just bb-doctor          # expect pass (port warnings OK if services up)
just bb-up              # postgres/redis + migrations
# relay already running on :3000, or:
# just relay
just bb-smoke           # health + readiness
just test-unit          # baseline before coding
```

### 2.2 Environment variables (names only — never commit values)

| Variable | Purpose |
|----------|---------|
| `BUZZ_RELAY_URL` | Relay base (`ws://127.0.0.1:3000` or `http://localhost:3000`) |
| `BUZZ_PRIVATE_KEY` | Agent Nostr key (hex or `nsec1…`) for signed writes |
| `BUZZ_AUTH_TAG` | NIP-OA auth tag for owner-reviewed agent drafts (Desktop) |
| `BUZZ_RELAY_PRIVATE_KEY` | Stable relay identity in `.env` (survives restarts) |
| `GH_TOKEN` / `gh` keyring | GitHub CLI auth for issues/PRs (operator host) |

Provider keys for coding harnesses (Codex, Claude, etc.) stay in the host/harness config — not in the repo.

### 2.3 Agent identity setup

1. Each persistent role should eventually have its **own** keypair and Buzz profile.
2. Phase 1 may start with one managed agent (e.g. Fizz as Builder) acting on a human mention.
3. Desktop: owner-reviewed drafts via `buzz agents draft-create` (requires `BUZZ_AUTH_TAG`).
4. CLI path used by agents:

```bash
export PATH="/mnt/FastSSD/main/code/active/blazebuzz/target/debug:$PATH"
# Prefer monorepo target/debug/buzz — desktop target/debug/buzz may be a 0-byte stub
buzz --help
buzz --format compact channels list
```

### 2.4 Primary harness and fallback

| Role | Primary | Fallback |
|------|---------|----------|
| In-room agent (this pilot) | **buzz-acp** → Grok Build / managed ACP agent | Direct human + CLI on FOXTROT |
| Heavy repo implementation | Codex or Claude Code (ACP-capable) | Goose / OpenCode for local experiments |

See [CAPABILITY_MATRIX.md](CAPABILITY_MATRIX.md) for measured suitability.

---

## 3. Channel conventions

### 3.1 Minimum set for the pilot

| Channel | UUID (local FOXTROT seed may differ) | Purpose |
|---------|--------------------------------------|---------|
| `#operations` | (list with `buzz channels list`) | Ops / host |
| `#blazebuzz` | project room | Platform work |
| `#agent-activity` | activity stream | Lifecycle noise |
| `#work-blazebuzz-<objective>` | temporary | Single outcome |

Create a work room:

```bash
buzz channels create \
  --name "work-blazebuzz-<objective>" \
  --type stream \
  --visibility open \
  --description "Objective… Archive after draft PR + human review."
```

### 3.2 Channel → worktree naming

| Artefact | Convention |
|----------|------------|
| Work room | `work-<project>-<short-objective>` |
| Branch | `docs/<topic>` or `feat/<topic>` (Conventional scope) |
| Worktree path | `/mnt/FastSSD/main/code/active/blazebuzz-worktrees/<short-objective>` |
| Issue title | `[Phase 1] <objective>` |
| Draft PR title | `docs(blazenetic): <objective>` |

Example from the first pilot:

- Room: `work-blazebuzz-phase1-loop`
- Branch: `docs/phase1-collaboration-loop`
- Worktree: `…/blazebuzz-worktrees/phase1-collaboration-loop`

### 3.3 What belongs where

| Content | Channel |
|---------|---------|
| Task claim, progress, blocker, completion | Work room (or project room if no work room) |
| Host/relay failures | `#operations` |
| High-volume agent telemetry | `#agent-activity` |
| Architecture decisions that stick | Vault + GitHub PR, not only chat |

---

## 4. Builder runbook (step-by-step)

```bash
# 0. Hermit + doctor
cd /mnt/FastSSD/main/code/active/blazebuzz
. ./bin/activate-hermit
just bb-doctor && just bb-up && just bb-smoke

# 1. Record work item
gh issue create -R Blazenetic/blazebuzz \
  --title "[Phase 1] <objective>" \
  --body "…"

# 2. Isolated worktree (never edit main directly for agent work)
mkdir -p /mnt/FastSSD/main/code/active/blazebuzz-worktrees
git worktree add -b docs/<topic> \
  /mnt/FastSSD/main/code/active/blazebuzz-worktrees/<topic> main
cd /mnt/FastSSD/main/code/active/blazebuzz-worktrees/<topic>

# 3. Implement (docs under docs/blazenetic/ preferred for fork-only work)

# 4. Checks
just test-unit
# docs-only: still run unit tests as the fork gate

# 5. Commit (DCO + human trailers per nest rules when required)
git add docs/blazenetic/
git commit -s -m "docs(blazenetic): <summary>"

# 6. Push origin only — never upstream
git push -u origin HEAD

# 7. Draft PR (link originating channel when using buzz pr)
gh pr create --draft -R Blazenetic/blazebuzz \
  --title "docs(blazenetic): <summary>" \
  --body "…"

# 8. Post completion into the originating Blazebuzz room (evidence, PR URL, risks)
```

### Commit trailers (Buzz nest agents)

When committing from a managed nest agent workspace policy:

```text
Co-authored-by: <human name> <human email>
Signed-off-by: <human name> <human email>
```

Repo-local identity on FOXTROT:

```bash
git config user.name    # e.g. Blazenetic
git config user.email   # e.g. blazenetic@proton.me
```

---

## 5. Human approval points

| Gate | Human required? |
|------|-----------------|
| Claim task / start build | No (agent may claim) |
| Open draft PR | No (Builder) |
| Merge PR | **Yes** |
| `just reset` / destroy volumes | **Yes** |
| Push to `upstream` (block/buzz) | **Never** from agents |
| Expose relay publicly | **Yes** (and out of Phase 1) |
| Grant Blazelife to company agents | **Yes** (default deny) |

---

## 6. Verification checklist

After a loop attempt:

- [ ] `just bb-doctor` pass (warnings for busy ports OK)
- [ ] `just bb-smoke` → health `ok`, readiness `ready`
- [ ] `just test-unit` green on the commit that opened the PR
- [ ] Work done in **worktree + branch**, not on `main`
- [ ] Push went to **origin** (`Blazenetic/blazebuzz`) only
- [ ] PR is **draft**; not merged by agent
- [ ] Channel post includes: outcome, repo, branch, PR URL, checks, risks, next step
- [ ] No secrets in messages, commits, or PR body
- [ ] Another human/agent can re-run from this guide

---

## 7. Troubleshooting

| Symptom | Fix |
|---------|-----|
| `buzz: Permission denied` / empty binary | Use `…/blazebuzz/target/debug/buzz`, not desktop stub |
| Smoke fails | Ensure `buzz-relay` listening; `just bb-up`; check ports |
| `bb-doctor` port warnings | Normal if stack is already up |
| Dirty tree blocks sync | Commit or stash before `just bb-sync` |
| Behind upstream | `just bb-sync-status` then deliberate `just bb-sync` (not mid-pilot) |
| gh auth failure | `gh auth status`; re-login on FOXTROT |
| Agent cannot open Desktop draft | Needs `BUZZ_AUTH_TAG` (managed agents) |

More: [RUNBOOK.md](RUNBOOK.md) · [CACHYOS.md](CACHYOS.md)

---

## 8. Known limitations (Phase 1)

- No Vault Bridge MCP yet — vault reads for architecture were done via GitHub API / explicit paths, not broad `$HOME`.
- No structured job events / execution broker yet — jobs are channel messages + GitHub issues.
- Reviewer independence is process-defined; not yet a separate always-on agent identity.
- Desktop `target/debug/buzz` may be a stub; monorepo CLI is the reliable binary.
- Local relay only; no Blazenet remote access guide in this phase.
- Multi-agent Dispatcher → Builder → Reviewer handoff is manual / mention-based.

### Still manual

- Merge, deploy, vault authoritative writes, Ryan onboarding, scheduled autonomous work.

---

## 9. Phase 2 proposal (do not implement yet)

1. **Vault Bridge MCP** — `vault.search` / `vault.read_note` / `vault.append_handover` with deny-by-default Blazelife.
2. **Structured job envelope** — accepted / started / blocked / completed events into `#agent-activity`.
3. **Separate Reviewer identity** — different session (and ideally model) from Builder for material diffs.
4. **Harness comparison** — measure Codex vs Claude Code vs Goose on one repeated task class.
5. **Ryan onboarding** — membership, private-room policy, no Blazelife.
6. **Blazenet** — remote client path without public relay.
7. **Scheduled operational checks** — health summary to `#operations` (bounded, not free-roaming agents).

Exit test for “Phase 1 done repeatedly”: a non-author human can request a doc fix in-room and receive a draft PR + channel handover without operator terminal babysitting beyond human merge.
