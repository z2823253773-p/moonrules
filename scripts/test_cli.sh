#!/usr/bin/env bash
set -euo pipefail

pass_json="$(moon run --target native cmd/main eval \
  examples/coupon.rule.json \
  --data examples/coupon.data.pass.json \
  --json)"
node -e 'const x=JSON.parse(process.argv[1]); if(x.report.decision.status!=="pass") process.exit(1)' "$pass_json"

set +e
fail_json="$(moon run --target native cmd/main eval \
  examples/coupon.rule.json \
  --data examples/coupon.data.json \
  --json)"
fail_code=$?
set -e
test "$fail_code" -eq 1
node -e 'const x=JSON.parse(process.argv[1]); if(x.report.decision.status!=="fail") process.exit(1)' "$fail_json"

stdin_json="$(moon run --target native cmd/main check - --json \
  < examples/coupon.rule.json)"
node -e 'const x=JSON.parse(process.argv[1]); if(x.ok!==true) process.exit(1)' "$stdin_json"

set +e
cli_tmp_dir="$(mktemp -d /tmp/moonrules-cli.XXXXXX)"
moon run --target native cmd/main eval - --data - \
  < examples/coupon.rule.json >"$cli_tmp_dir/dual-stdin.out" 2>"$cli_tmp_dir/dual-stdin.err"
dual_code=$?
set -e
test "$dual_code" -eq 2
grep -q "cannot both use stdin" "$cli_tmp_dir/dual-stdin.err"

moon run --target native cmd/main -- --version | grep -q "moonrules 0.2.0"
moon run --target native cmd/main -- --help | grep -q "moonrules check"
