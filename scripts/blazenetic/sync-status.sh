#!/usr/bin/env bash
# Report fork position vs origin + upstream and protected-file health.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

BLU=$'\033[0;34m'
RST=$'\033[0m'

echo "${BLU}==>${RST} Fetching remotes (status only)…"
git fetch origin --quiet 2>/dev/null || echo "  (origin fetch failed — offline?)"
git fetch upstream --quiet 2>/dev/null || echo "  (upstream fetch failed — offline?)"

branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")"
head_sha="$(git rev-parse --short HEAD)"
echo
echo "Branch:  $branch"
echo "HEAD:    $head_sha ($(git log -1 --format='%s'))"
echo "origin:  $(git remote get-url origin 2>/dev/null || echo n/a)"
echo "upstream:$(git remote get-url upstream 2>/dev/null || echo n/a)"

if git rev-parse --verify upstream/main >/dev/null 2>&1; then
  behind="$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo '?')"
  ahead="$(git rev-list --count upstream/main..HEAD 2>/dev/null || echo '?')"
  up_sha="$(git rev-parse --short upstream/main)"
  echo
  echo "vs upstream/main ($up_sha):"
  echo "  behind: $behind commits"
  echo "  ahead:  $ahead commits (Blazenetic-only)"
  if [[ "$behind" == "0" && "$ahead" == "0" ]]; then
    echo "  status: identical to upstream/main"
  elif [[ "$behind" == "0" ]]; then
    echo "  status: ahead of upstream (fork commits only)"
  elif [[ "$ahead" == "0" ]]; then
    echo "  status: behind upstream — run: just bb-sync"
  else
    echo "  status: diverged — merge carefully (just bb-sync)"
  fi
  if [[ "$behind" != "0" && "$behind" != "?" ]]; then
    echo
    echo "Upcoming upstream commits (max 15):"
    git log --oneline --no-merges "HEAD..upstream/main" | head -15 || true
  fi
else
  echo
  echo "upstream/main not available — add remote: git remote add upstream https://github.com/block/buzz.git"
fi

if git rev-parse --verify origin/main >/dev/null 2>&1; then
  obehind="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
  oahead="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo '?')"
  echo
  echo "vs origin/main:"
  echo "  behind: $obehind  ahead: $oahead"
fi

echo
if git diff --quiet && git diff --cached --quiet; then
  echo "Working tree: clean"
else
  echo "Working tree: DIRTY"
  git status --short | head -40
fi

protect="$ROOT/scripts/blazenetic/protect.list"
if [[ -f "$protect" ]]; then
  echo
  echo "Protected Blazenetic paths:"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    if [[ -e "$line" ]]; then
      echo "  ok  $line"
    else
      echo "  MISSING  $line"
    fi
  done < "$protect"
fi

echo
echo "Dry-run merge preview: just bb-sync-dry"
echo "Apply merge:           just bb-sync"
