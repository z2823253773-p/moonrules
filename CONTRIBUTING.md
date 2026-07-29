# Contributing to MoonRules

MoonRules is a MoonBit-native explainable JSON business rule engine. Contributions are welcome within the project's [scope and non-goals](ROADMAP.md).

## Environment setup

1. Install the MoonBit toolchain:

   ```bash
   curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
   ```

2. Clone and verify:

   ```bash
   git clone https://github.com/z2823253773-p/moonrules
   cd moonrules
   moon update
   moon check --deny-warn
   moon test --target native
   ```

3. For Playground work, also install Node.js 24+ and run:

   ```bash
   scripts/build_playground_engine.sh
   cd playground && npm ci
   ```

## Development loop

MoonRules follows test-driven development:

1. Write a focused failing test.
2. Run it and observe the expected failure.
3. Implement the smallest change that makes the test pass.
4. Run the focused test, then the full regression suite.
5. Format and commit.

## Commands

```bash
moon fmt                              # format MoonBit sources
moon fmt --check                      # verify formatting
moon check --deny-warn                # type-check with no warnings
moon test --target native             # run native tests
moon test --target wasm-gc            # run wasm-gc tests
moon build --target native            # build the core library
scripts/build_playground_engine.sh    # build the web adapter
cd playground && npm test             # run Playground unit tests
cd playground && npm run test:e2e     # run browser smoke tests
cd playground && npm run build        # build the Playground for production
```

## Module boundaries

The reusable rule engine lives in the root package and must never depend on filesystem, network, environment, or process APIs. Native side effects belong only in `cmd/main`; browser DOM and clipboard side effects belong only in `playground/`.

| Module | Responsibility |
|---|---|
| `model.mbt` | Public types: AST, diagnostics, decisions, Trace, budgets |
| `parser.mbt` | JSON to `RuleDocument` / `Expr` |
| `checker.mbt` | Pre-evaluation structural and arity checks |
| `operators.mbt` | Pure comparison, collection, and string operators |
| `evaluator.mbt` | Three-state evaluation, budgets, and Trace construction |
| `trace_mode.mbt` | Deterministic Full/Summary/Off Trace compression |
| `render.mbt` | Text and JSON report output |
| `moonrules.mbt` | Public façade: `parse`, `check`, `evaluate`, `evaluate_json` |
| `cmd/main/` | Native CLI (argparse, file I/O, exit codes) |
| `cmd/playground/` | Web Adapter (string/JSON boundary for browsers) |
| `playground/` | Static Vite + TypeScript Playground UI |

## Commit style

- Use small, focused commits: one logical change per commit.
- Prefix with `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`, or `ci:`.
- Update `.ai/TASK_STATE.md` after every task.

## Pull requests

- Use the PR template (`.github/pull_request_template.md`).
- Include the verification checklist, terminal output or screenshots.
- Link the relevant issue and milestone.
- Keep PRs scoped to one phase: core → CLI → Playground → evidence/release.

## Scope and non-goals

MoonRules is a JSONLogic-inspired rule engine, not a full JSONLogic implementation. Do not add:

- Full JSONLogic compatibility, array-index data paths, or custom operators.
- Loops, user-defined functions, network access, or arbitrary code execution.
- A server, database, accounts, cloud save, or native desktop GUI.

The approved v0.2 static local-only Web Playground is the only GUI exception.

## Questions?

Open a [discussion](https://github.com/z2823253773-p/moonrules/discussions) or check the [technical report](docs/technical-report.md).
