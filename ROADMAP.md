# MoonRules Roadmap

## v0.1.0 — Core engine (published)

- JSONLogic-inspired rule DSL with 15 operators.
- Three-state deterministic evaluation (`Pass` / `Fail` / `Indeterminate`).
- Full explainable Trace with variable and literal snapshots.
- Pre-evaluation structural and arity checks.
- Execution budgets (depth, nodes, steps, Trace nodes).
- Native CLI with file input and human-readable output.
- Three runnable business examples.
- White-box, property, and golden Trace tests.
- CI, README, API docs, and mooncakes.io publication.

## v0.2.0 — Playground and output modes (current)

- Deterministic `Summary` and `Off` Trace modes.
- Stable diagnostic JSON serialization.
- CLI JSON output, stdin support, `--help`, `--version`, fixed exit codes.
- MoonBit Web Adapter with a string/JSON boundary.
- Static local-only Playground (Vite + TypeScript + CodeMirror 6).
- Three built-in examples with pass/fail data variants.
- Browser smoke tests (Playwright) and reproducible benchmarks.
- Architecture document, technical report, and hackathon submission materials.

## v0.3 candidate

- Schema-aware variable type environment for richer pre-evaluation diagnostics.
- Expanded operator set (e.g., date comparisons, basic arithmetic predicates).
- Playground usability improvements (keyboard shortcuts, dark mode, shareable URLs via hash fragments).

## Explicit non-goals

These are out of scope for the foreseeable future. They may be reconsidered only through a separate design process:

- Full JSONLogic compatibility.
- Array-index data paths (`items[0].price`).
- User-defined operators or functions.
- Loops, recursion, or arbitrary code execution.
- Server, database, accounts, cloud save, or native desktop GUI.
- Monaco or full online IDE experience.
