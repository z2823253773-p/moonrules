# MoonRules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a MoonBit-native, explainable, budget-limited JSON business-rule engine with a thin native CLI, three runnable examples, CI, and submission-ready documentation.

**Architecture:** Keep the reusable rule engine in the root MoonBit package and isolate native file/terminal I/O in `cmd/main`. Parse JSON into a typed AST, check every rule before evaluation, evaluate with deterministic three-state semantics, and build an independent `TraceNode` for every variable, literal, and operation. Lock external behavior with black-box tests and golden Trace snapshots before adding property tests.

**Tech Stack:** MoonBit v0.10.x toolchain, `moonbitlang/core/json`, `moonbitlang/core/argparse`, `moonbitlang/core/env`, `moonbitlang/core/quickcheck`, `moonbitlang/async` native I/O, `moonbitlang/x/sys` for explicit exit codes, GitHub Actions, mooncakes.io.

---

## Scope and execution rules

- Work from `/Users/henryz/Documents/Moonbit 黑客松`.
- Read `docs/superpowers/specs/2026-07-23-moonrules-design.md` before every implementation session.
- Keep `.ai/TASK_STATE.md` current after each task so Codex and Claude Code can hand off safely.
- Use TDD: add one focused failing test, run it, implement the smallest behavior, rerun, then commit.
- Do not add a web server, database, Playground, array-index data paths, custom operators, or full JSONLogic compatibility.
- Do not send, paste, or commit GitHub, mooncakes.io, or other credentials.
- Stop after a dependency/API mismatch; record the exact command and error before revising this plan.

## Verified toolchain contract

The following points were verified against the installed 2026-07-13 toolchain
(`moon 0.1.20260713`, `moonc v0.10.4`) rather than inferred from older MoonBit
examples:

- `moon new` generates `moon.mod` and `moon.pkg`; this toolchain does not
  generate `moon.mod.json` or `moon.pkg.json`. Every manifest below follows the
  generated template's actual filename and syntax.
- `moon test PATH...` accepts a single test file such as
  `moon test model_test.mbt`.
- `moon run --target native cmd/main ARGS...` is the verified executable-package
  syntax.
- `moon ide doc` is unavailable in this installation, so API assumptions are
  verified with minimal compiling code plus `moon check --deny-warn` and focused
  tests before dependent behavior is implemented.
- `Json?` is valid optional-value syntax and is used for `TraceNode.result`.
- `StringBuilder` provides `is_empty()`, `write_char()`, `write_string()`, and
  `to_string()`. The implementation does not assume a `length()` method.
- `String.split(".")` is iterable as string views; each retained segment is
  converted with `to_owned()`.
- `@json.parse` raises on malformed JSON and is handled with `catch`.
- `Ref[Int]`, `Ref(0)`, and mutation through `count.val` compile.
- JSON objects support `length()`, `get()`, and direct key/value iteration; the
  implementation does not assume `Map.size()` or `Map.all()`.
- JSON numeric matching supports `Number(value, ..)`.
- `@quickcheck.samples(n)` compiles when
  `"moonbitlang/core/quickcheck"` is imported for tests. QuickCheck is a package
  in the bundled `moonbitlang/core` module, not a separate module to install
  with `moon add`.

## Locked file map

### Project and governance

- `moon.mod` — module metadata and pinned external module versions.
- `moon.pkg` — root library-package imports.
- `AGENTS.md` — commands, boundaries, and completion contract for coding agents.
- `.ai/TASK_STATE.md` — current milestone, decisions, commands, and next action.
- `.gitignore` — build output, local credentials, and editor noise.

### Rule engine

- `model.mbt` — public AST, diagnostics, decisions, Trace types, statistics, and budgets.
- `rule_path.mbt` — rule-document path construction and rendering.
- `data_path.mbt` — V1 dot-separated input-data lookup.
- `json_equal.mbt` — locked JSON deep-equality semantics.
- `parser.mbt` — JSON-to-`RuleDocument` conversion.
- `checker.mbt` — structural, operator, arity, literal-type, path, and static-budget checks.
- `operators.mbt` — pure comparison, collection, and string operators.
- `evaluator.mbt` — execution context, step/depth budgets, three-state logic, short-circuiting, and Trace construction.
- `render.mbt` — human-readable Trace tree and structured report JSON.
- `moonrules.mbt` — small public façade: `parse`, `check`, `evaluate`, and `evaluate_json`.

### Tests

- `model_test.mbt` — defaults and public type snapshots.
- `path_test.mbt` — rule-path rendering and data-path lookup.
- `parser_test.mbt` — valid and invalid DSL parsing.
- `checker_test.mbt` — diagnostics and static budget limits.
- `json_equal_test.mbt` — all equality rules.
- `evaluator_test.mbt` — minimal vertical slice, all operators, errors, short-circuiting, and budgets.
- `render_test.mbt` — golden human and JSON Trace outputs.
- `properties_test.mbt` — QuickCheck properties added only after deterministic tests pass.

### CLI, examples, and delivery

- `cmd/main/moon.pkg` — native executable imports.
- `cmd/main/main.mbt` — argv, file I/O, output, and exit-code wiring only.
- `examples/coupon.rule.json`, `examples/coupon.data.json` — primary demonstration.
- `examples/api-access.rule.json`, `examples/api-access.data.json` — API admission.
- `examples/membership.rule.json`, `examples/membership.data.json` — membership eligibility.
- `README.mbt.md` and `README.md` — Chinese main README and standard GitHub entry point.
- `README.en.md` — concise English installation, example, DSL, and limitations.
- `docs/DSL.md`, `docs/API.md`, `docs/ERRORS.md` — user-facing reference.
- `CHANGELOG.md`, `LICENSE` — release metadata.
- `.github/workflows/ci.yml` — format, check, test, build, and CLI smoke test.
- `docs/submission/moonrules-application.md` — source for the one-page application PDF.

## Task 1: Toolchain and dependency preflight

**Files:**
- Inspect: `docs/superpowers/specs/2026-07-23-moonrules-design.md`
- No workspace files are changed until every command in this gate passes.

- [x] **Step 1: Verify architecture and the official installer URL**

Run:

```bash
uname -m
curl -I https://cli.moonbitlang.com/install/unix.sh
```

Expected: `arm64`; the installer request returns an HTTP success or redirect from `cli.moonbitlang.com`. If either differs, stop and report the exact output.

- [x] **Step 2: Request approval and install the toolchain**

