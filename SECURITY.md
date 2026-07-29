# Security

## Execution model

MoonRules never executes arbitrary code. Rule evaluation is limited to a fixed set of built-in operators. The engine enforces deterministic execution budgets (maximum depth, node count, steps, and Trace nodes) and returns a structured error when any budget is exceeded.

The Web Playground processes rules and data entirely in the local browser. No input is sent to a server.

## Reporting a vulnerability

**Do not report security concerns through public Issues.**

Report them privately through GitHub's [security advisory interface](https://github.com/z2823253773-p/moonrules/security/advisories/new). Provide:

- MoonRules version and target (library, CLI, or Playground).
- A minimal rule and data that reproduces the issue.
- A description of the potential impact.

We will acknowledge receipt within 72 hours and aim to publish a fix or mitigation within 14 days.

## Supported versions

Only the latest published minor release receives security fixes. The current supported version is listed on the [releases page](https://github.com/z2823253773-p/moonrules/releases).

## Supply chain

MoonRules depends on:

- The MoonBit standard library and toolchain.
- `moonbitlang/async` and `moonbitlang/x` (pinned by version in `moon.mod`).
- The npm packages listed in `playground/package.json` (pinned in `package-lock.json`).

All third-party licenses are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). CI runs on every push and pull request; only green `main` is deployable.
