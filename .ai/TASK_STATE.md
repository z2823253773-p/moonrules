# MoonRules task state

## Current milestone

MoonRules v0.2 implementation is active on `codex/v0.2-playground`.
Task 9 status, Trace, diagnostics, JSON, stats, copy, and download passed.
Next: Task 10.
Task 8 and Task 9 playground changes remain uncommitted in this worktree.
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

Task 4 CLI configuration/output contract on `codex/v0.2-cli`:

- `moon test cmd/main/main_wbtest.mbt --target native`: expected TDD failure
  observed before implementation; new CLI config/output variants were missing.
- `moon fmt`: pass.
- `moon test cmd/main/main_wbtest.mbt --target native`: 5 total, 5 passed, 0
  failed.
- `moon check --target native --deny-warn`: pass.
- `moon fmt --check`: pass.

Task 5 CLI stdin, JSON execution, and black-box exit tests on
`codex/v0.2-cli`:

- `moon check cmd/main --target native --deny-warn`: pass; verified
  `@stdio.stdin.read_all().text()` for `-` source input.
- `scripts/test_cli.sh`: initial failure identified `moon run` option parsing
  for `--help`/`--version`; fixed with `--` argument separator.
- `scripts/test_cli.sh`: pass; JSON pass/fail parsed, Fail exited `1`, stdin
  check succeeded, dual stdin exited `2`, help/version matched.
- `moon fmt`: pass.
- `moon fmt --check`: pass.
- `moon check --deny-warn`: pass.
- `moon test --target native`: 71 total, 71 passed, 0 failed.
- `moon test --target wasm-gc`: 66 total, 66 passed, 0 failed.
- `moon build --target native`: pass.

Task 6 Web Adapter backend gate on `codex/v0.2-playground`:

- `git status --short --branch`: clean branch confirmed at start.
- `moon test cmd/playground --target wasm-gc`: initial failure observed because
  `#export_name` is rejected under wbtest; package-level `exports` in
  `cmd/playground/moon.pkg` is sufficient and tests pass after removing the
  attribute.
- `moon build cmd/playground --target wasm-gc --release`: pass; wasm artifact
  `_build/wasm-gc/release/build/cmd/playground/playground.wasm`.
- `moon build cmd/playground --target js --release`: pass; JS artifact
  `_build/js/release/build/cmd/playground/playground.js`.
- wasm-gc gate: Node could instantiate
  `playground/public/engine/moonrules.wasm` and exports included `check_json`
  and `evaluate_json`, but direct JS string calls failed with
  `TypeError: type incompatibility when transforming from/to JS`.
- `PLAYGROUND_BACKEND=js`: selected planned JS fallback. JS ESM import smoke
  passed; `check_json` returned parseable `{ "ok": true, "kind": "check" }`,
  and `evaluate_json` with `trace_mode: "off"` returned `evaluation fail 0`.
- `scripts/build_playground_engine.sh`: pass; copies the selected JS artifact
  to `playground/src/generated/moonrules.js`.
- `moon fmt`: pass.
- `moon fmt --check`: pass.
- `moon check --deny-warn`: pass.
- `moon test cmd/playground --target wasm-gc`: 5 total, 5 passed, 0 failed.

Task 7 Playground project shell and engine client on `codex/v0.2-playground`:

- `npm init -y`: pass.
- `npm install @codemirror/lang-json @codemirror/state @codemirror/view
  codemirror`: pass; package-lock generated.
- `npm install --save-dev vite typescript vitest jsdom @types/node`: pass.
- `scripts/build_playground_engine.sh`: pass; generated selected JS engine for
  local build/test and left it ignored by git.
- `npm test`: 1 test file, 2 tests passed.
- `npm run build`: initial failure found TypeScript 7 CSS side-effect import
  declaration requirement; fixed with `src/vite-env.d.ts`.
- `npm run build`: pass; Vite built `playground/dist/index.html`.

Task 8 examples, dual editors, and Check/Evaluate flow on
`codex/v0.2-playground`:

- Synced three browser examples with pass/fail data under
  `playground/public/examples/`.
- `npm test`: 2 test files, 3 tests passed.
- `npm run build`: pass.
- Default coupon/fail flow verified through the same generated engine module as
  the page; `evaluate_json` returned `decision.status = "fail"`.

Task 9 status, Trace, diagnostics, JSON, stats, copy, and download on
`codex/v0.2-playground`:

- `npm test`: expected TDD failure observed before implementation because
  `playground/tests/renderers.test.ts` could not resolve `../src/renderers`.
- Added DOM-safe result renderers that create elements with `document.createElement`
  and assign untrusted adapter text with `textContent`.
- Added result status card, Trace/Diagnostics/JSON/Stats tabs, copy JSON, and
  `moonrules-report.json` download actions.
- Addressed Task 8 review follow-ups while touching the same area: manifest
  files are checked and pass/fail examples are evaluated in tests; selected
  example loading now uses a monotonically increasing token; CodeMirror editable
  content receives an aria label through `EditorView.contentAttributes`; example
  URL bases work with or without a trailing slash; unused `.notice` CSS was
  removed.
- `playground/package.json` now runs `scripts/build_playground_engine.sh` before
  `npm test` and `npm run build`, so clean checkouts regenerate the ignored
  engine artifact automatically.
- `scripts/build_playground_engine.sh`: pass.
- `cd playground && npm test`: pretest regenerated the engine artifact; 3 test
  files, 6 tests passed.
- `cd playground && npm run build`: prebuild regenerated the engine artifact;
  pass.
- Generated-engine smoke: coupon fail returned `decision.status = "fail"` for
  Full, Summary, and Off; malformed rule returned `ok=false`,
  `kind=input_error`, and one diagnostic.
- `moon fmt --check`: pass.
- `moon check`: pass.
- `moon test`: 71 total, 71 passed, 0 failed.
- `moon build --target native`: pass.

## Next action

Task 10.

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
- Core output phase PR:
  - PR: `https://github.com/z2823253773-p/moonrules/pull/5`
  - Merge commit: `07f86b3819e22844f6eeb12455db1ca604b9cc76`
  - CI: `https://github.com/z2823253773-p/moonrules/actions/runs/30321323443/job/90157635140`
- CLI phase PR:
  - PR: `https://github.com/z2823253773-p/moonrules/pull/6`
  - Merge commit: `508aabf8dff93b3f6b0b764499899cdff82a6903`
  - CI: `https://github.com/z2823253773-p/moonrules/actions/runs/30322549792/job/90161256328`
  - Next branch: `codex/v0.2-playground`
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
