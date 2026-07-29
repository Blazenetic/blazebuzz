#!/usr/bin/env bash
# Merge (or rebase) upstream/main into the current Blazenetic fork branch.
#
# Usage:
#   sync-upstream.sh              # merge upstream/main into main (default)
#   sync-upstream.sh --dry-run    # show what would land
#   sync-upstream.sh --rebase     # rebase onto upstream/main instead
#   sync-upstream.sh --stash      # stash dirty tree first
#   sync-upstream.sh --allow-branch  # allow non-main current branch
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DRY_RUN=0
REBASE=0
STASH=0
ALLOW_BRANCH=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --rebase) REBASE=1 ;;
    --stash) STASH=1 ;;
    --allow-branch) ALLOW_BRANCH=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "error: no 'upstream' remote. Add with:"
  echo "  git remote add upstream https://github.com/block/buzz.git"
  exit 1
fi

branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [[ -z "$branch" ]]; then
  echo "error: detached HEAD — checkout a branch first"
  exit 1
fi
if [[ "$branch" != "main" && "$ALLOW_BRANCH" -ne 1 ]]; then
  echo "error: current branch is '$branch' (expected main)."
  echo "  Pass --allow-branch to sync onto this branch anyway."
  exit 1
fi

dirty=0
if ! git diff --quiet || ! git diff --cached --quiet; then
  dirty=1
fi
if [[ "$dirty" -eq 1 && "$STASH" -ne 1 && "$DRY_RUN" -ne 1 ]]; then
  echo "error: working tree is dirty. Commit/stash first, or pass --stash."
  git status --short | head -20
  exit 1
fi

echo "==> Fetching upstream…"
git fetch upstream --tags

if ! git rev-parse --verify upstream/main >/dev/null 2>&1; then
  echo "error: upstream/main not found after fetch"
  exit 1
fi

behind="$(git rev-list --count HEAD..upstream/main)"
ahead="$(git rev-list --count upstream/main..HEAD)"
echo "vs upstream/main: behind=$behind ahead=$ahead"

if [[ "$behind" -eq 0 ]]; then
  echo "Already up to date with upstream/main."
  exit 0
fi

echo
echo "Commits that will land (max 30):"
git log --oneline --no-merges "HEAD..upstream/main" | head -30
echo

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "[dry-run] no changes applied. Run without --dry-run to merge."
  exit 0
fi

if [[ "$dirty" -eq 1 && "$STASH" -eq 1 ]]; then
  echo "==> Stashing local changes…"
  git stash push -u -m "blazebuzz-sync-$(date +%Y%m%d%H%M%S)"
fi

# Snapshot protected files before merge (restore if clobbered)
PROTECT_LIST="$ROOT/scripts/blazenetic/protect.list"
TMP_SNAP="$(mktemp -d)"
cleanup() { rm -rf "$TMP_SNAP"; }
trap cleanup EXIT

if [[ -f "$PROTECT_LIST" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ -e "$line" ]]; then
      mkdir -p "$TMP_SNAP/$(dirname "$line")"
      if [[ -d "$line" ]]; then
        cp -a "$line" "$TMP_SNAP/$(dirname "$line")/"
      else
        cp -a "$line" "$TMP_SNAP/$line"
      fi
    fi
  done < "$PROTECT_LIST"
fi

# Snapshot AGENTS.md pointer block if present
AGENTS_PTR_FILE="$TMP_SNAP/AGENTS.pointer.md"
if head -15 AGENTS.md 2>/dev/null | grep -qi 'blazenetic\|blazebuzz'; then
  # capture from start through first horizontal rule after the pointer, or first 12 lines
  head -12 AGENTS.md > "$AGENTS_PTR_FILE" || true
fi

if [[ "$REBASE" -eq 1 ]]; then
  echo "==> Rebasing onto upstream/main…"
  if ! git rebase upstream/main; then
    echo "error: rebase conflicts. Resolve, then: git rebase --continue"
    echo "  Or abort: git rebase --abort"
    exit 1
  fi
else
  echo "==> Merging upstream/main…"
  if ! git merge --no-ff upstream/main -m "chore(blazebuzz): merge upstream/main

Synced block/buzz into Blazenetic/blazebuzz.

Signed-off-by: $(git config user.name) <$(git config user.email)>"; then
    echo
    echo "Merge conflicts detected."
    # Prefer ours for protected paths
    if [[ -f "$PROTECT_LIST" ]]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        if git ls-files -u -- "$line" 2>/dev/null | grep -q . || [[ -e "$line" ]]; then
          if [[ -e "$TMP_SNAP/$line" || -d "$TMP_SNAP/$(basename "$line")" ]]; then
            echo "  restoring protected: $line"
            if [[ -d "$TMP_SNAP/$(basename "${line%/}")" && "$line" == */ ]]; then
              rm -rf "$line"
              cp -a "$TMP_SNAP/$(basename "${line%/}")" "$(dirname "$line")/"
            elif [[ -f "$TMP_SNAP/$line" ]]; then
              mkdir -p "$(dirname "$line")"
              cp -a "$TMP_SNAP/$line" "$line"
            fi
            git add -- "$line" 2>/dev/null || true
          fi
        fi
      done < "$PROTECT_LIST"
    fi
    if git diff --name-only --diff-filter=U | grep -q .; then
      echo "Remaining conflicts:"
      git diff --name-only --diff-filter=U
      echo "Resolve manually, then: git commit"
      exit 1
    fi
    git commit --no-edit -s || true
  fi
fi

# Re-apply AGENTS.md pointer if stripped
if [[ -f "$AGENTS_PTR_FILE" ]] && ! head -15 AGENTS.md | grep -qi 'blazenetic\|blazebuzz'; then
  echo "==> Re-injecting Blazenetic AGENTS.md pointer…"
  {
    cat "$AGENTS_PTR_FILE"
    echo
    # skip original first lines that were our pointer; keep rest of upstream file
    # If we lost the pointer entirely, prepend our block to current AGENTS.md
    cat AGENTS.md
  } > AGENTS.md.tmp
  # Simpler: prepend pointer paragraph if missing
  {
    echo "> **Blazenetic fork (Blazebuzz):** read [BLAZEBUZZ.md](BLAZEBUZZ.md) and [docs/blazenetic/AGENTS.md](docs/blazenetic/AGENTS.md) first. Upstream Buzz agent guide continues below."
    echo
    cat AGENTS.md
  } > AGENTS.md.tmp
  mv AGENTS.md.tmp AGENTS.md
  git add AGENTS.md
  if ! git diff --cached --quiet; then
    git commit -s -m "chore(blazebuzz): restore AGENTS.md fork pointer after upstream sync"
  fi
fi

# Restore any missing protected paths from snapshot
if [[ -f "$PROTECT_LIST" ]]; then
  restored=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ ! -e "$line" && -e "$TMP_SNAP/$line" ]]; then
      mkdir -p "$(dirname "$line")"
      cp -a "$TMP_SNAP/$line" "$line"
      git add -- "$line"
      restored=1
      echo "  restored missing protected path: $line"
    fi
  done < "$PROTECT_LIST"
  if [[ "$restored" -eq 1 ]]; then
    git commit -s -m "chore(blazebuzz): restore protected fork paths after upstream sync" || true
  fi
fi

echo
echo "Sync complete."
echo "  HEAD: $(git rev-parse --short HEAD)"
behind_now="$(git rev-list --count HEAD..upstream/main)"
echo "  behind upstream/main: $behind_now"
echo
echo "Next:"
echo "  just bb-doctor"
echo "  just test-unit"
echo "  just bb-push   # when ready to update origin"
