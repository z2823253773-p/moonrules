# MoonRules Current Toolchain Maintenance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore MoonRules v0.2's complete validation matrix on the MoonBit current release available on 2026-11-11 without changing product behavior.

**Architecture:** Apply a mechanical language-format migration, update the two native-side-effect dependencies that resolve the reproduced linker failure, and preserve public API coverage by making black-box test package references explicit. Then update CI/manual verification documentation and run the full supported matrix with the isolated official toolchain.

**Tech Stack:** MoonBit `moon 0.1.20261104`, `moonc 0.10.20`, native and wasm-gc targets, Bash CLI smoke tests, Node.js 24, Vitest, Playwright, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-11-current-toolchain-maintenance-design.md`

## Global Constraints

- Preserve MoonRules v0.2 DSL, public API, decisions, budgets, Trace semantics, CLI exit codes, and Playground behavior.
- Keep the reusable engine free of filesystem, network, environment, and process APIs.
- Keep black-box root tests as consumer-facing public API tests.
- Validate with the isolated official latest toolchain: `moon 0.1.20261104`, `moonc 0.10.20`, `moonrun 0.1.20261104`.
- Do not publish, release, deploy, merge, or push as part of local implementation.

## Review Focus

- Native CLI test/link behavior on macOS arm64 with the default current native backend.
- Black-box tests must still exercise only public `@moonrules` symbols after qualification.
- Dependency upgrades must not alter CLI filesystem/stdin behavior or JSON output.
- wasm-gc and JS Playground adapter builds must remain supported after the syntax migration.
- README verification claims must distinguish local evidence from remote CI evidence.

---

### Task 1: Migrate syntax and native dependencies

**Files:**
- Modify: `moon.mod`
- Modify: MoonBit sources selected by `moon fmt`
- Modify: `pkg.generated.mbti`
- Modify: `cmd/playground/pkg.generated.mbti`
- Modify: `cmd/main/moon.pkg`
- Modify: `.ai/TASK_STATE.md`

**Interfaces:**
- Consumes: Existing v0.2 behavior and test suite.
- Produces: Current-syntax sources and dependency versions compatible with the current native backend.

- [ ] **Step 1: Preserve the reproduced red gates**

Run with the isolated current toolchain: `moon fmt --check`, `moon check --deny-warn`, and `moon test cmd/main/main_wbtest.mbt --target native`.

Expected: format and strict check fail on old syntax; native CLI test fails with undefined `_moonbit_get_cli_args` before dependency upgrades.

- [ ] **Step 2: Upgrade only the dependencies implicated by the native linker failure**

Set `moonbitlang/async@0.22.9` and `moonbitlang/x@0.5.7` in `moon.mod`.

- [ ] **Step 3: Apply the official formatter migration**

Run: `moon fmt`

Expected: old derive/parameter/type formatting is mechanically migrated.

- [ ] **Step 4: Remove imports reported unused by the current compiler**

Remove only `moonbitlang/async/io` and `moonbitlang/core/json` from `cmd/main/moon.pkg` if the post-upgrade compiler still reports them unused.

- [ ] **Step 5: Verify the focused linker regression and syntax gates**

Run: `moon fmt --check` and `moon test cmd/main/main_wbtest.mbt --target native`.

Expected: formatter is clean and all 5 CLI white-box tests pass under the default current native backend.

- [ ] **Step 6: Update task state and commit**

Record the current toolchain, root cause, dependency versions, and focused verification in `.ai/TASK_STATE.md`.

Commit: `fix: update MoonRules for current MoonBit toolchain`

### Task 2: Preserve warning-free public API tests

**Files:**
- Modify: `*_test.mbt` in the root package
- Modify: `.ai/TASK_STATE.md`

**Interfaces:**
- Consumes: Current-syntax production APIs from Task 1.
- Produces: Black-box tests that explicitly reference the public package as `@moonrules` and pass `--deny-warn`.

- [ ] **Step 1: Run the strict gate and capture remaining warnings**

Run: `moon check --deny-warn`

Expected: fail only on `test_unqualified_package` or any remaining specifically reported warning.

- [ ] **Step 2: Qualify black-box public API references**

Update root `*_test.mbt` files so MoonRules types, constructors, functions, and methods use `@moonrules`; keep standard-library aliases such as `@json`, `@test`, and `@quickcheck` unchanged.

- [ ] **Step 3: Verify strict native and wasm-gc checks and tests**

Run: `moon check --deny-warn`, `moon test --target native`, and `moon test --target wasm-gc`.

Expected: 0 warnings/errors and all tests pass on both supported targets.

- [ ] **Step 4: Update task state and commit**

Record counts and commands in `.ai/TASK_STATE.md`.

Commit: `test: make MoonRules public API tests explicit`

### Task 3: Refresh CI entry points, documentation, and full evidence

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `README.md`
- Modify: `README.en.md`
- Modify: `README.mbt.md`
- Modify: `.ai/TASK_STATE.md`

**Interfaces:**
- Consumes: Warning-free current-toolchain project from Tasks 1 and 2.
- Produces: A manually triggerable latest-toolchain CI workflow and documented local compatibility evidence.

- [ ] **Step 1: Add a manual CI trigger without weakening existing gates**

Add `workflow_dispatch` alongside the existing `push` and `pull_request` triggers. Keep installation from the official latest installer and the native/wasm-gc/CLI/Playground matrix intact.

- [ ] **Step 2: Document the supported targets and actual maintenance verification**

Add a concise compatibility section to all README variants with the 2026-11-11 toolchain versions, native/wasm-gc scope, Node.js requirement, and exact verification entry points. State that the recorded result is local until a remote run exists.

- [ ] **Step 3: Run the full MoonBit and CLI matrix**

Run: `moon fmt --check`, `moon check --deny-warn`, native test/build, wasm-gc test/build, `scripts/test_cli.sh`, and the coupon CLI smoke command.

Expected: every command exits 0.

- [ ] **Step 4: Run the clean Playground matrix**

Run: `cd playground && npm ci && npm test && npm run build && npm run test:e2e`.

Expected: Vitest, TypeScript/Vite build, and all Playwright Chromium tests pass.

- [ ] **Step 5: Verify repository hygiene**

Run: `git diff --check`, inspect `git status --short`, and confirm generated/build artifacts remain ignored.

- [ ] **Step 6: Update task state and commit**

Record exact version output, command results, test counts, and the local-versus-remote evidence boundary in `.ai/TASK_STATE.md`.

Commit: `ci: record current MoonBit compatibility`
