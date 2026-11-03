---
name: run-ticketbay
description: "Start TicketBay from zero: database, demo data, logins. Use when the user wants to get it running (just cloned it, on my laptop, start the app, run it locally, run the dev server), asks for the admin password, the demo login or how to sign in to the dashboard, or wants to set up the database, seed or reset the demo data. Use it before answering a login question from the README: it holds the verified accounts. Checks Node 22, installs, starts Postgres (or uses the box's own), migrates, seeds only an empty database, starts npm run dev, waits until pages, the API and the demo login answer, then gives the URLs and the two demo accounts. Never seeds a database that is not local, never reseeds over existing data unless the user asked to reset, never deletes the Postgres volume. Not for finding why something looks wrong (debug-runbook) or for running the tests."
---

# Run TicketBay

From a fresh clone (or a stopped machine) to a dev server at http://localhost:3000 with the demo data and a working login. Run every command from the repo root.

## Steps

1. **Answer a login question without starting anything.** If the user only asks how to log in: both accounts use the password `ticketbay-demo`; `anna@ticketbay.test` is a customer with order history under **My orders**, `admin@ticketbay.test` opens `/admin`. Done when the question is answered; stop unless they also want it running.
2. **Decide on a reset.** Pass `--reset` only when the user said reset, reseed, wipe or fresh demo data. Done when you know which of the two commands in step 3 to run.
3. **Prepare the app.** Run `.claude/skills/run-ticketbay/scripts/run-ticketbay.sh` (or with `--reset`). It checks Node against `.nvmrc`, runs `npm ci` when `node_modules` is stale, runs `npm run db:up` on the host (skipped inside `./box`, which has its own Postgres at `db:5432`), migrates, and seeds only when the database has no events and no orders. Done when it prints `== ready to start`. On a failure, fix what its last line names and run it again; read the Gotchas first.
4. **Start the dev server in the background.** Run `npm run dev` as a background command (for another port: `PORT=3100 BETTER_AUTH_URL=http://localhost:3100 npm run dev`). If port 3000 is already taken by a running TicketBay, skip this step. Done when the command is still running after its `Ready in` line; if it exited, read its output against the Gotchas.
5. **Wait until it works.** Run `.claude/skills/run-ticketbay/scripts/wait-ready.sh` (or `wait-ready.sh 3100`). It checks the storefront, `GET /api/v1/events` and a real sign-in as anna. Done when it prints `READY:`.
6. **Report.** Give the user exactly this, with the real port:

   ```
   TicketBay is running.
   Storefront  http://localhost:3000
   Dashboard   http://localhost:3000/admin
   Password for both: ticketbay-demo
     anna@ticketbay.test   customer, has orders under My orders
     admin@ticketbay.test  admin, opens /admin
   Seeded: 8 events, ~300 orders, codes WELCOME10 STUDENT15 CRAFT20 (SUMMER25 expired, LAUNCH50 inactive)
   ```

   If step 3 skipped the seed, replace the last line with the counts it printed. Done when the user has the URLs and both logins.

## Gotchas

- The seed runs `TRUNCATE` on users (with their sessions and API keys), orders, events and discount codes. Never run `npm run db:seed` yourself: go through `run-ticketbay.sh`, which seeds an empty database and needs `--reset` for any other.
- `run-ticketbay.sh` refuses when `DATABASE_URL`'s host is not `localhost`, `127.0.0.1` or `db`. Never work around it by editing `DATABASE_URL`: ask the user which database they meant.
- Never run `docker compose down -v` unless the user asks: it deletes the `ticketbay-pg` volume. `npm run db:down` stops Postgres and keeps the data.
- Sign-in fails with 403 "Invalid origin" at `http://127.0.0.1:3000`: Better Auth accepts only the origin in `BETTER_AUTH_URL`. Open `http://localhost:<port>`, and set `BETTER_AUTH_URL` to the same port as `PORT`.
- Inside `./box` there is no Docker: never run `npm run db:up` there. The box's Postgres is separate from the host's, so seeding one does not seed the other.
- Port 5432 taken by another Postgres (`db:up` fails with "port is already allocated"): put `POSTGRES_PORT=5433` and the same port in `DATABASE_URL` in `.env`, then run step 3 again.
- `npm run dev` prints `Ready`, then dies with `Failed to open database … failed to sync file .next/dev/cache/turbopack…: Invalid argument (os error 22)`: the repo is on a filesystem without fsync (a VirtualBox `vboxsf` shared folder; check with `df -T .`). Start it with `npx next dev --webpack` instead. Do not edit `next.config.ts` for it.
- Seeded dates are relative to the hour the seed ran. Days later, the early-bird windows and refund windows have moved on; reseed with `--reset` only if the user wants fresh dates.

Last verified: 2026-11-02 with Claude Code, Node 22.23.4, Next.js 16.3.6 (empty Docker volume: steps 3-5 end to end on Linux; second run skipped the seed; a remote DATABASE_URL was refused; 127.0.0.1 origin gave 403). Not yet run inside `./box`.
