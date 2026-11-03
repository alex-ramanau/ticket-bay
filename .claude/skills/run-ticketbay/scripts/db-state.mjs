#!/usr/bin/env node
// db-state.mjs — print where DATABASE_URL points and, with --counts, what is in it.
// Usage: node scripts/db-state.mjs [--counts]   (run from the repo root)
// Reads the environment the way scripts/local-env.ts does: env first, then .env, then .env.example.
// Prints shell-friendly lines: host=… port=… db=…, and with --counts events=… orders=… users=…
// (-1 = the table does not exist yet). Exit 1 if DATABASE_URL is unset or the database is unreachable.
import fs from "node:fs";

if (process.argv.includes("-h") || process.argv.includes("--help")) {
  console.log("usage: node db-state.mjs [--counts]   (run from the repo root)");
  process.exit(0);
}

for (const file of [".env", ".env.example"]) {
  if (fs.existsSync(file)) process.loadEnvFile(file);
}
const raw = process.env.DATABASE_URL;
if (!raw) {
  console.error("DATABASE_URL is not set and there is no .env or .env.example in this folder.");
  process.exit(1);
}
const url = new URL(raw);
console.log(`host=${url.hostname}`);
console.log(`port=${url.port || "5432"}`);
console.log(`db=${url.pathname.slice(1)}`);

if (process.argv.includes("--counts")) {
  const { default: pg } = await import("pg");
  const client = new pg.Client({ connectionString: raw, connectionTimeoutMillis: 5000 });
  try {
    await client.connect();
  } catch (err) {
    console.error(`cannot reach Postgres at ${url.host}: ${err.message}`);
    process.exit(1);
  }
  for (const [name, table] of [["events", "events"], ["orders", "orders"], ["users", '"user"']]) {
    const exists = await client.query("select to_regclass($1) as t", [table]);
    const n = exists.rows[0].t ? Number((await client.query(`select count(*) as n from ${table}`)).rows[0].n) : -1;
    console.log(`${name}=${n}`);
  }
  await client.end();
}
