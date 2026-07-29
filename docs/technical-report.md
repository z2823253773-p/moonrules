# MoonRules v0.2 Technical Report

## 1. Problem and positioning

API gateways, form validators, pricing engines, and access-control systems all need to answer the same question: does this JSON input satisfy these business conditions, and why?

Existing solutions fall into two categories. JSON Schema validates structure — field presence, types, enumerations — but cannot express dynamic cross-field conditions like "age ≥ 18 AND role = student AND total ≥ 100." General-purpose rule engines (JSONLogic, JsonLogic, Cel) either lack explainability, require a runtime with dynamic code evaluation, or are not available as a MoonBit-native library.

**MoonRules** fills this gap. It is an explainable, budget-limited JSON business-rule engine written in MoonBit. It parses a small JSONLogic-inspired DSL, checks rules before execution, evaluates with deterministic three-state semantics, and returns a structured trace showing every resolved variable, intermediate result, error, and short-circuit decision.

## 2. DSL and JSON Schema boundary

MoonRules uses a JSONLogic-inspired expression format. Each operator is a single-key JSON object with arguments in an array:

```json
{
  "and": [
    {">=": [{"var": "user.age"}, 18]},
    {"==": [{"var": "user.role"}, "student"]}
  ]
}
```

The DSL is **inspired by but not compatible with** JSONLogic. MoonRules does not implement the full JSONLogic specification and does not claim compatibility.

The boundary with JSON Schema is explicit:

- JSON Schema validates whether data has the correct **shape** (fields, types, required/optional).
- MoonRules evaluates whether correctly-shaped data satisfies dynamic **business conditions**, and explains the evaluation.

A valid JSON Schema document can pass while MoonRules returns `Fail` — the order's structure is legal, but the customer does not qualify for the coupon.

## 3. Parser, checker, and evaluator architecture

The engine processes rules in three phases:

**Parser** (`parser.mbt`) converts JSON into a typed AST (`RuleDocument` / `Expr`). It maps operator keys to the `Operator` enum, validates the single-key-per-node rule, and rejects malformed `var`/`literal` nodes with rule-path-attributed errors. JSON parsing uses MoonBit's `@json.parse` from the standard library.

**Checker** (`checker.mbt`) performs pre-evaluation validation without input data:
- Operator existence and arity.
- V1 dot-separated data-path syntax.
- Statically detectable literal type errors.
- Rule depth and node count against configured budgets.
- Caller budget ceiling enforcement.

Diagnostics include stable error codes, severity, rule path, message, and suggestion.

**Evaluator** (`evaluator.mbt`) executes the rule against input data with deterministic three-state semantics. It constructs an independent `TraceNode` for every variable, literal, and operation. Execution budgets (depth, nodes, steps, Trace nodes) are checked at each step. Short-circuit evaluation stops `and` on `false` and `or` on `true`, marking remaining siblings as `Skipped`.

After full evaluation, the `TraceMode` compressor (`trace_mode.mbt`) shapes the output report. This ensures that Full, Summary, and Off always produce identical `Decision` and `ExecutionStats`.

## 4. Three-state logic

MoonRules uses three states instead of boolean pass/fail:

- `Pass` — the rule reliably evaluates to `true`.
- `Fail` — the rule reliably evaluates to `false`.
- `Indeterminate(EvalError)` — missing data, type mismatch, or budget exceeded prevents reliable evaluation.

Error propagation in logical operators:

```text
and: false > error > true   (false is decisive; error is kept if no false found)
or:  true  > error > false  (true is decisive; error is kept if no true found)
not: error → error           (otherwise invert boolean)
```

This ensures that errors are never silently converted to `false`, and that partial information (a decisive `false` in an `and` with an earlier error) still produces a correct result with the error preserved in the trace.

## 5. Budgets and partial Trace

Five deterministic budgets prevent unbounded resource consumption:

| Budget | Default | Purpose |
|---|---|---|
| `max_depth` | 64 | Prevent deeply nested rules from overflowing the stack |
| `max_rule_nodes` | 4096 | Reject excessively large rules at check time |
| `max_steps` | 10000 | Bound evaluation work |
| `max_trace_nodes` | 4096 | Bound Trace memory |
| `max_preview_chars` | 256 | Bound text rendering of large values |

When a budget is exceeded, the engine returns `Indeterminate` with a structured error and preserves all Trace nodes produced up to that point. The truncation point is marked with an `Error` node naming the budget, current count, and limit. Callers can lower limits but cannot exceed library defaults. Wall-clock timeouts are not used, preserving cross-platform determinism.

## 6. Full, Summary, and Off Trace modes

v0.2 introduces three output modes. All modes first perform an identical full evaluation; the mode only affects the final report shape:

- **Full** preserves every variable, literal, operator, error, and skipped node with all `resolved_inputs`, results, and children. This is v0.1's behavior, unchanged.
- **Summary** removes ordinary value-leaf nodes (`var` and `literal` with status `Value` and no children) while keeping all operator, error, and skipped nodes. Operator `resolved_inputs` remain for explainability.
- **Off** returns a single root node with no children and no resolved inputs. Decision and stats are preserved.

