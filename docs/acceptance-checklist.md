# MoonRules v0.2.0 Acceptance Checklist

Every item from the design document (section 16: 完成定义) is listed with its current status.

## Core engine

- [x] `moon fmt --check` passes
- [x] `moon check --deny-warn` passes
- [x] `moon test --target native` passes (71 tests)
- [x] `moon test --target wasm-gc` passes (66 tests)
- [x] `moon build --target native` passes
- [x] `moon build --target wasm-gc` passes
- [x] Existing target regression tests pass
- [x] Full/Summary/Off Decision consistency has automated tests
- [x] DSL, three-state semantics, budgets, and Full Trace remain compatible with v0.1

## CLI

- [x] File input works
- [x] Stdin (`-`) works for rule and data
- [x] Dual stdin (`eval - --data -`) rejected with exit code 2
- [x] `--json` output is machine-readable with stable fields
- [x] `--help` and `--version` work
- [x] Exit codes: 0 (Pass/check OK), 1 (Fail), 2 (error/Indeterminate)
- [x] CLI black-box tests pass (`scripts/test_cli.sh`)

## Web Adapter

- [x] Adapter exports `check_json` and `evaluate_json` with stable string/JSON contract
- [x] Response envelope: `{ ok, kind, report, diagnostics }`
- [x] Options parsing: `trace_mode`, budget fields
- [x] Invalid options return `input_error`
- [x] Selected backend: MoonBit JavaScript target (wasm-gc gate did not pass with moonc 0.10.4)
- [x] `scripts/build_playground_engine.sh` copies the JS artifact

## Playground

- [x] TypeScript type-checking passes (`tsc --noEmit`)
- [x] Production build succeeds (`vite build`)
- [x] 3 built-in examples with pass/fail data
- [x] Check and Evaluate buttons work
- [x] Status card shows PASS / FAIL / INDETERMINATE / CHECKED / ERROR
- [x] Four result tabs: Trace, Diagnostics, JSON, Stats
- [x] Copy JSON and Download JSON actions
- [x] Full/Summary/Off mode selector
- [x] Format JSON button
- [x] Keyboard shortcut: Cmd/Ctrl+Enter
- [x] Responsive layout (desktop dual-column, mobile stacked)
- [x] Privacy notice displayed
- [x] 11 Playwright browser smoke tests pass
- [x] 6 Vitest unit tests pass

## GitHub Pages

- [ ] GitHub Pages publicly accessible
- [ ] Three examples demonstrate pass, fail, and error paths
- [x] Pages workflow exists (`.github/workflows/pages.yml`)
- [x] Deploy job enabled after explicit user confirmation

## Repository maturity

- [x] GitHub Issue templates (YAML forms for bug report and feature request)
- [x] GitHub PR template
- [x] `CONTRIBUTING.md`
- [x] `SECURITY.md`
- [x] `ROADMAP.md`
- [x] `THIRD_PARTY_NOTICES.md` with verified licenses
- [x] `docs/ARCHITECTURE.md`
- [x] `docs/technical-report.md`
- [x] `docs/BENCHMARKS.md`
- [x] CI workflow with core + playground jobs
- [x] Repository description and topics set

## Documentation

- [x] Chinese README (`README.md`) with v0.2 content
- [x] English README (`README.en.md`)
- [x] Mooncakes README (`README.mbt.md`)
- [x] `docs/API.md` updated for v0.2
- [x] `docs/ERRORS.md` updated for v0.2
- [x] `docs/DSL.md`
- [x] `docs/demo-script.md`
- [x] `docs/acceptance-checklist.md` (this file)

## Release (pending user confirmation)

- [x] `moon.mod` version bumped to `0.2.0`
- [x] `CHANGELOG.md` updated with v0.2.0 entries
- [x] `moon package --list` audit clean (no credentials, `.env`, `node_modules`, build artifacts; local sample PDF excluded)
- [ ] Consumer install test: `moon add z2823253773-p/moonrules@0.2.0 && moon check`
- [ ] `moon publish` successful
- [ ] GitHub Release `v0.2.0` created with release notes
- [ ] Pages URL verified
- [ ] Mooncakes docs page verified
- [ ] All README links verified

## Submission materials

- [x] Application source (`docs/submission/moonrules-application.md`) updated for v0.2
- [x] One-page PDF built and visually verified
- [x] GIF or screenshot walkthrough captured
- [ ] All claims in application match measured results