Run only after explicit approval because this writes under `~/.moon`:

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
```

Expected: installer completes without error.

- [x] **Step 3: Verify the installed commands**

Run:

```bash
export PATH="$HOME/.moon/bin:$PATH"
moon version --all
moon new --help
moon check --help
moon test --help
```

Expected: all four commands exit `0`; record the actual compiler and `moon` versions in `.ai/TASK_STATE.md` when that file is created in Task 2.

- [x] **Step 4: Generate a disposable current template**

Run:

```bash
MOONRULES_TEMPLATE_DIR="$(mktemp -d /tmp/moonrules-template.XXXXXX)"
moon new "$MOONRULES_TEMPLATE_DIR" --user z2823253773-p --name moonrules
find "$MOONRULES_TEMPLATE_DIR" -maxdepth 3 -type f -o -type l
sed -n '1,160p' "$MOONRULES_TEMPLATE_DIR/moon.mod"
sed -n '1,160p' "$MOONRULES_TEMPLATE_DIR/moon.pkg"
moon test --help
```

Expected: with the verified 2026-07-23 toolchain, the template contains `moon.mod`, `moon.pkg`, a root `.mbt` file, tests, `cmd/main/main.mbt`, and `cmd/main/moon.pkg`. Do not copy the nested `.git` directory.

Record the actual manifest filenames and syntax before Task 2. Also record the
template test naming convention and confirm from `moon test --help` that a
single file path is accepted. These observed results override any manifest or
test syntax shown in an older MoonBit example.

- [x] **Step 5: Verify core and external dependencies independently**

Inside the disposable template, run:

```bash
cd "$MOONRULES_TEMPLATE_DIR"
moon add moonbitlang/async@0.20.2
moon add moonbitlang/x@0.4.46
moon check --target native
moon test --target native
moon build --target native
```

Expected: all commands exit `0`. If the exact pinned versions are unavailable or incompatible with the installed toolchain, stop and revise the dependency versions in this plan before creating project files.

Do not run `moon add moonbitlang/core/quickcheck`: `moon add` installs modules,
while QuickCheck is already a package in the bundled `moonbitlang/core` module.
Its package import is added for tests in Task 14 and verified by the complete
test matrix there.

- [x] **Step 6: Lock compiler-verified API shapes**

Because `moon ide doc` is unavailable in this toolchain, use the smallest
compiling implementation and focused test in each dependent task as the API
probe. Do not build later behavior until the probe passes:

| API surface | First compiler-backed probe | Locked result |
|---|---|---|
| Optional JSON and JSON parsing | Tasks 3 and 5 | `Json?`; `@json.parse(...) catch { ... }` |
| `StringBuilder` and `String.split` | Task 4 | builder methods above; split yields views converted with `to_owned()` |
| `Ref[Int]` | Task 6 | `let count : Ref[Int] = Ref(0)` and `count.val += 1` |
| JSON object and number matching | Task 9 | `length()`, `get()`, key/value iteration, `Number(value, ..)` |
| QuickCheck | Task 14 | test-only core import and typed `@quickcheck.samples(n)` |

Run after the probes exist:

```bash
moon fmt --check
moon check --deny-warn
moon test --target native
```

Expected: no warnings and all focused tests pass. If a probe fails, update its
task to match compiler diagnostics before continuing.

## Task 2: Project metadata and agent-safe handoff

**Files:**
- Create: `moon.mod`
- Create: `moon.pkg`
- Create: `AGENTS.md`
- Create: `.ai/TASK_STATE.md`
- Create: `.gitignore`
- Create: `LICENSE`

- [x] **Step 1: Create the module and root-package configuration**

Create `moon.mod` with the current template's field spelling and these exact values:

```moonbit
name = "z2823253773-p/moonrules"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/z2823253773-p/moonrules"

license = "Apache-2.0"

keywords = ["rules-engine", "json", "validation", "explainable"]

preferred_target = "wasm-gc"

description = "Explainable and budget-limited JSON business rules for MoonBit"
```

Create `moon.pkg` using the exact filename and syntax emitted by the Task 1
template. For the verified toolchain, the expected content is:

```moonbit
import {
  "moonbitlang/core/json",
}

import {
  "moonbitlang/core/test",
} for "test"
```

Run:

```bash
moon fmt
moon check
```

Expected: configuration parses. Source-related errors are acceptable only until `model.mbt` is added in Task 3; configuration errors must be fixed now.

- [x] **Step 2: Create project rules for both coding agents**

Create `AGENTS.md` with this contract:

```markdown
# MoonRules agent contract

Read `.ai/TASK_STATE.md` and the approved design before editing.

Commands: `moon fmt --check`, `moon check`, `moon test`, `moon build --target native`.

Keep the reusable engine free of filesystem, network, environment, and process APIs. Native side effects belong only in `cmd/main`.

Follow TDD, keep commits small, and update `.ai/TASK_STATE.md` after each task. Do not add full JSONLogic compatibility, array-index paths, a server, a database, a GUI, or credential files.
```

Create `.ai/TASK_STATE.md`:

```markdown
# MoonRules task state

## Current milestone

Task 2: project metadata and governance.

## Locked decisions

- JSONLogic-inspired, not JSONLogic-compatible.
- Independent Trace nodes for variables and literals.
- Three-state evaluation with deterministic budgets.
- Native CLI is a thin wrapper around a portable core library.

## Verification commands

`moon fmt --check && moon check && moon test && moon build --target native`

## Next action

Create the public model and default execution budget in Task 3.
```

Create `.gitignore`:

```gitignore
target/
_build/
.mooncakes/
.DS_Store
.idea/
.vscode/
*.log
*.tmp
credentials.json
.env
```

- [x] **Step 3: Add the Apache-2.0 license**

Use the unmodified Apache License 2.0 text in `LICENSE`, with copyright line:

```text
Copyright 2026 Hengrui Zhang
```

Verify:

```bash
rg -n "Apache License|Copyright 2026" LICENSE
```

Expected: both phrases are present.

- [x] **Step 4: Fix repository-local public Git identity before any push**

Run:

```bash
git config user.name "z2823253773-p"
git config user.email "235035337+z2823253773-p@users.noreply.github.com"
git config --get user.name
git config --get user.email
```

Expected: the repository-local values are the GitHub login and noreply address. Before public push, rewrite the two existing documentation commits with `--reset-author` in a supervised step; do not run a history rewrite after a remote branch has been shared.

- [x] **Step 5: Commit project metadata**

Run:

```bash
git add moon.mod moon.pkg AGENTS.md .ai/TASK_STATE.md .gitignore LICENSE
git commit -m "chore: initialize MoonRules module"
```

Expected: one commit containing only project metadata and governance.

## Task 3: Public model and budget contracts

**Files:**
- Create: `model.mbt`
- Create: `model_test.mbt`
- Modify: `.ai/TASK_STATE.md`

- [x] **Step 1: Write failing tests for locked defaults and decisions**

Create `model_test.mbt`:

```moonbit
///|
test "default budget is locked" {
  let budget = Budget::default()
  inspect(
    (
      budget.max_depth,
      budget.max_rule_nodes,
      budget.max_steps,
      budget.max_trace_nodes,
      budget.max_preview_chars,
    ),
    content="(64, 4096, 10000, 4096, 256)",
  )
}

