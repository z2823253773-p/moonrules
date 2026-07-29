# MoonRules Architecture

## Overview

MoonRules is a MoonBit-native explainable JSON business-rule engine. It parses a small JSONLogic-inspired DSL, checks rules before execution, evaluates with deterministic three-state semantics, and returns structured execution traces.

## Data flow

```text
JSON source ──► Parser ──► Checker ──► Evaluator ──► Full EvaluationReport
                 │            │             │
                 │            │             └── Three-state logic
                 │            │                 Short-circuit evaluation
                 │            │                 Execution budgets
                 │            │                 Full Trace construction
                 │            │
                 │            └── Structural checks
                 │                Operator existence
                 │                Arity validation
                 │                Data-path syntax
                 │                Budget ceiling enforcement
                 │
                 └── JSON → RuleDocument
                     JSON → Expr tree
                     Operator key mapping
                     Literal / Variable / Operation nodes

Full EvaluationReport ──► TraceMode compressor ──► Final report
                               │
                               ├── Full:   pass-through
                               ├── Summary: drop ordinary value leaves
                               └── Off:    single root node, no children

Final report ──► Renderer ──► Human-readable text tree
             │              ──► Structured JSON (report_to_json)
             │              ──► Diagnostic JSON (diagnostics_to_json)
             │
             ├──► Native CLI (cmd/main) ──► stdout/stderr + exit codes
             │
             └──► Web Adapter (cmd/playground) ──► String/JSON boundary
                       │
                       └──► Static Playground ──► Browser DOM
```

## Module map

| Module | Responsibility | Side effects |
|---|---|---|
| `model.mbt` | Public ADTs: `Expr`, `RuleDocument`, `Diagnostic`, `Decision`, `EvalError`, `TraceNode`, `TraceStatus`, `TraceMode`, `EvaluationReport`, `ExecutionStats`, `Budget` | None |
| `parser.mbt` | JSON → `RuleDocument` / `Expr`. Operator-key mapping, error reporting with rule paths | None |
| `checker.mbt` | Pre-evaluation structural validation. Arity, data-path syntax, literal types, depth/node budgets | None |
| `operators.mbt` | Pure comparison, collection, and string operator implementations | None |
| `evaluator.mbt` | Three-state evaluation with budgets, short-circuiting, and Trace construction | None |
| `trace_mode.mbt` | Deterministic Full→Summary / Full→Off Trace compression after full evaluation | None |
| `render.mbt` | Text tree rendering, `report_to_json`, `diagnostics_to_json` | None |
| `moonrules.mbt` | Public façade: `parse`, `check`, `evaluate`, `evaluate_json` | None |
| `rule_path.mbt` | Rule-path construction (`condition.and[1].==[0]`) | None |
| `data_path.mbt` | V1 dot-separated input-data lookup | None |
| `json_equal.mbt` | Locked JSON deep-equality semantics | None |
| `cmd/main/` | Native CLI: argparse, file I/O, stdin, stdout/stderr, exit codes | Filesystem, terminal |
| `cmd/playground/` | Web Adapter: `check_json`/`evaluate_json` string exports, options parsing, response envelope | None (foreign-library boundary) |
| `playground/` | Static Vite + TypeScript + CodeMirror 6 Playground UI | Browser DOM, clipboard, fetch |

## Core side-effect boundary

The root MoonBit package and `cmd/playground` contain no filesystem, network, environment, or process APIs. Native side effects are isolated to `cmd/main`. Browser side effects are isolated to `playground/`.

## Web Adapter backend

The v0.2.0 Playground uses the **MoonBit JavaScript target** as its adapter backend. A two-hour technical gate evaluated wasm-gc first; the JS fallback was selected because wasm-gc string interop with browsers produced `TypeError: type incompatibility when transforming from/to JS` with the current toolchain (`moonc 0.10.4`).

The adapter exports two functions with a stable string/JSON contract:

- `check_json(rule_source: String, options_source: String) -> String`
- `evaluate_json(rule_source: String, data_source: String, options_source: String) -> String`

Both return a UTF-8 JSON string with a fixed `{ ok, kind, report, diagnostics }` envelope. The TypeScript engine client (`playground/src/engine.ts`) imports the generated JS module and calls these functions. The rest of the Playground never knows which backend was selected.

## TraceMode compression

v0.2 Trace modes control the output shape, not the evaluation work:

1. A complete evaluation is performed using v0.1's existing semantics.
2. The resulting `EvaluationReport` is passed through a deterministic compressor.

This means Summary and Off do not reduce execution cost in v0.2. They reduce output volume and visual complexity while preserving identical `Decision` and `ExecutionStats`.

### Full

All operator, variable, literal, error, and skipped nodes are preserved. `resolved_inputs`, results, messages, and children are included. This is v0.1's behavior, unchanged.

### Summary

- Root and operator nodes are preserved.
- Error and skipped nodes are unconditionally preserved.
- Ordinary value-leaf nodes (`var` and `literal` with `Value` status and no children) are removed.
- Operator nodes retain compact `resolved_inputs` for explainability.
- Child order and `rule_path` are preserved.

### Off

- A single root node is returned.
- `resolved_inputs` and `children` are emptied.
- `Decision` and `ExecutionStats` are preserved.
- Top-level errors remain identifiable through `Decision::Indeterminate` and the root message.

## Three-state logic

```text
and: false > error > true
or:  true  > error > false
not: error → error; otherwise invert boolean
```

Budget-exceeded, type-mismatch, and missing-variable errors produce `Indeterminate` at the top level. Individual node errors are recorded in Trace even when a sibling's decisive boolean short-circuits the parent.

## Budget model

Five deterministic budgets are checked during evaluation:

| Budget | Default | Enforced at |
|---|---|---|
| Maximum rule depth | 64 | Checker + Evaluator |
| Maximum rule nodes | 4096 | Checker |
| Maximum execution steps | 10000 | Evaluator |
| Maximum Trace nodes | 4096 | Evaluator |
| Value preview characters | 256 | Renderer |

Callers may lower limits but cannot exceed library defaults. Wall-clock timeouts are not used — the engine is deterministic across platforms.
