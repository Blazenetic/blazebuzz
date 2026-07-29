# Complex State × Blazebuzz — architecture handover

**Status:** Phase 1 operator digest (not a redesign)  
**Date:** 2026-07-30  
**Sources of truth:** Complex State vault `02 - Areas/Blazebuzz/` (draft PR [complex-state-vault#1](https://github.com/Blazenetic/complex-state-vault/pull/1)); this fork layer under `docs/blazenetic/`.

This document is a **handover for humans and agents working on FOXTROT**. Full architecture remains in the vault. Do not treat this file as permission to implement every idea immediately.

---

## What Blazebuzz is

Blazebuzz is Complex State’s private collaboration and execution-coordination layer: shared rooms where humans and signed AI-agent identities discuss work, run jobs, present evidence, and request approvals.

It is **not** the sole source of truth for company information.

| Domain | Authority | Blazebuzz role |
|--------|-----------|----------------|
| Code / delivery | GitHub | Coordinate jobs, surface status, collect evidence and approvals |
| Durable knowledge | Obsidian vaults | Retrieve context, append handovers, propose reviewed updates |
| Business documents | Google Drive | Link and notify; avoid silent duplicate authority |
| Collaboration | Blazebuzz relay | Persist signed messages, jobs, reactions, workflow state, audit |
| Secrets | Host env / secret store | Reference identifiers only — never commit secret values |

**Fork identity:** product code stays named Buzz for upstream sync. Blazenetic ops live under `docs/blazenetic/`, `scripts/blazenetic/`, `justfile.blazenetic`, `BLAZEBUZZ.md`. See [BLAZEBUZZ.md](../../BLAZEBUZZ.md).

---

## Approved baseline decisions

1. One private Complex State community initially.
2. Local access first; Blazenet/NetBird for remote later. Do **not** expose the relay publicly in Phase 1.
3. GitHub remains authoritative for repos, issues, branches, PRs, reviews, releases.
4. Obsidian vaults remain authoritative for durable knowledge and architecture.
5. Google Drive holds business-facing / broadly shareable docs.
6. Blazebuzz coordinates conversations, jobs, approvals, workflows, execution events, searchable operational history.
7. Builder agents may create worktrees, branches, commits, and **draft** PRs.
8. **Human approval** required for merges, destructive ops, external publication, production changes.
9. Mitchell-authorised personal agents may receive policy-controlled access to Blazelife, Complex State, Complex Labs.
10. Ryan and shared company agents must **not** receive Blazelife by default.
11. Vault access should use a policy-aware Vault Bridge MCP (Phase 2+) — not unrestricted filesystem access.
12. Do not replace GitHub with Buzz’s native forge during initial phases.

---

## Context map

```text
People (Mitchell, Ryan, collaborators)
            │
            v
     Blazebuzz community
  channels · DMs · jobs · workflows · audit
       │            │              │
       v            v              v
  Dispatcher   Execution      Operator
                    │
     ┌──────────────┼──────────────────┐
     v              v                  v
 Coding harness  Vault Bridge MCP*  GitHub
 (Codex/Claude/   (Phase 2+)        issues/PRs
  Goose/OpenCode/
  buzz-acp)
     │
     v
 isolated worktrees · bounded shells
```

\* Blazelife only for Mitchell-authorised personal agents.

---

## Channel model (Phase 1 minimum)

### Operational commons (create early)

| Channel | Purpose | Archive? |
|---------|---------|----------|
| `#operations` | Host health, restarts, smoke failures, ops pages | No — durable |
| `#blazebuzz` | Project room for the platform itself | No — durable |
| `#agent-activity` | Agent lifecycle noise (started / blocked / done) | No — durable |
| `#inbox` / `#help-and-routing` | Optional later for multi-human triage | Optional |

### Work rooms (temporary)

Pattern: `#work-<project>-<objective>`

Example: `#work-blazebuzz-phase1-loop`

Each work room should record (in canvas or pinned handover message):

- project + objective  
- accountable human  
- assigned agents / roles  
- GitHub repo, issue, branch, PR when known  
- definition of done  
- archive condition  

**Archive** after final summary + human acknowledgement. History remains searchable.

### Private rooms (later)

`#founder-office`, `#ryan-and-mitchell`, etc. Agents join only via deliberate membership — never inferred.

---

## Agent roles (Phase 1 minimum)

Use **distinct responsibilities** even if the same harness runs multiple personas.

| Role | Responsibility | May not |
|------|----------------|---------|
| **Dispatcher** | Accept request, bound scope, open/link issue + work room, pick harness | Silently expand scope; merge |
| **Builder** | Isolated worktree/branch, implement, tests, commit, draft PR, post evidence | Merge; destroy data; expose secrets |
| **Reviewer** | Independent read of diff + checks; separate session preferred | Rubber-stamp without inspecting; approve own build |

Full roster (Librarian, Researcher, Operator) is Phase 2+ unless needed for a single loop.

---

## Authority boundaries

| Action | Who |
|--------|-----|
| Create branch / worktree / commit / draft PR | Builder (autonomous when authorised) |
| Merge PR | Human only |
| `just reset`, force-push main, delete vault content | Human only, explicit |
| Public relay exposure / production deploy | Human only, out of Phase 1 |
| Blazelife access | Mitchell personal agents only (policy) |
| Shell / file tools | Operator-level trust — bound working directory |

---

## Sources to re-read

| Doc | Location |
|-----|----------|
| Architecture index | Vault: `02 - Areas/Blazebuzz/README.md` |
| System architecture | Vault: `System Architecture.md` |
| Implementation roadmap | Vault: `Implementation Roadmap.md` |
| Decisions / risks / experiments | Vault: `Decisions Risks and Experiments.md` |
| Fork entry | [BLAZEBUZZ.md](../../BLAZEBUZZ.md) |
| Agent rules (fork) | [AGENTS.md](AGENTS.md) |
| Runbook | [RUNBOOK.md](RUNBOOK.md) |
| Collaboration loop (this pilot) | [PHASE1_COLLABORATION_LOOP.md](PHASE1_COLLABORATION_LOOP.md) |
| Capability matrix | [CAPABILITY_MATRIX.md](CAPABILITY_MATRIX.md) |

Draft vault PR: https://github.com/Blazenetic/complex-state-vault/pull/1  
Branch: `docs/blazebuzz-architecture-v0.1`