///|
test "decision keeps false separate from execution error" {
  inspect(Decision::Fail, content="Fail")
  inspect(
    Decision::Indeterminate(EvalError::MissingVariable("user.age")),
    content="Indeterminate(MissingVariable(\"user.age\"))",
  )
}

///|
test "V1 exposes trace modes but implements full only" {
  inspect([TraceMode::Off, TraceMode::Summary, TraceMode::Full], content="[Off, Summary, Full]")
}
```

Run:

```bash
moon test model_test.mbt
```

Expected: FAIL because the public types are not defined.

- [x] **Step 2: Define the public AST, diagnostics, results, and budget**

Create `model.mbt` with these public shapes:

```moonbit
pub(all) enum Operator {
  And
  Or
  Not
  Equal
  NotEqual
  GreaterThan
  GreaterOrEqual
  LessThan
  LessOrEqual
  In
  Contains
  StartsWith
  EndsWith
} derive(Eq, Show)

pub(all) enum Expr {
  Literal(Json)
  Variable(String)
  Operation(Operator, Array[Expr])
} derive(Eq, Show)

pub(all) struct RuleDocument {
  id : String
  description : String
  condition : Expr
} derive(Eq, Show)

pub(all) enum DiagnosticSeverity {
  Error
  Warning
} derive(Eq, Show)

pub(all) struct Diagnostic {
  code : String
  severity : DiagnosticSeverity
  rule_path : String
  message : String
  suggestion : String
} derive(Eq, Show)

pub(all) enum EvalError {
  MissingVariable(String)
  TypeMismatch(String)
  BudgetExceeded(String, Int, Int)
  UnsupportedTraceMode(String)
} derive(Eq, Show)

pub(all) enum Decision {
  Pass
  Fail
  Indeterminate(EvalError)
} derive(Eq, Show)

pub(all) enum TraceStatus {
  Value
  Pass
  Fail
  Error
  Skipped
} derive(Eq, Show)

pub(all) enum TraceMode {
  Off
  Summary
  Full
} derive(Eq, Show)

pub(all) struct ResolvedInput {
  source : String
  value : Json
} derive(Eq, Show)

pub(all) struct TraceNode {
  rule_path : String
  operator : String
  status : TraceStatus
  resolved_inputs : Array[ResolvedInput]
  result : Json?
  message : String
  children : Array[TraceNode]
} derive(Eq, Show)

pub(all) struct ExecutionStats {
  steps_executed : Int
  nodes_evaluated : Int
  max_depth_reached : Int
  trace_nodes_emitted : Int
} derive(Eq, Show)

pub(all) struct EvaluationReport {
  decision : Decision
  trace : TraceNode
  stats : ExecutionStats
} derive(Eq, Show)

pub(all) struct Budget {
  max_depth : Int
  max_rule_nodes : Int
  max_steps : Int
  max_trace_nodes : Int
  max_preview_chars : Int
} derive(Eq, Show)

