# TicketBay

The commands are in `package.json`, the setup is in `README.md`. These are the rules the code cannot tell you.

## Rules

- Money is integer cents, never floats. Only output meant for people or MCP clients converts to euros (`lib/format.ts`, the `*_eur` fields in `src/mcp/tools.ts`).
- Never push to `main`. Every change goes through a pull request, and the `gate` workflow must be green.
- Never edit the migrations in `drizzle/` by hand. Change the schema, then run `npm run db:generate`.
- Test behavior through the public API: the route handlers and the `src/domain` / `src/services` functions the app calls. Never test private helpers, never assert on internal calls, never mock `src/domain` or `src/services`. The HTTP and integration tests mock only the wiring seams `lib/auth`, `src/db/client` and `src/payments`.
- Never mark a mutant equivalent yourself. When the CI mutation check finds a survivor, write a test that kills it. If you think it cannot be killed, stop and ask the human, with the reason.
- A regression test goes in a new file `tests/domain/regression-<short-slug>.test.ts` (code in `src/domain`) or `tests/lib/regression-<short-slug>.test.ts` (code in `lib/`). The fast suite is `npm run test:unit`. Do not edit the unit test config.
