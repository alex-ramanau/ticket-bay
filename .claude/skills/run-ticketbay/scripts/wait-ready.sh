#!/usr/bin/env bash
# wait-ready.sh — wait until the running dev server serves pages, the API and the demo login.
# Usage: scripts/wait-ready.sh [port] [timeout-seconds]   (defaults: $PORT or 3000, 120)
set -euo pipefail

case "${1:-}" in -h|--help) sed -n '2,3p' "$0"; exit 0 ;; esac
port="${1:-${PORT:-3000}}"
timeout="${2:-120}"
[[ "$port" =~ ^[0-9]+$ && "$timeout" =~ ^[0-9]+$ ]] || { echo "usage: $0 [port] [timeout-seconds]" >&2; exit 2; }
base="http://localhost:$port"

echo "== waiting for $base (up to ${timeout}s; the first request compiles)"
deadline=$((SECONDS + timeout))
until code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 "$base/")" && [ "$code" = 200 ]; do
  [ "$SECONDS" -lt "$deadline" ] || { echo "no 200 from $base/ after ${timeout}s (last status: ${code:-none}). Is npm run dev running on port $port?" >&2; exit 1; }
  sleep 2
done
echo "storefront: 200"

events="$(curl -sf --max-time 60 "$base/api/v1/events" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{console.log(JSON.parse(s).events.length)})')"
echo "api: $events events"
[ "$events" -gt 0 ] || { echo "the API lists no events: the database is not seeded (scripts/run-ticketbay.sh)" >&2; exit 1; }

login="$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 -X POST "$base/api/auth/sign-in/email" \
  -H 'content-type: application/json' -H "origin: $base" \
  -d '{"email":"anna@ticketbay.test","password":"ticketbay-demo"}')"
echo "demo login: $login"
[ "$login" = 200 ] || { echo "sign-in as anna@ticketbay.test answered $login. 403 = BETTER_AUTH_URL does not match $base; 401 = the demo accounts are gone (scripts/run-ticketbay.sh --reset)." >&2; exit 1; }

echo "READY: $base (storefront), $base/admin (dashboard)"