Properties verified by automated tests:
- All three modes produce identical `Decision`.
- Summary node count ≤ Full node count.
- Off always has exactly one Trace node.
- Repeated evaluation of the same rule and data produces identical JSON output.

## 7. Adapter and chosen backend

The Web Adapter (`cmd/playground`) exposes the rule engine to browsers through two exported functions with a stable string/JSON contract. A two-hour technical gate evaluated wasm-gc first. With the v0.10.4 toolchain, wasm-gc string interop produced `TypeError: type incompatibility when transforming from/to JS` in the target browser. The adapter was therefore built with the **MoonBit JavaScript target** as a planned fallback.

The adapter returns a fixed JSON envelope:

```json
{
  "ok": true,
  "kind": "evaluation",
  "report": { "decision": {...}, "trace": {...}, "stats": {...} },
  "diagnostics": []
}
```

The TypeScript engine client (`playground/src/engine.ts`) imports the generated JS module. No other part of the Playground depends on the backend choice.

## 8. Playground interaction and privacy

The Playground is a static single-page application built with Vite, TypeScript, and CodeMirror 6. It provides:

- Dual JSON editors (rule and data) with syntax highlighting and formatting.
- Three built-in business examples with pass/fail data variants.
- Check (pre-evaluation diagnostics) and Evaluate (full rule execution).
- Four result tabs: Trace, Diagnostics, JSON, Stats.
- Copy JSON and Download JSON actions.
- Full, Summary, and Off Trace mode selection.
- Responsive layout (desktop dual-column, mobile stacked).

All processing happens in the local browser. No data is sent to a server. The page displays this privacy notice prominently.

## 9. Tests and actual counts

| Category | Count | Notes |
|---|---|---|
| MoonBit unit/property/golden tests (native) | 71 | Covers parser, checker, evaluator, trace modes, renderer, CLI, adapter |
| MoonBit tests (wasm-gc) | 71 | Cross-target regression coverage |
| QuickCheck property tests | 18 | Double-negation, determinism, short-circuit, budget safety, mode invariants, JSON round-trip |
| Playground unit tests (Vitest) | 6 | Engine client, example loading, render helpers |
| Playground e2e tests (Playwright) | 11 | Page shell, evaluate, check, pass/fail variants, tabs, copy, download, malformed input, trace modes |
| CLI black-box tests | Shell script | File/stdin input, JSON/human output, exit codes 0/1/2, --help, --version |
| Benchmark fixtures | 6 files × 4 sizes | Parse, check, evaluate, render (Full/Summary/Off) |

## 10. Benchmark method and results

Benchmarks use MoonBit's `@bench.T` harness with deterministic rule fixtures at 1, 10, 100, and 1000 comparison nodes. All measurements are from a single Apple Silicon (arm64) machine running native release builds. Full results are published in [docs/BENCHMARKS.md](BENCHMARKS.md).

Key findings:
- Parse, check, and evaluate scale linearly with node count.
- Render Full and Summary scale with output size; Render Off is constant-time.
- A 1000-node rule evaluates in ~1 ms and renders Full in ~5 ms.
- The JS adapter artifact is ~309 KB (uncompressed).

These results demonstrate scaling trends, not universal performance guarantees.

## 11. AI-assisted development

AI coding agents (Codex and Claude Code) assisted with planning, implementation, tests, and documentation throughout the v0.1 and v0.2 development cycles. The human entrant (Hengrui Zhang) was responsible for:

- Defining project scope, DSL design, and architectural boundaries.
- Reviewing every AI-generated change before commit.
- Verifying all tests, builds, and benchmarks.
- Ensuring security, licensing compliance, and supply-chain integrity.
- Writing and approving all final claims in submission materials.

No AI-generated code was committed without human review. All public API contracts, error semantics, and budget policies were designed and approved by the entrant before implementation.

## 12. Dependency and license provenance

MoonRules is licensed under Apache-2.0. Third-party dependencies and their licenses are documented in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

Core dependencies:
- MoonBit compiler and standard library — Apache-2.0
- `moonbitlang/async@0.20.2` — Apache-2.0
- `moonbitlang/x@0.4.46` — Apache-2.0

Playground dependencies:
- CodeMirror 6 and Lezer — MIT
- Vite, Vitest, TypeScript, Playwright, jsdom — MIT / Apache-2.0

No part of MoonRules copies or derives from JSONLogic source code. References to JSONLogic describe semantic inspiration only.

## 13. Known limitations and v0.3

Current limitations:
- Data paths support dot-separated object fields only (no array indexing).
- Summary and Off modes reduce output but not evaluation cost.
- The Playground uses the JS backend; wasm-gc interop is gated on toolchain improvements.
- No schema-aware type environment for pre-evaluation type diagnostics.
- No custom operator API.

Planned for v0.3:
- Schema-aware variable type environment for richer pre-evaluation diagnostics.
- Date comparisons and basic arithmetic predicates.
- Playground keyboard shortcuts, dark mode, shareable hash-fragment URLs.

Explicit non-goals remain: full JSONLogic compatibility, array-index paths, user-defined operators, loops, arbitrary code execution, server, database, accounts, and native GUI.
