#!/usr/bin/env bash
# Capture MoonRules Playground and CLI evidence for submission materials.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS="$ROOT/docs/assets"
PLAYGROUND="$ROOT/playground"
mkdir -p "$ASSETS"

echo "Building Playground production assets..."
cd "$PLAYGROUND"
npm run build

echo "Starting local preview server..."
npx vite preview --host 127.0.0.1 --strictPort --port 4173 &
PREVIEW_PID=$!
trap "kill $PREVIEW_PID 2>/dev/null || true" EXIT

for _ in $(seq 1 40); do
  if curl -fsS http://127.0.0.1:4173 > /dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

echo "Capturing Playground screenshots..."
MOONRULES_ASSETS="$ASSETS" node --input-type=module <<'NODE'
import { chromium } from "playwright";
import { join } from "node:path";

const assets = process.env.MOONRULES_ASSETS;
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });

async function openPlayground() {
  await page.goto("http://127.0.0.1:4173");
  await page.getByRole("heading", { name: "MoonRules Playground" }).waitFor();
  await page.locator("#copy-result").waitFor({ state: "visible" });
}

async function screenshot(name) {
  await page.screenshot({ path: join(assets, name), fullPage: true });
}

await openPlayground();
await page.getByRole("button", { name: "Evaluate" }).click();
await page.locator(".status-card").filter({ hasText: "FAIL" }).waitFor();
await screenshot("moonrules-playground-fail.png");

await page.locator("#variant").selectOption("pass");
await page.getByRole("button", { name: "Evaluate" }).click();
await page.locator(".status-card").filter({ hasText: "PASS" }).waitFor();
await screenshot("moonrules-playground-pass.png");

await page.locator("#variant").selectOption("fail");
await page.locator("#trace-mode").selectOption("summary");
await page.getByRole("button", { name: "Evaluate" }).click();
await page.locator(".status-card").filter({ hasText: "FAIL" }).waitFor();
await screenshot("moonrules-playground-summary.png");

await page.locator("#rule-editor .cm-content").click();
await page.keyboard.press("ControlOrMeta+A");
await page.keyboard.insertText('{"id":"broken","description":"bad arity","condition":{">":[{"var":"user.age"}]}}');
await page.getByRole("button", { name: "Check" }).click();
await page.locator("#tab-diagnostics").click();
await page.locator("#panel-diagnostics").filter({ hasText: "E_ARITY" }).waitFor();
await screenshot("moonrules-playground-diagnostic.png");

await browser.close();
NODE

cd "$ROOT"
echo "Capturing CLI JSON output..."
set +e
CLI_OUTPUT="$(
  moon run --target native cmd/main eval examples/coupon.rule.json \
    --data examples/coupon.data.json \
    --json 2>&1
)"
CLI_STATUS=$?
set -e
CLI_OUTPUT="$CLI_OUTPUT"$'\n'"exit code: $CLI_STATUS"
MOONRULES_ASSETS="$ASSETS" MOONRULES_CLI_OUTPUT="$CLI_OUTPUT" python3 - <<'PY'
import os
import textwrap
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

assets = Path(os.environ["MOONRULES_ASSETS"])
text = "$ moon run --target native cmd/main eval examples/coupon.rule.json --data examples/coupon.data.json --json\n\n"
text += os.environ["MOONRULES_CLI_OUTPUT"]
wrapped = []
for line in text.splitlines():
    wrapped.extend(textwrap.wrap(line, width=108) or [""])

font = ImageFont.load_default()
line_height = 16
padding = 24
width = 1280
height = padding * 2 + line_height * len(wrapped)
image = Image.new("RGB", (width, height), "#111827")
draw = ImageDraw.Draw(image)
for index, line in enumerate(wrapped):
    color = "#d1fae5" if index == 0 else "#e5e7eb"
    draw.text((padding, padding + index * line_height), line, fill=color, font=font)
image.save(assets / "moonrules-cli-json.png")

frames = []
for name in [
    "moonrules-playground-fail.png",
    "moonrules-playground-pass.png",
    "moonrules-playground-summary.png",
    "moonrules-playground-diagnostic.png",
]:
    frame = Image.open(assets / name).convert("RGB")
    ratio = 960 / frame.width
    frame = frame.resize((960, int(frame.height * ratio)))
    frames.append(frame)

frames[0].save(
    assets / "moonrules-playground.gif",
    save_all=True,
    append_images=frames[1:],
    duration=1400,
    loop=0,
    optimize=True,
)
PY

echo "Captured assets:"
find "$ASSETS" -maxdepth 1 -type f -print | sort
