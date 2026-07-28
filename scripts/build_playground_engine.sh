#!/usr/bin/env bash
set -euo pipefail

moon build cmd/playground --target js --release
artifact="$(find _build/js/release -path '*cmd/playground*' -type f -name '*.js' -print -quit)"
test -n "$artifact"
mkdir -p playground/src/generated
cp "$artifact" playground/src/generated/moonrules.js
