import { toDisplayName } from "@/lib/site";

describe("toDisplayName", () => {
  it("normalizes dashed or underscored values into a readable site name", () => {
    expect(toDisplayName("terrastack_platform")).toBe("Terrastack Platform");
  });

  it("falls back to the default brand when no value is provided", () => {
    expect(toDisplayName("")).toBe("Terrastack");
  });
});
