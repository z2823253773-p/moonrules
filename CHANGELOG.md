# Changelog

All notable changes to MoonRules are documented here.

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
