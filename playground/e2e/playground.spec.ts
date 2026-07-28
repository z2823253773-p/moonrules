import { expect, type Page, test } from "@playwright/test";

async function openPlayground(page: Page): Promise<void> {
  await page.goto("/");
  await expect(
    page.getByRole("heading", { name: "MoonRules Playground" }),
  ).toBeVisible();
  await expect(page.locator("#example option")).not.toHaveCount(0);
  await expect(page.locator("#copy-result")).toBeEnabled();
}

test.describe("MoonRules Playground", () => {
  test("default coupon scenario evaluates to FAIL with a trace", async ({
    page,
  }) => {
    await openPlayground(page);
    await page.getByRole("button", { name: "Evaluate" }).click();
    await expect(page.locator(".status-card")).toContainText("FAIL");
    await expect(page.getByRole("tab", { name: "Trace" })).toBeVisible();
    await expect(page.locator(".trace-node").first()).toBeVisible();
  });

  test("mobile layout keeps both editors and actions reachable", async ({
    page,
  }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await openPlayground(page);
    await expect(page.getByLabel("Rule JSON editor")).toBeVisible();
    await expect(page.getByLabel("Data JSON editor")).toBeVisible();
    await expect(page.getByRole("button", { name: "Evaluate" })).toBeVisible();
  });

  test("renders the page shell and loads an example", async ({ page }) => {
    await openPlayground(page);
    await expect(page.locator("h1")).toHaveText("MoonRules Playground");

    const exampleSelect = page.locator("#example");
    await expect(exampleSelect).toBeVisible();
    await expect(exampleSelect.locator("option")).not.toHaveCount(0);
  });

  test("Check button produces a diagnostic-free result for a valid rule", async ({
    page,
  }) => {
    await openPlayground(page);
    await page.locator("#check").click();
    const statusCard = page.locator("#status-card");
    await expect(statusCard).toContainText("CHECKED");
  });

  test("switches to coupon pass data and sees Pass decision", async ({
    page,
  }) => {
    await openPlayground(page);
    await page.locator("#variant").selectOption("pass");
    await page.locator("#evaluate").click();
    const statusCard = page.locator("#status-card");
    await expect(statusCard).toContainText("PASS");
  });

  test("selects each example from the dropdown successfully", async ({
    page,
  }) => {
    await openPlayground(page);
    const exampleSelect = page.locator("#example");
    const options = await exampleSelect.locator("option").all();
    for (const option of options) {
      const value = await option.getAttribute("value");
      if (!value) continue;
      await exampleSelect.selectOption(value);
      await page.locator("#evaluate").click();
      await expect(page.locator("#status-card")).not.toBeEmpty();
    }
  });

  test("Trace tabs switch visible panels", async ({ page }) => {
    await openPlayground(page);
    await page.locator("#evaluate").click();

    const diagnosticsTab = page.locator("#tab-diagnostics");
    await diagnosticsTab.click();
    await expect(diagnosticsTab).toHaveAttribute("aria-selected", "true");
    await expect(page.locator("#panel-diagnostics")).toBeVisible();

    const jsonTab = page.locator("#tab-json");
    await jsonTab.click();
    await expect(jsonTab).toHaveAttribute("aria-selected", "true");
    await expect(page.locator("#panel-json")).toBeVisible();

    const statsTab = page.locator("#tab-stats");
    await statsTab.click();
    await expect(statsTab).toHaveAttribute("aria-selected", "true");
    await expect(page.locator("#panel-stats")).toBeVisible();
  });

  test("Copy JSON button is enabled after auto-evaluate on load", async ({
    page,
  }) => {
    await openPlayground(page);
    const copyButton = page.locator("#copy-result");
    await expect(copyButton).toBeEnabled();
    await copyButton.click();
    // clipboard.writeText is not available in headless Playwright;
    // the app handles the rejection gracefully and keeps the button
    // label unchanged.
    await expect(copyButton).toBeEnabled();
  });

  test("Download button is enabled after auto-evaluate on load", async ({
    page,
  }) => {
    await openPlayground(page);
    const downloadButton = page.locator("#download-result");
    await expect(downloadButton).toBeEnabled();
    const [download] = await Promise.all([
      page.waitForEvent("download"),
      downloadButton.click(),
    ]);
    expect(download.suggestedFilename()).toBe("moonrules-report.json");
  });

  test("malformed rule JSON shows diagnostics on evaluate", async ({
    page,
  }) => {
    await openPlayground(page);
    await page.locator("#rule-editor").locator(".cm-content").click();
    await page.keyboard.press("ControlOrMeta+A");
    await page.keyboard.insertText('{"bad": "rule"}');
    await page.locator("#evaluate").click();
    const statusCard = page.locator("#status-card");
    await expect(statusCard).toContainText(/error|INPUT_ERROR/i);
    const diagnostics = page.locator("#panel-diagnostics");
    await expect(diagnostics).not.toContainText("No diagnostics.");
  });

  test("switching trace mode evaluates correctly", async ({ page }) => {
    await openPlayground(page);
    const traceModeSelect = page.locator("#trace-mode");

    await traceModeSelect.selectOption("summary");
    await page.locator("#evaluate").click();
    await expect(page.locator("#status-card")).not.toBeEmpty();

    await traceModeSelect.selectOption("off");
    await page.locator("#evaluate").click();
    await expect(page.locator("#status-card")).not.toBeEmpty();
  });
});
