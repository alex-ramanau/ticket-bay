import { describe, it, expect } from "vitest";
import { serviceFee, vatPortion } from "../../src/domain/fees";

describe("serviceFee", () => {
  it("charges 3% on a normal order", () => {
    expect(serviceFee(10000)).toBe(300);
  });

  it("charges the 100-cent minimum on a small order", () => {
    // 3% of €10 is 30 cents; the customer still pays the €1 minimum
    expect(serviceFee(1000)).toBe(100);
  });

  it("charges the minimum when 3% lands exactly on 99 cents", () => {
    // 3% of €33 is 99 cents — one cent under the minimum
    expect(serviceFee(3300)).toBe(100);
  });

  it("charges plain 3% once it reaches the minimum", () => {
    expect(serviceFee(3334)).toBe(100);
    expect(serviceFee(3400)).toBe(102);
  });

  it("caps the fee at 2000 cents on a large order", () => {
    // 3% of €1,000 would be €30; the cap holds it at €20
    expect(serviceFee(100000)).toBe(2000);
  });

  it("caps the fee when 3% lands exactly one cent over the cap", () => {
    // 3% of €667 is 2001 cents
    expect(serviceFee(66700)).toBe(2000);
  });

  it("charges plain 3% right up to the cap", () => {
    expect(serviceFee(66600)).toBe(1998);
  });
});

describe("vatPortion", () => {
  it("extracts 27% VAT from a gross price", () => {
    expect(vatPortion(12700, 27)).toBe(2700);
  });
});
