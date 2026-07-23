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
- Manifest format: `moon.mod`
- Compatible dependencies: `moonbitlang/async@0.20.2`, `moonbitlang/x@0.4.46`
- Black-box tests construct public enum values with qualified names such as `Expr::Operation` and `Operator::And`.

## Verification commands

`moon fmt --check && moon check && moon test && moon build --target native`

## Next action

Re-authenticate GitHub CLI, create and push the public repository, verify CI, then obtain explicit confirmation before `moon publish --frozen`.

## External blockers

- `gh auth status` reports an invalid token for `z2823253773-p`; run `gh auth login -h github.com`.
- GitHub, CI, and mooncakes.io URLs remain intentionally unfilled until confirmed public.

## Release artifacts

- Package: `_build/publish/z2823253773-p-moonrules-0.1.0.zip` (51 files, about 62 KB).
- Application source: `docs/submission/moonrules-application.md`.
- Visually verified one-page PDF: `output/pdf/moonrules-application.pdf`.
