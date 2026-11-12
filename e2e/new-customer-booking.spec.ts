// A brand-new customer: creates an account, books one ticket, and finds it
// under My orders. Assert what the user SEES.
import { randomUUID } from "node:crypto";
import { test, expect } from "@playwright/test";
import { BOOKING_AT_MS, E2E_EVENTS, type E2EUser } from "./support/env";
import { bookThroughUI, setClock, signUp, ticketsLine, totalLine } from "./support/app";

test("a new customer signs up, books one ticket, and sees it in My orders", async ({ page, context }) => {
  // Not a seeded account: this spec creates it, and a retry needs an unused email.
  const customer: E2EUser = { name: "Nina New", email: `new-customer-${randomUUID()}@e2e.test` };
  await setClock(context, BOOKING_AT_MS);

  await signUp(page, customer);
  await expect(page.getByRole("button", { name: "Account", exact: true }), "signing up also signs in").toContainText(customer.name);

  await bookThroughUI(page, customer, E2E_EVENTS.newCustomer, "1");
  // 1 x €50.00, plus the 3% service fee (€1.50).
  await expect(ticketsLine(page)).toHaveText("Tickets €50.00");
  await expect(totalLine(page)).toHaveText("Total paid €51.50");

  await page.goto("/orders");
  await expect(page.getByRole("heading", { name: "My orders" })).toBeVisible();
  await expect(page.getByText(`1 order for ${customer.email}`), "a new account holds this order and no other").toBeVisible();
  const row = page.getByRole("row").filter({ hasText: "First Booking Night" });
  await expect(row.getByRole("cell")).toHaveText([/^TB-\d{5}/, "First Booking Night", /Jun 2031/, "1", "€51.50", "Paid"]);
});
