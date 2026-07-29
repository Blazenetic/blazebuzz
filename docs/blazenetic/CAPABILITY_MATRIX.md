# Phase 1 — Agent integration capability matrix

**Assessed on:** FOXTROT · 2026-07-30  
**Context:** First Blazebuzz collaboration-loop pilot  
**Method:** Binary presence, `--help` / launch probes, `gh auth status`, live `buzz` CLI against local relay. Not a full multi-hour bake-off.

---

## Matrix

| Harness | Launch method | Provider / model | Tool access | Working-directory control | Cancel / timeout | Credential handling | Suitability for first pilot |
|---------|---------------|------------------|-------------|---------------------------|------------------|---------------------|----------------------------|
| **buzz-cli** | `target/debug/buzz` after hermit | N/A (API client) | Relay ops only | N/A | N/A | `BUZZ_*` env | **Required infrastructure** — messages, channels, feed |
| **buzz-acp** | `buzz-acp` binary; Desktop managed agents | Harness-selected (Grok Build used in-room) | MCP + shell via host agent | Desktop/worktree per agent config | ACP cancel paths exist in stack | Agent key + `BUZZ_AUTH_TAG` for drafts | **Primary for in-room loop** — proven by this pilot mention→work |
| **buzz-agent** | `buzz-agent` ACP agent | Needs `BUZZ_AGENT_PROVIDER` | MCP (buzz-dev-mcp) | Per-session MCP cwd | Documented process-group kill | Provider env on host | **Strong fallback coding core** once provider set |
| **Goose** | `/usr/bin/goose` | Host config | Goose tools | Session cwd | Goose controls | Local config | Secondary autonomous investigation |
| **Codex** | `~/.local/bin/codex` | OpenAI/Codex account | Shell/file via Codex | Project roots | Codex session controls | Local login | Preferred for heavy repo implementation (later) |
| **Claude Code** | `~/.local/bin/claude` | Anthropic | Claude tools | Project roots | Session controls | Local login | Alternate heavy implementation |
| **OpenCode** | `/usr/bin/opencode` | Host config | Local tools | Project roots | Session controls | Local config | Fast local experiment |
| **GitHub (`gh`)** | CLI | N/A | Issues/PRs/repos | N/A | N/A | keyring (`Blazenetic`) | **Required** for draft PR path |
| **MCP (host)** | Desktop / agent config | Varies | Per-server (GitHub, Gmail, Drive, …) | Server-defined | Server-defined | Host MCP secrets | Use sparingly; no Blazelife via broad FS |

---

## Selection for Phase 1 pilot

| Choice | Harness | Rationale |
|--------|---------|-----------|
| **Primary** | Managed **buzz-acp** agent (in-room Fizz) + monorepo **buzz-cli** + **gh** | Already receives channel @mentions; can post evidence; GitHub authenticated as Blazenetic |
| **Fallback** | Operator terminal on FOXTROT with Codex/Claude Code + same git conventions | If ACP agent fails, human or alternate harness follows [PHASE1_COLLABORATION_LOOP.md](PHASE1_COLLABORATION_LOOP.md) |

---

## Known environment notes

1. **CLI path trap:** `desktop/src-tauri/target/debug/buzz` can be a **0-byte** non-executable stub while monorepo `target/debug/buzz` is the real binary. Prefer `$REPO/target/debug` on `PATH` after `cargo build -p buzz-cli`.
2. **Relay:** Local `ws://127.0.0.1:3000` healthy at assessment (`just bb-smoke` OK). Do not expose publicly.
3. **Git remotes:** `origin` = Blazenetic/blazebuzz (push OK); `upstream` = block/buzz (never push).
4. **Fork vs upstream:** `main` may diverge (behind/ahead upstream). Do not run `bb-sync` mid-pilot unless intentional.
5. **Secrets:** No secret values in docs, channel posts, or PRs.

---

## Re-assessment trigger

Re-run this matrix after:

- first failure of ACP→draft-PR path;
- provider or Desktop agent config change;
- always-on deployment mode differs from dev compose.
