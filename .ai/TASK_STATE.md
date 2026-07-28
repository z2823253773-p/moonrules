# MoonRules task state

## Current milestone

MoonRules v0.2 implementation is active on `codex/v0.2-core`.
Task 3 diagnostic JSON serialization passed. Next: Task 3 core phase PR,
CI, merge, then Task 4 CLI configuration/output contract.
No public v0.2 release action is authorized yet.

## Locked decisions

- JSONLogic-inspired, not JSONLogic-compatible.
- Independent Trace nodes for variables and literals.
- Three-state evaluation with deterministic budgets.
- Native CLI is a thin wrapper around a portable core library.
- v0.2 preserves the V1 DSL and evaluator semantics.
- v0.2 implements Full, Summary, and Off as output-shape modes; all modes first
  perform the same full evaluation.
- v0.2 adds a static local-only Playground through a string/JSON Web Adapter.
- The Web Adapter has a two-hour wasm-gc gate and may fall back to the MoonBit
  JavaScript target without changing its TypeScript-facing contract.
- v0.2 does not add a server, database, native desktop GUI, full JSONLogic,
  array-index paths, custom operators, or schema-aware type environments.

## Verified environment

- Architecture: `arm64`
- `moon`: `0.1.20260713`
- `moonc`: `0.10.4`
- `moonrun`: `0.1.20260713`
- Node.js: `v24.15.0`
- npm: `11.12.1`
- Manifest format: `moon.mod` plus package-level `moon.pkg` files; the verified
  toolchain does not generate `.json` manifest variants.
- Compatible dependencies: `moonbitlang/async@0.20.2`, `moonbitlang/x@0.4.46`
- QuickCheck is a bundled `moonbitlang/core` package imported only for tests; it
  is not installed separately with `moon add`.
- `moon ide doc` is unavailable, so MoonBit API shapes were locked through
  compiler-backed probes, `moon check --deny-warn`, and focused tests.
- Black-box tests construct public enum values with qualified names such as `Expr::Operation` and `Operator::And`.

## Verification commands

Task 1 baseline on `codex/v0.2-core`:

- `moon version --all`: `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf`,
  `moonrun 0.1.20260713`; feature flags `rr_moon_mod`, `rr_moon_pkg`.
- `node --version`: `v24.15.0`.
- `npm --version`: `11.12.1`.
- `gh auth status`: local `gh` account `z2823253773-p` is active, but the
  stored token is invalid; use the connected GitHub integration or
  re-authenticate `gh` before CLI GitHub writes.
- `moon fmt --check`: pass.
- `moon check --deny-warn`: pass.
- `moon test --target native`: 63 total, 63 passed, 0 failed.
- `moon test --target wasm-gc`: 60 total, 60 passed, 0 failed.
- `moon build --target native`: pass.
- `moon build --target wasm-gc`: pass.

Task 2 TraceMode compression on `codex/v0.2-core`:

- `moon test evaluator_test.mbt --target native`: expected TDD failure observed
  before implementation; 3 new mode tests failed with
  `UnsupportedTraceMode("Summary")` / `UnsupportedTraceMode("Off")`.
- `moon fmt`: pass.
- `moon test evaluator_test.mbt --target native`: 21 total, 21 passed, 0 failed.
- `moon test properties_test.mbt --target native`: 17 total, 17 passed, 0 failed.
- `moon fmt --check`: pass.
- `moon check --deny-warn`: pass.
- `moon test --target native`: 66 total, 66 passed, 0 failed.
- `moon test --target wasm-gc`: 63 total, 63 passed, 0 failed.

Task 3 diagnostic JSON serialization on `codex/v0.2-core`:

- `moon test render_test.mbt --target native`: expected TDD failure observed on
  the Task 2 baseline in a temporary worktree; `diagnostics_to_json` was
  unbound.
- `moon test render_test.mbt --target native`: 6 total, 6 passed, 0 failed.
- `moon test properties_test.mbt --target native`: 18 total, 18 passed, 0 failed.
- `moon fmt`: pass.
- `moon fmt --check`: pass.
- `moon check --deny-warn`: pass.
- `moon test --target native`: 69 total, 69 passed, 0 failed.
- `moon test --target wasm-gc`: 66 total, 66 passed, 0 failed.

## Next action

Task 3 core phase PR, CI, merge, then Task 4 CLI configuration/output contract.

## External status

- GitHub CLI has an active `z2823253773-p` account, but `gh auth status`
  reported the stored token as invalid on 2026-07-28.
- Public repository: `https://github.com/z2823253773-p/moonrules`.
- GitHub planning records for v0.2.0:
  - Milestone: `https://github.com/z2823253773-p/moonrules/milestone/1`
    (`v0.2.0`, due `2026-07-31T15:59:59Z`).
  - `Implement Summary and Off Trace modes`:
    `https://github.com/z2823253773-p/moonrules/issues/1`
  - `Add CLI JSON and stdin support`:
    `https://github.com/z2823253773-p/moonrules/issues/4`
  - `Build static MoonRules Playground`:
    `https://github.com/z2823253773-p/moonrules/issues/2`
  - `Prepare v0.2 evidence and release`:
    `https://github.com/z2823253773-p/moonrules/issues/3`
- Initial CI run `29984299189` failed before compilation because a fresh runner
  had not updated the MoonBit registry; the focused fix adds `moon update`.
- Green CI: `https://github.com/z2823253773-p/moonrules/actions/runs/29985024289`.
- Published package:
  `https://mooncakes.io/docs/z2823253773-p/moonrules`
  (`z2823253773-p/moonrules@0.1.0`).
- `moon publish --frozen` could not install pinned dependencies in its isolated
  verification directory; publishing the identical package with `moon publish`
  completed successfully with server status `200 OK`.
- A clean temporary consumer project successfully ran
  `moon add z2823253773-p/moonrules@0.1.0` followed by `moon check`.

## Release artifacts

- Package: `_build/publish/z2823253773-p-moonrules-0.1.0.zip` (58 archive
  entries, 190212 bytes, SHA-256
  `b5cf313ca8c7a58132e22de33a1086042b74d9d080af421d1c70806f41d60175`).
- Application source: `docs/submission/moonrules-application.md`.
- Visually verified final one-page PDF:
  `output/pdf/moonrules-application.pdf`.
