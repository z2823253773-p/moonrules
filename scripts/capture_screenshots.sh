#!/usr/bin/env bash
# Capture Playground screenshots for submission materials.
# Prerequisites: npm run build must have completed in playground/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
ASSETS="$ROOT/docs/assets"
PLAYGROUND="$ROOT/playground"
mkdir -p "$ASSETS"

cd "$PLAYGROUND"

# Start preview server in background
npx vite preview --host 127.0.0.1 --strictPort --port 4173 &
PREVIEW_PID=$!
trap "kill $PREVIEW_PID 2>/dev/null || true" EXIT

# Wait for server
for _ in $(seq 1 20); do
  if curl -s http://127.0.0.1:4173 > /dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

echo "Capturing screenshots..."

npx playwright screenshot \
  --browser chromium \
  --viewport-size 1280,800 \
  "http://127.0.0.1:4173" \
  "$ASSETS/moonrules-playground-fail.png"

echo "Screenshots saved to $ASSETS/"
echo ""
echo "To capture specific states manually:"
echo "  1. Open http://127.0.0.1:4173"
echo "  2. Select coupon, fail data, click Evaluate → screenshot for FAIL state"
echo "  3. Switch data to pass, click Evaluate → screenshot for PASS state"
echo "  4. Switch trace mode to Summary → screenshot"
echo "  5. Paste a malformed rule, click Evaluate → screenshot for diagnostics"
echo ""
echo "For a GIF, use a screen recorder or:"
echo "  ffmpeg -i screen-recording.mov -vf 'fps=15,scale=1280:-1' -loop 0 docs/assets/moonrules-demo.gif"
