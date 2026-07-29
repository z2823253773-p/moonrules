# Changelog

All notable changes to MoonRules are documented here.

## 0.2.0 — 2026-07-29

Release candidate. Playground, Trace output modes, and scriptable CLI.

### Added

- Deterministic `Summary` and `Off` Trace output modes with automated invariant tests.
- `diagnostics_to_json(Array[Diagnostic]) -> Json` stable serialization.
- CLI `--json` machine-readable output, stdin (`-`) support, `--help`, and `--version`.
- MoonBit Web Adapter (`cmd/playground`) with stable string/JSON response envelope and budget-aware options parsing.
- Static local-only Playground (Vite + TypeScript + CodeMirror 6) with three built-in examples, dual JSON editors, Check/Evaluate flow, four result tabs, Trace mode selector, copy JSON, and download JSON.
- Playwright browser smoke tests (11 tests) and Vitest unit tests (6 tests).
- Reproducible MoonBit benchmarks for parse, check, evaluate, and render (Full/Summary/Off) at 1/10/100/1000 node scales.
- `docs/ARCHITECTURE.md`, `docs/technical-report.md`, `docs/BENCHMARKS.md`, `docs/demo-script.md`, `docs/acceptance-checklist.md`.
- `CONTRIBUTING.md`, `SECURITY.md`, `ROADMAP.md`, `THIRD_PARTY_NOTICES.md`.
- GitHub Issue forms (YAML) and PR template.
- Pages workflow (`.github/workflows/pages.yml`, deploy commented out pending user confirmation).

### Changed

- Playground CI job split from core; `cmd/playground` limited to wasm-gc and js targets.
- `AGENTS.md` updated to document the approved static Playground exception.
- V1 `UnsupportedTraceMode` rejection replaced by Full/Summary/Off implementation; the variant retained for compatibility but not produced in normal v0.2 paths.

### Compatibility

V1 DSL, three-state decisions, budgets, and Full Trace remain compatible. All v0.1 tests pass unchanged.

## 0.1.0 — 2026-07-23

Initial hackathon release.

### Added

- JSONLogic-inspired JSON rule parsing with explicit object-literal wrapping.
- Preflight diagnostics for arity, data paths, literal types, static limits, and caller budgets.
- Explainable Trace nodes for every variable, literal, operation, error, and skipped branch.
- Deterministic three-state evaluation: `Pass`, `Fail`, and `Indeterminate`.
- Depth, rule-node, execution-step, Trace-node, and preview budgets.
- Fifteen V1 node/operator forms: `var`, `literal`, `and`, `or`, `not`, six comparisons, `in`, and three string operators.
- Strict recursive JSON equality without cross-type coercion.
- Native `check` and `eval` CLI commands with stable exit codes.
- Coupon, API-access, and membership examples with passing and failing data.
- Chinese and English README files plus DSL, API, and error references.
- Native and wasm-gc CI matrix with deterministic property tests.
