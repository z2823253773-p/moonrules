# MoonRules task state

## Current milestone

Task 16 is complete: implementation, public GitHub repository, green CI,
mooncakes.io publication, install smoke test, and final submission evidence.

## Locked decisions

- JSONLogic-inspired, not JSONLogic-compatible.
- Independent Trace nodes for variables and literals.
- Three-state evaluation with deterministic budgets.
- Native CLI is a thin wrapper around a portable core library.

## Verified environment

- Architecture: `arm64`
- `moon`: `0.1.20260713`
- `moonc`: `0.10.4`
- Manifest format: `moon.mod` plus package-level `moon.pkg` files; the verified
  toolchain does not generate `.json` manifest variants.
- Compatible dependencies: `moonbitlang/async@0.20.2`, `moonbitlang/x@0.4.46`
- QuickCheck is a bundled `moonbitlang/core` package imported only for tests; it
  is not installed separately with `moon add`.
- `moon ide doc` is unavailable, so MoonBit API shapes were locked through
  compiler-backed probes, `moon check --deny-warn`, and focused tests.
- Black-box tests construct public enum values with qualified names such as `Expr::Operation` and `Operator::And`.

## Verification commands

`moon fmt --check && moon check && moon test && moon build --target native`

## Next action

Submit the application and record the planned demo. No engineering or release
blocker remains.

## External status

- GitHub CLI is authenticated as `z2823253773-p`.
- Public repository: `https://github.com/z2823253773-p/moonrules`.
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