pub fn Budget::default() -> Budget {
  {
    max_depth: 64,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
}
```

- [x] **Step 3: Format and make the model tests pass**

Run:

```bash
moon fmt
moon test model_test.mbt
moon check
```

Expected: PASS with no warnings.

- [x] **Step 4: Commit the public contracts**

Update `.ai/TASK_STATE.md` to Task 4, then run:

```bash
git add model.mbt model_test.mbt .ai/TASK_STATE.md
git commit -m "feat: define rule and trace contracts"
```

## Task 4: Rule paths and V1 data paths

**Files:**
- Create: `rule_path.mbt`
- Create: `data_path.mbt`
- Create: `path_test.mbt`

- [x] **Step 1: Write failing path tests**

Create `path_test.mbt`:

```moonbit
///|
test "rule path uses fields and indexes consistently" {
  let path = RulePath::root()
    .field("condition")
    .field("and")
    .index(1)
    .field("==")
    .index(0)
    .field("var")
  inspect(path.to_string(), content="condition.and[1].==[0].var")
}

///|
test "data path reads nested object fields" {
  let data = @json.parse(#|{"user":{"age":20}}|)
  inspect(resolve_data_path(data, "user.age"), content="Ok(20)")
}

///|
test "data path rejects V2 syntax" {
  inspect(parse_data_path("items[0].price"), content="Err(InvalidDataPath(\"items[0].price\"))")
  inspect(parse_data_path("user..age"), content="Err(InvalidDataPath(\"user..age\"))")
}
```

Run `moon test path_test.mbt`; expected: FAIL because path APIs do not exist.

- [x] **Step 2: Implement rule-path rendering**

Create `rule_path.mbt`:

```moonbit
pub(all) enum RulePathSegment {
  Field(String)
  Index(Int)
} derive(Eq, Show)

pub(all) struct RulePath {
  segments : Array[RulePathSegment]
} derive(Eq, Show)

pub fn RulePath::root() -> RulePath { { segments: [] } }

pub fn RulePath::field(self : RulePath, name : String) -> RulePath {
  { segments: self.segments + [Field(name)] }
}

pub fn RulePath::index(self : RulePath, index : Int) -> RulePath {
  { segments: self.segments + [Index(index)] }
}

pub fn RulePath::to_string(self : RulePath) -> String {
  let out = StringBuilder()
  for segment in self.segments {
    match segment {
      Field(name) => {
        if out.length() > 0 { out.write_char('.') }
        out.write_string(name)
      }
      Index(index) => out.write_string("[\{index}]")
    }
  }
  out.to_string()
}
```

- [x] **Step 3: Implement dot-only data paths**

Create `data_path.mbt` with a public parse error and these functions:

```moonbit
pub(all) enum DataPathError {
  InvalidDataPath(String)
  MissingDataPath(String)
  NonObjectSegment(String)
} derive(Eq, Show)

pub fn parse_data_path(path : String) -> Result[Array[String], DataPathError] {
  let parts = path.split(".")
  if path == "" || parts.any(fn(part) { part == "" || part.contains("[") || part.contains("]") }) {
    Err(InvalidDataPath(path))
  } else {
    Ok(parts)
  }
}

pub fn resolve_data_path(data : Json, path : String) -> Result[Json, DataPathError] {
  let parts = parse_data_path(path)?
  let mut current = data
  for part in parts {
    match current {
      Object(fields) =>
        match fields.get(part) {
          Some(value) => current = value
          None => return Err(MissingDataPath(path))
        }
      _ => return Err(NonObjectSegment(part))
    }
  }
  Ok(current)
}
```

- [x] **Step 4: Verify and commit paths**

Run:

```bash
moon fmt
moon test path_test.mbt
moon check
git add rule_path.mbt data_path.mbt path_test.mbt .ai/TASK_STATE.md
git commit -m "feat: add rule and data paths"
```

Expected: all path tests pass.

## Task 5: DSL parser

**Files:**
- Create: `parser.mbt`
- Create: `parser_test.mbt`

- [x] **Step 1: Write parser tests before implementation**

Create tests for the exact primary rule and three invalid shapes:

```moonbit
///|
test "parse coupon rule" {
  let json = @json.parse(
    #|{"id":"student-coupon","description":"adult student","condition":{"and":[{">=":[{"var":"user.age"},18]},{"==":[{"var":"user.role"},"student"]}]}}|,
  )
  let rule = parse_rule_document(json)
  inspect(rule.id, content="student-coupon")
  inspect(rule.condition is Operation(And, _), content="true")
}

///|
test "reject object with multiple operator keys" {
  let json = @json.parse(#|{"id":"x","description":"x","condition":{"and":[],"or":[]}}|)
  inspect(parse_rule_document(json), content="Err(MultipleOperatorKeys(\"condition\"))")
}

///|
test "reject malformed var and unwrapped object literal" {
  let bad_var = @json.parse(#|{"id":"x","description":"x","condition":{"var":42}}|)
  inspect(parse_rule_document(bad_var), content="Err(InvalidVariable(\"condition.var\"))")
  let object_literal = @json.parse(#|{"id":"x","description":"x","condition":{"country":"CN"}}|)
  inspect(parse_rule_document(object_literal), content="Err(UnknownOperator(\"country\"))")
}
```

Run `moon test parser_test.mbt`; expected: FAIL.

- [x] **Step 2: Add explicit parse errors and operator mapping**

In `parser.mbt`, define:

```moonbit
pub(all) enum RuleParseError {
  ExpectedObject(String)
  MissingField(String)
  ExpectedString(String)
  MultipleOperatorKeys(String)
  UnknownOperator(String)
  InvalidVariable(String)
  InvalidLiteral(String)
  InvalidArguments(String)
} derive(Eq, Show)

fn parse_operator(name : String) -> Result[Operator, RuleParseError] {
  match name {
    "and" => Ok(And)
    "or" => Ok(Or)
    "not" => Ok(Not)
    "==" => Ok(Equal)
    "!=" => Ok(NotEqual)
    ">" => Ok(GreaterThan)
    ">=" => Ok(GreaterOrEqual)
    "<" => Ok(LessThan)
    "<=" => Ok(LessOrEqual)
    "in" => Ok(In)
    "contains" => Ok(Contains)
    "starts_with" => Ok(StartsWith)
    "ends_with" => Ok(EndsWith)
    name => Err(UnknownOperator(name))
  }
}
```

- [x] **Step 3: Implement `parse_rule_document` and recursive `parse_expr`**

The implementation must obey this exhaustive decision table:

```text
JSON primitive or array            -> Expr::Literal
{"literal": object}               -> Expr::Literal(object)
{"var": string}                   -> Expr::Variable(string)
{known_operator: array}            -> Expr::Operation(operator, parsed arguments)
object with zero or multiple keys  -> structured RuleParseError
unknown single key                 -> UnknownOperator
```

Use these signatures and start the root at `RulePath::root().field("condition")`:

```moonbit
pub fn parse_rule_document(json : Json) -> Result[RuleDocument, RuleParseError]
fn parse_expr(json : Json, path : RulePath) -> Result[Expr, RuleParseError]
fn parse_expr_array(values : Array[Json], path : RulePath) -> Result[Array[Expr], RuleParseError]
```

Do not perform arity or runtime-type checks here; those belong to `checker.mbt`.

- [x] **Step 4: Verify and commit parser behavior**

Run:

```bash
moon fmt
moon test parser_test.mbt
moon test
moon check
git add parser.mbt parser_test.mbt .ai/TASK_STATE.md
git commit -m "feat: parse MoonRules DSL"
```

## Task 6: Static checker and diagnostics

**Files:**
- Create: `checker.mbt`
- Create: `checker_test.mbt`

- [x] **Step 1: Add failing diagnostic snapshots**

```moonbit
///|
test "checker reports arity and data path" {
  let expr = Operation(And, [
    Operation(GreaterThan, [Literal(18)]),
    Variable("items[0].price"),
  ])
  inspect(
    check_expr(expr, Budget::default()),
    content=(
      #|[
      #|  { code: "E_ARITY", severity: Error, rule_path: "condition.and[0].>", message: "operator > expects 2 arguments, received 1", suggestion: "provide exactly 2 arguments" },
      #|  { code: "E_DATA_PATH", severity: Error, rule_path: "condition.and[1].var", message: "V1 data paths only support dot-separated object fields", suggestion: "replace items[0].price with an object-field path" },
      #|]
    ),
  )
}

///|
test "empty diagnostics means check passed" {
  let expr = Operation(GreaterOrEqual, [Variable("user.age"), Literal(18)])
  inspect(check_expr(expr, Budget::default()), content="[]")
}

///|
test "caller cannot raise library budget ceilings" {
  let budget = Budget::{
    max_depth: 65,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
  inspect(validate_budget(budget)[0].code, content="E_BUDGET_LIMIT")
}
```

Run `moon test checker_test.mbt`; expected: FAIL.

- [x] **Step 2: Implement checker traversal and arity table**

Construct every operator segment from its DSL JSON key (`and`, `or`, `not`,
`==`, `!=`, `>`, `>=`, `<`, `<=`, `in`, `contains`, `starts_with`, or
`ends_with`), not from the MoonBit enum variant name. Therefore
`condition.and[0].>` in the snapshot above is intentional and consistent with
`condition.and[1].==[0].var` in the design.

Use this exact arity function:

```moonbit
fn valid_arity(operator : Operator, count : Int) -> Bool {
  match operator {
    And | Or => count >= 1
    Not => count == 1
    Equal | NotEqual | GreaterThan | GreaterOrEqual | LessThan | LessOrEqual |
    In | Contains | StartsWith | EndsWith => count == 2
  }
}
```

Implement:

```moonbit
pub fn check_expr(expr : Expr, budget : Budget) -> Array[Diagnostic]
pub fn validate_budget(budget : Budget) -> Array[Diagnostic]
fn check_node(expr : Expr, path : RulePath, depth : Int, count : Ref[Int], budget : Budget, out : Array[Diagnostic]) -> Unit
```

The traversal must append diagnostics in preorder so output is deterministic. It checks arity, V1 data-path syntax, obvious literal operand types, `max_depth`, and `max_rule_nodes`. `validate_budget` emits `E_BUDGET_LIMIT` for every supplied value above `Budget::default()`; V1 callers may lower limits but may not raise them.

- [x] **Step 3: Verify and commit the checker**

Run `moon fmt && moon test checker_test.mbt && moon test && moon check`.

Expected: PASS. Commit:

```bash
git add checker.mbt checker_test.mbt .ai/TASK_STATE.md
git commit -m "feat: validate rules before evaluation"
```

## Task 7: Minimal evaluator and independent Trace nodes

**Files:**
- Create: `operators.mbt`
- Create: `evaluator.mbt`
- Create: `evaluator_test.mbt`
- Create: `examples/coupon.rule.json`
- Create: `examples/coupon.data.json`

- [x] **Step 1: Add the coupon files and failing vertical-slice test**

Use the exact coupon rule and data from the approved design. Add this direct-library test:

```moonbit
///|
test "coupon trace has independent variable and literal nodes" {
  let rule = RuleDocument::{
    id: "student-coupon",
    description: "adult students",
    condition: Operation(GreaterOrEqual, [Variable("user.age"), Literal(18)]),
  }
  let data = @json.parse(#|{"user":{"age":20}}|)
  let report = evaluate(rule, data, Budget::default())
  inspect(report.decision, content="Pass")
  inspect(report.trace.children.length(), content="2")
  inspect(report.trace.children[0].status, content="Value")
  inspect(report.trace.children[0].result, content="Some(20)")
  inspect(report.trace.children[1].status, content="Value")
  inspect(report.trace.children[1].result, content="Some(18)")
}
```

Run `moon test evaluator_test.mbt`; expected: FAIL.

- [x] **Step 2: Implement numeric comparison helpers**

In `operators.mbt`, implement strict numeric comparison without coercion:

```moonbit
fn compare_numbers(
  operator : Operator,
  left : Json,
  right : Json,
) -> Result[Bool, EvalError] {
  guard left is Number(a, ..) && right is Number(b, ..) else {
    return Err(TypeMismatch("numeric comparison requires two numbers"))
  }
  Ok(match operator {
    GreaterThan => a > b
    GreaterOrEqual => a >= b
    LessThan => a < b
    LessOrEqual => a <= b
    _ => false
  })
}
```

- [x] **Step 3: Implement the evaluation context and vertical slice**

In `evaluator.mbt`, define a private mutable context with `budget`, `steps`, `nodes`, `max_depth`, and `trace_nodes`. Implement:

```moonbit
pub fn evaluate(
  rule : RuleDocument,
  data : Json,
  budget : Budget,
  trace_mode? : TraceMode = Full,
) -> EvaluationReport
pub fn evaluate_condition(
  condition : Expr,
  data : Json,
  budget : Budget,
  trace_mode? : TraceMode = Full,
) -> EvaluationReport
fn eval_expr(ctx : EvalContext, expr : Expr, data : Json, path : RulePath, depth : Int) -> EvalNodeResult
fn value_trace(path : RulePath, operator : String, value : Json, source : String) -> TraceNode
fn error_trace(path : RulePath, operator : String, error : EvalError) -> TraceNode
```

`evaluate_condition` wraps the expression in a private synthetic `RuleDocument` and delegates to `evaluate`; it exists to keep operator tests small. The first implementation supports `Literal`, `Variable`, `GreaterOrEqual`, and `And`. Every operand produces its own child Trace and every operation captures child results as `ResolvedInput` value snapshots. Map `DataPathError::MissingDataPath` to `EvalError::MissingVariable` and all other data-path failures to `EvalError::TypeMismatch`.

Before evaluation, reject budgets above library defaults with a terminal `BudgetExceeded` report. `TraceMode::Full` runs normally; `Off` and `Summary` return a terminal `UnsupportedTraceMode` report in V1.

- [x] **Step 4: Verify the vertical slice and commit**

Run:

```bash
moon fmt
moon test evaluator_test.mbt
moon test
moon check
git add operators.mbt evaluator.mbt evaluator_test.mbt examples .ai/TASK_STATE.md
git commit -m "feat: evaluate rules with explainable traces"
```

## Task 8: Three-state logic and execution budgets

**Files:**
- Modify: `evaluator.mbt`
- Modify: `evaluator_test.mbt`

- [x] **Step 1: Add failing tests for error dominance and short-circuiting**

```moonbit
///|
test "and false dominates earlier error" {
  let expr = Operation(And, [Variable("missing"), Literal(false), Variable("never")])
  let report = evaluate_condition(expr, {}, Budget::default())
  inspect(report.decision, content="Fail")
  inspect(report.trace.children[0].status, content="Error")
  inspect(report.trace.children[1].status, content="Value")
  inspect(report.trace.children[2].status, content="Skipped")
}

///|
test "or true dominates earlier error" {
  let expr = Operation(Or, [Variable("missing"), Literal(true), Variable("never")])
  let report = evaluate_condition(expr, {}, Budget::default())
  inspect(report.decision, content="Pass")
  inspect(report.trace.children[2].status, content="Skipped")
}

///|
test "error remains indeterminate without decisive boolean" {
  let expr = Operation(And, [Literal(true), Variable("missing")])
  inspect(
    evaluate_condition(expr, {}, Budget::default()).decision,
    content="Indeterminate(MissingVariable(\"missing\"))",
  )
}

///|
test "V1 rejects unimplemented trace modes explicitly" {
  let expr = Literal(true)
  inspect(
    evaluate_condition(expr, {}, Budget::default(), trace_mode=Off).decision,
    content="Indeterminate(UnsupportedTraceMode(\"Off\"))",
  )
}
```

- [x] **Step 2: Add failing tests for each budget**

Test `max_depth`, `max_rule_nodes`, `max_steps`, and `max_trace_nodes` independently. For Trace exhaustion, assert that the final emitted node has `status == Error`, its message names `max_trace_nodes`, and no later descendants exist.

- [x] **Step 3: Implement `and`, `or`, `not`, and budget reservation**

Use these precedence rules exactly:

```text
and: false > error > true
or:  true  > error > false
not: error remains error; otherwise invert boolean
```

Reserve one Trace slot before evaluating a node. When only the reserved slot remains, emit `BudgetExceeded("max_trace_nodes", current, limit)` at that node and stop expanding descendants.

- [x] **Step 4: Verify and commit logic and budgets**

Run `moon fmt && moon test evaluator_test.mbt && moon test && moon check`.

Commit:

```bash
git add evaluator.mbt evaluator_test.mbt .ai/TASK_STATE.md
git commit -m "feat: enforce deterministic evaluation budgets"
```

## Task 9: JSON equality and remaining comparison operators

**Files:**
- Create: `json_equal.mbt`
- Create: `json_equal_test.mbt`
- Modify: `operators.mbt`
- Modify: `evaluator.mbt`
- Modify: `evaluator_test.mbt`

- [x] **Step 1: Lock deep-equality behavior with failing tests**

```moonbit
///|
test "JSON equality follows the specification" {
  let ab = @json.parse(#|{"a":1,"b":2}|)
  let ba = @json.parse(#|{"b":2.0,"a":1.0}|)
  inspect(json_deep_equal(ab, ba), content="true")
  inspect(json_deep_equal([1, 2], [2, 1]), content="false")
  inspect(json_deep_equal(null, null), content="true")
  inspect(json_deep_equal(null, false), content="false")
}
```

Also test nested objects, unequal keys, unequal array lengths, strings, booleans, and cross-type values.

- [x] **Step 2: Implement exhaustive recursive equality**

Create `json_equal.mbt` with:

```moonbit
pub fn json_deep_equal(left : Json, right : Json) -> Bool {
  match (left, right) {
    (Null, Null) | (True, True) | (False, False) => true
    (Number(a, ..), Number(b, ..)) => a == b
    (String(a), String(b)) => a == b
    (Array(a), Array(b)) =>
      a.length() == b.length() &&
      a.indices().all(fn(i) { json_deep_equal(a[i], b[i]) })
    (Object(a), Object(b)) =>
      a.size() == b.size() &&
      a.all(fn(key, value) {
        match b.get(key) {
          Some(other) => json_deep_equal(value, other)
          None => false
        }
      })
    _ => false
  }
}
```

If current `Map` iteration uses a different method, use `moon ide doc 'Map::iter'` and update only the object arm while preserving the tests and semantics.

- [x] **Step 3: Wire `==`, `!=`, `>`, `>=`, `<`, and `<=`**

Add exhaustive operator dispatch in `operators.mbt`; equality accepts every JSON type, while ordered comparison accepts only two JSON numbers. Add one evaluator test per operator and one type-error test shared across ordered comparisons.

- [x] **Step 4: Verify and commit comparisons**

Run all tests and commit:

```bash
git add json_equal.mbt json_equal_test.mbt operators.mbt evaluator.mbt evaluator_test.mbt .ai/TASK_STATE.md
git commit -m "feat: add strict JSON comparisons"
```

## Task 10: Collection and string operators

**Files:**
- Modify: `operators.mbt`
- Modify: `evaluator.mbt`
- Modify: `evaluator_test.mbt`

- [x] **Step 1: Add a table of failing operator tests**

Cover these exact cases:

```text
in("admin", ["viewer", "admin"])             -> true
in({"a": 1}, [{"a": 1.0}])                  -> true
contains("moonrules", "rules")               -> true
starts_with("moonrules", "moon")             -> true
ends_with("moonrules", "rules")              -> true
contains([1, 2], 1)                            -> TypeMismatch
in("admin", "administrator")                 -> TypeMismatch
```

- [x] **Step 2: Implement strict collection and string helpers**

Add:

```moonbit
fn evaluate_in(needle : Json, haystack : Json) -> Result[Bool, EvalError] {
  guard haystack is Array(values) else {
    return Err(TypeMismatch("in requires an array as its second argument"))
  }
  Ok(values.any(fn(value) { json_deep_equal(needle, value) }))
}

fn evaluate_text(operator : Operator, left : Json, right : Json) -> Result[Bool, EvalError] {
  guard left is String(text) && right is String(part) else {
    return Err(TypeMismatch("string operator requires two strings"))
  }
  Ok(match operator {
    Contains => text.contains(part)
    StartsWith => text.starts_with(part)
    EndsWith => text.ends_with(part)
    _ => false
  })
}
```

- [x] **Step 3: Verify all 15 V1 node/operator forms and commit**

Run `moon fmt && moon test && moon check && moon build --target native`.

Expected: every operator named in the design has at least one success and one failure/error test. Commit:

```bash
git add operators.mbt evaluator.mbt evaluator_test.mbt .ai/TASK_STATE.md
git commit -m "feat: complete V1 rule operators"
```

## Task 11: Trace rendering and public façade

**Files:**
- Create: `render.mbt`
- Create: `render_test.mbt`
- Create: `moonrules.mbt`

- [x] **Step 1: Add golden tests for the coupon Trace**

The text snapshot must match the approved design, including independent `VALUE var(...)` and `VALUE literal` nodes and `SKIPPED` after `and` short-circuiting. Add a JSON snapshot asserting `decision`, `trace`, and all four `stats` fields.

- [x] **Step 2: Implement bounded text rendering**

Use:

```moonbit
pub fn render_report(report : EvaluationReport, budget : Budget) -> String
fn render_node(out : StringBuilder, node : TraceNode, prefix : String, is_last : Bool, budget : Budget) -> Unit
fn preview_json(value : Json, max_chars : Int) -> String
```

`preview_json` returns the full `stringify()` result when it fits; otherwise it returns the first `max_chars` characters followed by the literal suffix `…(truncated)`.

- [x] **Step 3: Implement structured report JSON**

Add `report_to_json(report : EvaluationReport) -> Json`. Use stable object keys and preserve child order. Do not serialize wall-clock time or memory addresses.

- [x] **Step 4: Add the public façade**

Create `moonrules.mbt`:

```moonbit
pub fn parse(source : String) -> Result[RuleDocument, RuleParseError] {
  try {
    parse_rule_document(@json.parse(source))
  } catch {
    error => Err(ExpectedObject("invalid JSON: \{error}"))
  }
}

pub fn check(rule : RuleDocument, budget? : Budget = Budget::default()) -> Array[Diagnostic] {
  check_expr(rule.condition, budget)
}

pub fn evaluate_json(
  rule_source : String,
  data_source : String,
  budget? : Budget = Budget::default(),
  trace_mode? : TraceMode = Full,
) -> Result[EvaluationReport, String] {
  let rule = parse(rule_source).map_err(fn(error) { "\{error}" })?
  let diagnostics = check(rule, budget~)
  if diagnostics.length() > 0 {
    return Err("rule check failed: \{diagnostics}")
  }
  let data = try @json.parse(data_source) catch {
    error => return Err("invalid data JSON: \{error}")
  }
  Ok(evaluate(rule, data, budget, trace_mode~))
}
```

- [x] **Step 5: Verify and commit rendering/API**

Run all checks and commit:

```bash
git add render.mbt render_test.mbt moonrules.mbt .ai/TASK_STATE.md
git commit -m "feat: expose reports and trace rendering"
```

## Task 12: Thin native CLI

**Files:**
- Modify: `moon.mod`
- Create: `cmd/main/moon.pkg`
- Create: `cmd/main/main.mbt`

- [x] **Step 1: Add and pin official dependencies**

Run:

```bash
moon add moonbitlang/async@0.20.2
moon add moonbitlang/x@0.4.46
```

Expected: `moon.mod` records both exact compatible versions. If Task 1 required different verified versions, use those recorded versions consistently and update this plan before proceeding.

- [x] **Step 2: Configure the executable package**

Create `cmd/main/moon.pkg`:

```moonbit
import {
  "z2823253773-p/moonrules" @moonrules,
  "moonbitlang/core/argparse",
  "moonbitlang/core/env",
  "moonbitlang/async",
  "moonbitlang/async/fs",
  "moonbitlang/async/stdio",
  "moonbitlang/x/sys",
}

pkgtype(kind: "executable")
```

- [x] **Step 3: Implement only `check` and `eval` wiring**

Create `cmd/main/main.mbt` with two argparse subcommands:

```text
moonrules check <rule.json>
moonrules eval <rule.json> --data <data.json>
```

Use `@env.args()` for argv, `@fs.read_file(path).text()` for UTF-8 file input, `@stdio.stdout.write()` for normal output, `@stdio.stderr.write()` for diagnostics, and `@sys.exit()` for exit codes. Exit `0` for `Pass`, `1` for `Fail`, and `2` for parse/check/evaluation/I/O errors.

Keep argument parsing in a testable `parse_cli(argv : ArrayView[String]) -> CliConfig raise` function and keep `async fn main` limited to reading argv, reading files, calling `@moonrules`, printing, and exiting.

- [x] **Step 4: Run CLI smoke tests**

Run using the syntax confirmed by `moon run --help` in Task 1:

```bash
moon run --target native cmd/main check examples/coupon.rule.json
set +e
moon run --target native cmd/main eval examples/coupon.rule.json --data examples/coupon.data.json
MOONRULES_EXIT_CODE="$?"
set -e
test "$MOONRULES_EXIT_CODE" -eq 1
```

Expected: `check` reports success; `eval` prints the coupon Trace and exits `1` for the deliberately ineligible `guest` input.

- [x] **Step 5: Commit the CLI**

```bash
git add moon.mod cmd/main .ai/TASK_STATE.md
git commit -m "feat: add native MoonRules CLI"
```

## Task 13: Examples and user documentation

**Files:**
- Create/Modify: `examples/*.json`
- Create: `README.mbt.md`
- Create: `README.md` symlink or identical entry file, following the generated template convention.
- Create: `README.en.md`
- Create: `docs/DSL.md`
- Create: `docs/API.md`
- Create: `docs/ERRORS.md`

- [x] **Step 1: Complete three runnable examples**

Each example pair must include one passing and one failing data variant. The three scenarios are coupon eligibility, API access by role/environment, and membership eligibility by age/region/status. Every example must use only V1 operators and dot-only data paths.

- [x] **Step 2: Write the Chinese primary README**

Use this exact section order:

```markdown
# MoonRules

MoonBit 原生的可解释、受预算限制的 JSON 业务规则引擎。

## 为什么不是 JSON Schema
## 30 秒示例
## 安装
## 库 API
## CLI
## 可解释 Trace
## 运行前检查
## 安全预算
## V1 操作符
## 示例
## 限制与非目标
## 开发与测试
## 许可证
```

The “为什么不是 JSON Schema” section must state: “JSON Schema validates structure; MoonRules evaluates business decisions and explains them.”

- [x] **Step 3: Write focused reference docs and English README**

`docs/DSL.md` defines every V1 operator, arity, types, and examples. `docs/API.md` documents the four façade functions. `docs/ERRORS.md` documents three-state logic, error precedence, budgets, and partial Trace. `README.en.md` covers installation, one example, DSL overview, and limitations without duplicating the full Chinese reference.

- [x] **Step 4: Check documentation code and examples**

Run:

```bash
moon fmt --check
moon check
moon test
moon run --target native cmd/main eval examples/coupon.rule.json --data examples/coupon.data.json
```

Expected: all code blocks that Moon checks compile; the example runs.

- [x] **Step 5: Commit docs and examples**

```bash
git add README.mbt.md README.md README.en.md docs/DSL.md docs/API.md docs/ERRORS.md examples .ai/TASK_STATE.md
git commit -m "docs: add MoonRules guides and examples"
```

## Task 14: Property tests and final test matrix

**Files:**
- Modify: `moon.pkg`
- Create: `properties_test.mbt`
- Modify: relevant deterministic test files when a property exposes a defect.

- [x] **Step 1: Import QuickCheck only for tests**

QuickCheck is bundled inside the already available `moonbitlang/core` module;
do not run `moon add moonbitlang/core/quickcheck`. Add only this test-scoped
package import to `moon.pkg`:

```moonbit
import {
  "moonbitlang/core/quickcheck",
} for "test"
```

- [x] **Step 2: Add deterministic properties after all ordinary tests pass**

Create `properties_test.mbt` with fixed sample counts:

```moonbit
///|
test "double negation preserves booleans" {
  for value in @quickcheck.samples(100) {
    let expr = Operation(Not, [Operation(Not, [Literal(value)])])
    let report = evaluate_condition(expr, {}, Budget::default())
    inspect(report.decision == if value { Pass } else { Fail }, content="true")
  }
}

///|
test "evaluation is deterministic" {
  let expr = Operation(Equal, [Variable("value"), Literal(42)])
  let data = { "value": 42 }
  let a = evaluate_condition(expr, data, Budget::default())
  let b = evaluate_condition(expr, data, Budget::default())
  inspect(a == b, content="true")
}
```

Add bounded generated tests for `and` false short-circuit, `or` true short-circuit, and every budget returning structured `Indeterminate` rather than panicking.

- [x] **Step 3: Run the complete test matrix**

Run:

```bash
moon fmt --check
moon check --deny-warn
moon test --target native
moon test --target wasm-gc
moon build --target native
moon build --target wasm-gc
```

Expected: all commands pass. If the native-only CLI prevents root `wasm-gc` commands, mark `cmd/main` as native-only in its `moon.pkg` and rerun; do not make the core library native-only.

- [x] **Step 4: Commit property tests**

```bash
git add moon.pkg properties_test.mbt cmd/main/moon.pkg .ai/TASK_STATE.md
git commit -m "test: add deterministic rule properties"
```

## Task 15: CI, release metadata, and GitHub publication

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `CHANGELOG.md`
- Modify: `.ai/TASK_STATE.md`

- [x] **Step 1: Add CI using the official installer**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
          echo "$HOME/.moon/bin" >> "$GITHUB_PATH"
      - name: Verify
        run: |
          moon version --all
          moon fmt --check
          moon check --deny-warn
          moon test --target native
          moon build --target native
          moon test --target wasm-gc
          moon build --target wasm-gc
      - name: CLI smoke test
        run: moon run --target native cmd/main check examples/coupon.rule.json
```

- [x] **Step 2: Add the initial changelog**

Create `CHANGELOG.md` with `0.1.0` entries for DSL parsing, static checking, explainable Trace, deterministic budgets, 15 V1 forms/operators, CLI, examples, and documentation.

- [x] **Step 3: Run local release checks and commit**

Run the same commands as CI, then:

```bash
git add .github/workflows/ci.yml CHANGELOG.md .ai/TASK_STATE.md
git commit -m "ci: validate MoonRules release"
```

- [ ] **Step 4: Create the public GitHub repository only after local identity audit**

Run:

```bash
git log --format='%h %an <%ae>' --reverse
git remote -v
```

Expected: every commit uses the approved public identity and no remote exists yet. If any commit still contains the local-machine email, stop and rewrite local history under supervision before publication.

With explicit confirmation and only while no remote has been shared, rewrite all local commit authors:

```bash
git rebase --root --exec 'git commit --amend --no-edit --reset-author'
git log --format='%h %an <%ae>' --reverse
```

Expected: every commit shows `z2823253773-p <235035337+z2823253773-p@users.noreply.github.com>`.

Create public repository `z2823253773-p/moonrules`, add it as `origin`, and push `main`. Because the local `gh` token was invalid during planning, use the connected GitHub app or complete `gh auth login`; never paste a PAT into chat or a command argument.

- [ ] **Step 5: Verify CI and repository visibility**

Expected: repository is public, `main` is pushed, the CI workflow is green, README renders, and no secret or local-machine email appears in tracked files or commit metadata.

## Task 16: mooncakes.io package and hackathon application

**Files:**
- Create: `docs/submission/moonrules-application.md`
- Modify: `moon.mod` only if packaging reports metadata errors.
- Modify: `.ai/TASK_STATE.md`

- [x] **Step 1: Verify package contents without publishing**

Run:

```bash
moon package --list
moon package
```

Expected: package includes the root library, README files, license, examples, and documentation; it excludes `_build`, credentials, logs, and `.ai/TASK_STATE.md` if the current packager includes it by default.

- [x] **Step 2: Prepare the one-page application source**

Create `docs/submission/moonrules-application.md` with these exact headings:

```markdown
# MoonRules 项目申报书

## 项目定位与生态价值
## 已有基础
## 本次新增范围
## 核心创新
## 技术路线
## 交付、测试与文档
## 开源与许可证
## 时间安排
```

Keep the rendered PDF to one page. State the three innovations as explainable execution, preflight diagnostics, and deterministic execution budgets. Link the public repository and clearly distinguish MoonRules from JSON Schema.

- [ ] **Step 3: Publish only after user confirmation**

Run `moon login` or `moon register` interactively if needed. Immediately before `moon publish`, show the package name, version, included files, and public repository to the user and obtain confirmation. Then run:

```bash
moon publish --frozen
```

Expected: mooncakes.io publishes `z2823253773-p/moonrules@0.1.0` successfully.

- [ ] **Step 4: Produce submission evidence**

Record the public GitHub URL, green CI URL, mooncakes.io package URL, test command output, and demo command in the application source. Generate the one-page PDF, visually inspect it, and verify that no line is clipped.

- [ ] **Step 5: Final completion commit**

Update `.ai/TASK_STATE.md` to state that implementation and release checks are complete, then commit only non-secret project files:

```bash
git add docs/submission .ai/TASK_STATE.md moon.mod
git commit -m "docs: prepare hackathon submission"
git push origin main
```

Expected: public repository, CI, package, application source, and final commit agree on version `0.1.0`.

## Final acceptance checklist

- [ ] `moon fmt --check`, `moon check --deny-warn`, `moon test`, and both native/wasm-gc builds pass.
- [ ] Every V1 operator has success, false, and relevant type/error coverage.
- [ ] Coupon Trace contains independent variable and literal nodes plus short-circuit `Skipped` nodes.
- [ ] Data paths and rule paths are never conflated in code or docs.
- [ ] JSON deep equality matches the approved object, array, number, `null`, and missing-field rules.
- [ ] Every budget returns a structured error and retains bounded partial Trace.
- [ ] Core library has no filesystem, environment, process, or network dependency.
- [ ] CLI exit codes are `0` pass, `1` fail, and `2` error.
- [ ] Three examples run; Chinese and English READMEs render correctly.
- [ ] CI is green and public commit metadata contains only the approved identity.
- [ ] mooncakes.io package and one-page application are ready or published with explicit user confirmation.

## Primary sources used to keep the plan current

- MoonBit installation and beginner tour: <https://docs.moonbitlang.com/en/stable/tutorial/tour.html>
- Current `moon` commands: <https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html>
- Current package configuration: <https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html>
- Package publishing: <https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html>
- Native CLI quickstart: <https://github.com/moonbitlang/moonbit-docs/blob/main/next/tutorial/cli-quickstart.md>
- Official async filesystem API: <https://github.com/moonbitlang/async/tree/main/src/fs>
