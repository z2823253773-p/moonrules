# MoonRules

[![CI](https://github.com/z2823253773-p/moonrules/actions/workflows/ci.yml/badge.svg)](https://github.com/z2823253773-p/moonrules/actions/workflows/ci.yml)

MoonRules is an explainable, budget-limited JSON business-rule engine written in MoonBit.

JSON Schema validates structure; MoonRules evaluates business decisions and explains them. It parses a small JSONLogic-inspired DSL, reports preflight diagnostics, evaluates with deterministic three-state semantics, and returns a structured Trace.

## Install

```bash
moon add z2823253773-p/moonrules@0.1.0
```

## Quick start

```bash
moon check --deny-warn
moon test
moon run --target native cmd/main check examples/coupon.rule.json
moon run --target native cmd/main eval examples/coupon.rule.json --data examples/coupon.data.pass.json
```

The second command prints every resolved variable and literal before reporting the decision.

## DSL overview

V1 supports `var`, `literal`, `and`, `or`, `not`, `==`, `!=`, `>`, `>=`, `<`, `<=`, `in`, `contains`, `starts_with`, and `ends_with`. Variable paths use dot-separated object fields only.

See [docs/DSL.md](docs/DSL.md) for syntax and [docs/API.md](docs/API.md) for the library façade.

## Safety and errors

Evaluation returns `Pass`, `Fail`, or `Indeterminate(error)`. `and` treats `false` as decisive; `or` treats `true` as decisive. Depth, node, step, Trace-node, and preview budgets are deterministic and caller-configurable only below the library ceilings.

## Limitations

V1 is not fully JSONLogic-compatible. It does not support array-index paths, loops, user functions, custom operators, network access, a server, a database, or a GUI. The CLI is native-only; the core library also builds for wasm-gc.

Licensed under Apache-2.0.
