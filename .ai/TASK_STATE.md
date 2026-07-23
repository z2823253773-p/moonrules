# MoonRules task state

## Current milestone

Task 2: project metadata and governance.

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

## Verification commands

`moon fmt --check && moon check && moon test && moon build --target native`

## Next action

Create the public model and default execution budget in Task 3.
