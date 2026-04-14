import { expect, test } from "@playwright/test";

test("landing page renders core SEO content", async ({ page }) => {
  await page.goto("/");

  await expect(page).toHaveTitle(/Terrastack/i);
  await expect(
    page.getByRole("heading", {
      level: 1,
      name: /launch a search-friendly frontend/i,
    }),
  ).toBeVisible();
  await expect(page.getByRole("link", { name: /verify backend connection/i })).toBeVisible();
});
