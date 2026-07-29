# MoonRules

[![CI](https://github.com/z2823253773-p/moonrules/actions/workflows/ci.yml/badge.svg)](https://github.com/z2823253773-p/moonrules/actions/workflows/ci.yml)

MoonRules is an explainable, budget-limited JSON business-rule engine written in MoonBit. v0.2 adds an **online Playground**, **three Trace output modes**, and **CLI JSON/stdin support**.

JSON Schema validates structure; MoonRules evaluates business decisions and explains them. It parses a small JSONLogic-inspired DSL, reports preflight diagnostics, evaluates with deterministic three-state semantics, and returns a structured Trace showing every resolved variable, intermediate result, error, and short-circuit decision.

## Online Playground

**[Open the MoonRules Playground](https://z2823253773-p.github.io/moonrules/)** (deployment requires user confirmation)

Write rules, select examples, and explore explainable Traces directly in your browser. All data is processed locally — nothing is sent to a server.

## Quick start

```bash
moon add z2823253773-p/moonrules@0.2.0
```

```bash
moon check --deny-warn
moon test
moon run --target native cmd/main check examples/coupon.rule.json
moon run --target native cmd/main eval examples/coupon.rule.json --data examples/coupon.data.pass.json
```

The CLI prints every resolved variable and literal before reporting the decision. Use `--json` for machine-readable output, `-` for stdin, and `--help`/`--version` for usage information.

## Example

Rule:

```json
{
  "id": "student-coupon",
  "description": "adult students spending ≥ 100",
  "condition": {
    "and": [
      {">=": [{"var": "user.age"}, 18]},
      {"==": [{"var": "user.role"}, "student"]},
      {">=": [{"var": "order.total"}, 100]}
    ]
  }
}
```

Data (student but role is "guest" — fails):

```json
{
  "user": { "age": 20, "role": "guest" },
  "order": { "total": 128 }
}
```

Output (Summary mode):

```text
FAIL student-coupon
├─ PASS user.age >= 18     (resolved: 20 >= 18)
├─ FAIL user.role == "student"  (resolved: "guest" != "student")
└─ SKIPPED order.total >= 100   (and short-circuited)
```

## DSL overview

V1 supports `var`, `literal`, `and`, `or`, `not`, `==`, `!=`, `>`, `>=`, `<`, `<=`, `in`, `contains`, `starts_with`, and `ends_with`. Variable paths use dot-separated object fields only.

See [docs/DSL.md](docs/DSL.md) for syntax and [docs/API.md](docs/API.md) for the library façade.

## Trace modes

v0.2 supports three output modes. All modes first perform identical full evaluation; the mode only affects the output shape, so **Decision and Stats are always identical**:

- **Full** — every variable, literal, operator, error, and skipped node.
- **Summary** — removes ordinary value leaves, keeps operators, errors, and skipped nodes.
- **Off** — single root node with no children; Decision and Stats preserved.

## Safety and errors

Evaluation returns `Pass`, `Fail`, or `Indeterminate(error)`. `and` treats `false` as decisive; `or` treats `true` as decisive. Depth, node, step, Trace-node, and preview budgets are deterministic and caller-configurable only below the library ceilings. Budget exceeded returns a structured error with partial Trace preserved.

## Testing and benchmarks

- 71 MoonBit tests (native), 18 QuickCheck property tests, 11 Playwright browser tests.
- Reproducible benchmarks: 1000-node rule evaluates in ~1 ms, Full render in ~5 ms (Apple Silicon native release).
- See [docs/BENCHMARKS.md](docs/BENCHMARKS.md) and [docs/technical-report.md](docs/technical-report.md).

## Limitations

MoonRules is JSONLogic-inspired, not JSONLogic-compatible. It does not support array-index paths, loops, user functions, custom operators, network access, a server, a database, or a native GUI. The Playground is the only GUI exception and runs entirely in the local browser.

## Documentation

- [API reference](docs/API.md) · [DSL syntax](docs/DSL.md) · [Errors & budgets](docs/ERRORS.md)
- [Architecture](docs/ARCHITECTURE.md) · [Technical report](docs/technical-report.md) · [Benchmarks](docs/BENCHMARKS.md)
- [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md) · [Roadmap](ROADMAP.md) · [Third-party notices](THIRD_PARTY_NOTICES.md)

Licensed under Apache-2.0.
