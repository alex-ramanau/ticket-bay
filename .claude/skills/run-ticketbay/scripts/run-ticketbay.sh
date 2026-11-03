#!/usr/bin/env bash
# run-ticketbay.sh — get TicketBay ready to serve: Node check, install, Postgres, migrate, seed an empty database.
# Usage: scripts/run-ticketbay.sh [--reset]   (--reset reseeds over existing data: wipes users, API keys, orders)
# Does not start the server; run `npm run dev` after it. Works on the host (Docker Postgres) and inside ./box (db:5432).
set -euo pipefail

RESET=0
for a in "$@"; do
  case "$a" in
    --reset) RESET=1 ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "usage: $0 [--reset]" >&2; exit 2 ;;
  esac
done

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(git -C "$here" rev-parse --show-toplevel)"
[ -f package.json ] && grep -q '"name": "ticketbay"' package.json || { echo "not the TicketBay repo: $(pwd)" >&2; exit 1; }
state() { node "$here/db-state.mjs" "$@"; }
val() { sed -n "s/^$1=//p"; }

echo "== node"
major="$(node -p 'process.versions.node.split(".")[0]')"
[ "$major" = "$(cut -d. -f1 .nvmrc)" ] || { echo "Node $(node -v), this repo needs $(cat .nvmrc): run 'nvm use'" >&2; exit 1; }
node -v

echo "== database target"
info="$(state)"
host="$(val host <<<"$info")"; port="$(val port <<<"$info")"; db="$(val db <<<"$info")"
echo "$host:$port/$db"
case "$host" in
  localhost|127.0.0.1) where=host ;;
  db) where=box ;;
  *) echo "DATABASE_URL points at '$host', not a local database. Refusing: the seed wipes users, API keys and orders." >&2; exit 1 ;;
esac

echo "== dependencies"
if [ ! -f node_modules/.package-lock.json ] || [ package-lock.json -nt node_modules/.package-lock.json ]; then
  npm ci
else
  echo "node_modules up to date"
fi

echo "== postgres ($where)"
if [ "$where" = host ]; then
  docker info >/dev/null 2>&1 || { echo "Docker is not running. Start Docker, or run this inside ./box (it has its own Postgres)." >&2; exit 1; }
  npm run --silent db:up
else
  echo "inside the box: using its own Postgres at db:5432, no db:up"
fi

echo "== migrate"
npm run --silent db:migrate

echo "== seed"
counts="$(state --counts)"
orders="$(val orders <<<"$counts")"; events="$(val events <<<"$counts")"; users="$(val users <<<"$counts")"
if [ "$orders" -le 0 ] && [ "$events" -le 0 ]; then
  npm run --silent db:seed
elif [ "$RESET" -eq 1 ]; then
  echo "reset: wiping $users users, $orders orders, $events events and reseeding"
  npm run --silent db:seed
else
  echo "skipped: database already has $events events, $orders orders, $users users (pass --reset to wipe and reseed)"
fi

echo "== ready to start"
echo "next: npm run dev   (then scripts/wait-ready.sh)"
echo "logins (password ticketbay-demo): anna@ticketbay.test (customer), admin@ticketbay.test (admin)"
