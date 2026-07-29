#!/usr/bin/env bash
# Smoke-check a local Buzz relay. Exit 0 if healthy.
set -euo pipefail

HEALTH_URL="${BUZZ_SMOKE_HEALTH_URL:-http://127.0.0.1:3000/health}"
READY_URL="${BUZZ_SMOKE_READY_URL:-http://127.0.0.1:8080/_readiness}"
TIMEOUT="${BUZZ_SMOKE_TIMEOUT:-3}"

fail=0
check() {
  local name="$1" url="$2"
  if out="$(curl -fsS --max-time "$TIMEOUT" "$url" 2>&1)"; then
    echo "✓ $name → $url"
    echo "  $out" | head -c 200
    echo
  else
    echo "✗ $name → $url"
    echo "  $out" | head -c 200
    echo
    fail=1
  fi
}

echo "Blazebuzz relay smoke"
check health "$HEALTH_URL"
check readiness "$READY_URL"

if [[ "$fail" -ne 0 ]]; then
  echo
  echo "Relay not healthy. Start it with:"
  echo "  cd $(pwd 2>/dev/null || echo /mnt/FastSSD/main/code/active/blazebuzz)"
  echo "  . ./bin/activate-hermit && just bb-up && just relay"
  exit 1
fi

echo "smoke: OK"
