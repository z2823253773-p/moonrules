# MoonRules task state

## Current milestone

Task 16 local release package and one-page application are ready.

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

Push the focused CI registry fix, verify the replacement GitHub Actions run,
then add confirmed public links to the application and obtain explicit
confirmation before `moon publish --frozen`.

## External blockers

- GitHub CLI is authenticated as `z2823253773-p`.
- Public repository: `https://github.com/z2823253773-p/moonrules`.
- Initial CI run `29984299189` failed before compilation because a fresh runner
  had not updated the MoonBit registry; the focused fix adds `moon update`.
- The mooncakes.io URL remains intentionally unfilled until publication is
  explicitly confirmed.

## Release artifacts

- Package: `_build/publish/z2823253773-p-moonrules-0.1.0.zip` (51 files, about 62 KB).
- Application source: `docs/submission/moonrules-application.md`.
- Visually verified one-page PDF: `output/pdf/moonrules-application.pdf`.
