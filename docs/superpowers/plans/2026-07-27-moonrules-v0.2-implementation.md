# MoonRules v0.2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship MoonRules v0.2.0 with stable Full/Summary/Off reports, scriptable CLI JSON/stdin support, a local-only static Playground, reproducible engineering evidence, and complete hackathon submission materials by 2026-07-31 evening.

**Architecture:** Preserve the portable root MoonBit engine and perform TraceMode compression only after the existing full evaluation. Keep native I/O in `cmd/main`, expose the same core through a string/JSON foreign-library adapter in `cmd/playground`, and keep all DOM/browser behavior in a Vite + Vanilla TypeScript app under `playground/`. Prefer wasm-gc for the adapter, but use a two-hour browser-interop gate and switch only the adapter build to MoonBit's JavaScript target if the gate fails.

**Tech Stack:** MoonBit `moon 0.1.20260713` / `moonc 0.10.4`, `moonbitlang/core/json`, `moonbitlang/core/quickcheck`, `moonbitlang/core/bench`, `moonbitlang/async`, `moonbitlang/x`, Vite, TypeScript, CodeMirror 6, Vitest, Playwright, GitHub Actions, GitHub Pages, Mooncakes.

---

## Scope and execution rules

- Work from `/Users/henryz/Documents/Moonbit 黑客松`.
- Read `.ai/TASK_STATE.md` and
  `docs/superpowers/specs/2026-07-27-moonrules-v0.2-design.md` before every
  implementation session.
- Use a `codex/...` branch; never implement v0.2 directly on `main`.
- Follow TDD for MoonBit and TypeScript behavior: failing focused test, observed
  failure, minimal implementation, passing focused test, regression suite,
  commit.
- Update `.ai/TASK_STATE.md` after every task.
- Do not change the V1 DSL, three-state semantics, budgets, Full Trace shape, or
  existing public API behavior.
- Do not add full JSONLogic, array-index paths, custom operators, a server, a
  database, accounts, cloud save, a native GUI, Monaco, or JSONL batch mode.
- Do not commit credentials, `.env` files, internal task state to release
  archives, or generated dependency/build directories.
- Stop at a failed verification gate. Record the exact command, tool version,
  error, and chosen response before editing dependent files.
- Public Mooncakes/GitHub Release publication happens only after presenting the
  final audit to the user and receiving confirmation.

## Agent/Claude handoff contract

If Codex quota becomes tight, hand off exactly one not-yet-started task at a
time. The handoff message must include:

```text
Goal: complete Task N from docs/superpowers/plans/2026-07-27-moonrules-v0.2-implementation.md
Allowed files: only the files listed in Task N
Required flow: failing test -> observed failure -> minimal implementation -> focused pass -> full regression
Required commands: copy the commands from Task N exactly
Done means: every Task N checkbox is satisfied and .ai/TASK_STATE.md is updated
Do not: touch other tasks, change DSL/Decision/budget semantics, add dependencies outside the task, publish, push, or paste credentials
Return: changed files, commands/results, remaining risk, and proposed commit message
```

Never let Codex and Claude edit the same files concurrently.

## Locked file map

### Existing MoonBit core

- `model.mbt` — public types; no v0.2 data-model expansion planned.
- `evaluator.mbt` — full evaluation only; remove the V1 mode rejection and call
  the output compressor after constructing a full report.
- `trace_mode.mbt` — new deterministic Full/Summary/Off report transformation.
- `render.mbt` — text/report JSON plus new diagnostic JSON serialization.
- `moonrules.mbt` — public façade; existing functions remain compatible.
- `evaluator_test.mbt`, `render_test.mbt`, `properties_test.mbt` — mode,
  serialization, and invariant coverage.

### Native CLI

- `cmd/main/cli_config.mbt` — command/flag model and pure argument parsing.
- `cmd/main/cli_output.mbt` — pure human/JSON domain-result formatting.
- `cmd/main/main.mbt` — native file/stdin/stdio wiring and exit.
- `cmd/main/main_wbtest.mbt` — pure parser/formatter tests.
- `scripts/test_cli.sh` — black-box stdin/stdout/stderr/exit-code checks.

### Web Adapter

- `cmd/playground/moon.pkg` — foreign-library package and backend exports.
- `cmd/playground/adapter.mbt` — options parsing, response envelope, and two
  exported string functions.
- `cmd/playground/adapter_wbtest.mbt` — black-box adapter responses.
- `scripts/build_playground_engine.sh` — build and copy the selected MoonBit
  artifact into the Vite app.

### Static Playground

- `playground/package.json`, `package-lock.json`, `tsconfig.json`,
  `vite.config.ts`, `index.html` — frontend project.
- `playground/src/contracts.ts` — response/report TypeScript types.
- `playground/src/engine.ts` — selected generated MoonBit module loader.
- `playground/src/examples.ts` — example manifest and fetch logic.
- `playground/src/editor.ts` — CodeMirror wrapper only.
- `playground/src/renderers.ts` — status, Trace, diagnostics, JSON, stats.
- `playground/src/app.ts` — event/state orchestration.
- `playground/src/styles.css` — responsive visual system.
- `playground/public/examples/` — browser-deployable copies of root examples.
- `playground/tests/` — Vitest behavior tests.
- `playground/e2e/` — Playwright smoke test.

### Evidence and release

- `benchmark_*.mbt` — parse/check/evaluate/render benchmark entry files.
- `benchmark_helpers.mbt` — deterministic benchmark fixture generation.
- `.github/workflows/ci.yml` — core, Playground, and package jobs.
- `.github/workflows/pages.yml` — deploy only a built static artifact.
- `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md` — governance.
- `CONTRIBUTING.md`, `SECURITY.md`, `ROADMAP.md`,
  `THIRD_PARTY_NOTICES.md` — maturity documents.
- `docs/ARCHITECTURE.md`, `docs/BENCHMARKS.md`,
  `docs/technical-report.md`, `docs/demo-script.md`,
  `docs/acceptance-checklist.md` — engineering evidence.
- `README.md`, `README.en.md`, `docs/API.md`, `CHANGELOG.md`, `moon.mod` —
  v0.2 user/release contract.
- `docs/submission/moonrules-application.md`,
  `scripts/build_application_pdf.py`, `output/pdf/moonrules-application.pdf` —
  final one-page application.

## Verified and gated API assumptions

Verified from the installed checkout/toolchain:

- Manifests are `moon.mod` and `moon.pkg`.
- `moon test FILE` and `moon bench FILE` are supported.
- stdin is `@stdio.stdin.read_all().text()`.
- `@json.parse` raises and uses `catch`.
- QuickCheck is a test-only core package, not a separate `moon add`.
- Existing builds support native, wasm-gc, and js targets.
- Official MoonBit v0.10.4 docs define `pkgtype(kind: "foreign_library")`,
  `#export_name`, backend `exports`, and JavaScript `format: "esm"`.

Gated, not assumed:

- The exact generated browser artifact path.
- The host loader needed for exported wasm-gc `String` values.
- Whether current Vite/browser versions load that artifact without a custom
  runtime shim.

Task 6 resolves these within two hours. No later task may proceed with an
unrecorded backend choice.

---

### Task 1: Branch, baseline, and governance contract

**Files:**
- Modify: `AGENTS.md`
- Modify: `.ai/TASK_STATE.md`
- No feature source changes.

- [ ] **Step 1: Create the implementation branch**

Run:

```bash
git switch -c codex/v0.2-core
git status --short --branch
```

Expected: current branch is `codex/v0.2-core`; worktree contains only the
already-approved plan commit state.

- [ ] **Step 2: Verify the locked baseline**

Run:

```bash
moon version --all
node --version
npm --version
gh auth status
moon fmt --check
moon check --deny-warn
moon test --target native
moon test --target wasm-gc
moon build --target native
moon build --target wasm-gc
```

Expected: MoonBit versions match `.ai/TASK_STATE.md`; 63 native and 60 wasm-gc
tests pass; both builds pass. Record different test totals without treating a
larger total as failure.

- [ ] **Step 3: Amend the agent contract for the approved static Playground**

Replace the final prohibition sentence in `AGENTS.md` with:

```markdown
Do not add full JSONLogic compatibility, array-index paths, a server, a
database, a native desktop GUI, or credential files. The approved v0.2 static
local-only Web Playground is the only GUI exception; browser side effects stay
under `playground/`.
```

Expected: the core-side-effect rule remains unchanged.

- [ ] **Step 4: Record the active milestone**

Set `.ai/TASK_STATE.md` current milestone to:

```markdown
## Current milestone

MoonRules v0.2 implementation is active on `codex/v0.2-core`.
Task 1 baseline passed. Next: Task 2 deterministic TraceMode compression.
No public v0.2 release action is authorized yet.
```

- [ ] **Step 5: Create GitHub planning records**

Run:

```bash
gh api repos/z2823253773-p/moonrules/milestones \
  -f title='v0.2.0' \
  -f description='Playground, Trace modes, scriptable CLI, and release evidence' \
  -f due_on='2026-07-31T15:59:59Z'
gh issue create --title 'Implement Summary and Off Trace modes' --body 'Preserve V1 decisions and Full Trace; add deterministic post-evaluation compression and tests.'
gh issue create --title 'Add CLI JSON and stdin support' --body 'Add --json, stdin via -, help/version, stable exit codes, and black-box tests.'
gh issue create --title 'Build static MoonRules Playground' --body 'Add the MoonBit Web Adapter, Vite UI, examples, Trace/diagnostics/stats, and Pages deployment.'
gh issue create --title 'Prepare v0.2 evidence and release' --body 'Add benchmarks, maturity docs, technical report, application PDF, demo script, and release audit.'
```

Expected: one open milestone and four open Issues; copy their URLs into
`.ai/TASK_STATE.md`.

- [ ] **Step 6: Commit**

```bash
git add AGENTS.md .ai/TASK_STATE.md
git commit -m "chore: start MoonRules v0.2 milestone"
```

---

### Task 2: Deterministic Summary and Off Trace modes

**Files:**
- Create: `trace_mode.mbt`
- Modify: `evaluator.mbt`
- Modify: `evaluator_test.mbt`
- Modify: `properties_test.mbt`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Replace the V1 rejection test with mode-shape tests**

Replace `test "V1 rejects unimplemented trace modes explicitly"` in
`evaluator_test.mbt` with:

```moonbit
///|
test "summary removes ordinary value leaves but keeps decisions" {
  let expr = Expr::Operation(Operator::GreaterOrEqual, [
    Expr::Variable("user.age"),
    Expr::Literal(Json::number(18.0)),
  ])
  let data = @json.parse("{\"user\":{\"age\":20}}")
  let full = evaluate_condition(expr, data, Budget::default(), trace_mode=Full)
  let summary = evaluate_condition(
    expr,
    data,
    Budget::default(),
    trace_mode=Summary,
  )
  @test.assert_eq(summary.decision, full.decision)
  @test.assert_eq(summary.trace.children.length(), 0)
  @test.assert_eq(summary.trace.resolved_inputs.length(), 2)
}

///|
test "summary keeps error and skipped nodes" {
  let expr = Expr::Operation(Operator::And, [
    Expr::Variable("missing"),
    Expr::Literal(Json::boolean(false)),
    Expr::Variable("never"),
  ])
  let report = evaluate_condition(
    expr,
    Json::empty_object(),
    Budget::default(),
    trace_mode=Summary,
  )
  @test.assert_eq(report.decision, Decision::Fail)
  @test.assert_eq(report.trace.children[0].status, TraceStatus::Error)
  @test.assert_eq(report.trace.children[1].status, TraceStatus::Skipped)
}

///|
test "off returns one root and preserves report semantics" {
  let expr = Expr::Operation(Operator::Equal, [
    Expr::Literal(Json::number(1.0)),
    Expr::Literal(Json::number(1.0)),
  ])
  let full = evaluate_condition(expr, Json::empty_object(), Budget::default())
  let off = evaluate_condition(
    expr,
    Json::empty_object(),
    Budget::default(),
    trace_mode=Off,
  )
  @test.assert_eq(off.decision, full.decision)
  @test.assert_eq(off.stats, full.stats)
  @test.assert_eq(off.trace.children.length(), 0)
  @test.assert_eq(off.trace.resolved_inputs.length(), 0)
}
```

- [ ] **Step 2: Run the focused test and observe failure**

Run:

```bash
moon test evaluator_test.mbt --target native
```

Expected: the three new tests fail because Summary/Off still produce
`UnsupportedTraceMode`.

- [ ] **Step 3: Add the deterministic compressor**

Create `trace_mode.mbt`:

```moonbit
///|
fn is_ordinary_value_leaf(node : TraceNode) -> Bool {
  node.status == TraceStatus::Value &&
  node.children.length() == 0 &&
  (node.operator == "literal" || node.operator.has_prefix("var("))
}

///|
fn summarize_trace(node : TraceNode) -> TraceNode {
  let children : Array[TraceNode] = []
  for child in node.children {
    if !is_ordinary_value_leaf(child) {
      children.push(summarize_trace(child))
    }
  }
  {
    rule_path: node.rule_path,
    operator: node.operator,
    status: node.status,
    resolved_inputs: node.resolved_inputs,
    result: node.result,
    message: node.message,
    children,
  }
}

///|
fn disable_trace(node : TraceNode) -> TraceNode {
  {
    rule_path: node.rule_path,
    operator: node.operator,
    status: node.status,
    resolved_inputs: [],
    result: node.result,
    message: node.message,
    children: [],
  }
}

///|
fn apply_trace_mode(
  report : EvaluationReport,
  trace_mode : TraceMode,
) -> EvaluationReport {
  let trace = match trace_mode {
    TraceMode::Full => report.trace
    TraceMode::Summary => summarize_trace(report.trace)
    TraceMode::Off => disable_trace(report.trace)
  }
  { decision: report.decision, trace, stats: report.stats }
}
```

- [ ] **Step 4: Apply compression after full evaluation**

In `evaluator.mbt`, delete the early `trace_mode != Full` branch. Apply the mode
to both terminal budget reports and the normal full report:

```moonbit
match first_budget_excess(budget) {
  Some(error) =>
    return apply_trace_mode(terminal_error_report(error), trace_mode)
  None => ()
}
```

At the end of `evaluate`, replace the report literal return with:

```moonbit
let full_report : EvaluationReport = {
  decision,
  trace,
  stats: {
    steps_executed: context.steps,
    nodes_evaluated: context.nodes,
    max_depth_reached: context.max_depth,
    trace_nodes_emitted: context.trace_nodes,
  },
}
apply_trace_mode(full_report, trace_mode)
```

Do not delete `UnsupportedTraceMode` from the public enum in v0.2; removing a
public variant would be a compatibility break.
Delete the now-unused private `trace_mode_name` helper so
`moon check --deny-warn` remains clean.

- [ ] **Step 5: Add mode properties**

Append to `properties_test.mbt`:

```moonbit
///|
fn trace_node_count(node : TraceNode) -> Int {
  let mut count = 1
  for child in node.children {
    count += trace_node_count(child)
  }
  count
}

///|
test "property: trace modes preserve decisions and reduce output" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let expr = Expr::Operation(Operator::And, [
      Expr::Literal(Json::boolean(value)),
      Expr::Literal(Json::boolean(true)),
    ])
    let full = evaluate_condition(
      expr,
      Json::empty_object(),
      Budget::default(),
      trace_mode=Full,
    )
    let summary = evaluate_condition(
      expr,
      Json::empty_object(),
      Budget::default(),
      trace_mode=Summary,
    )
    let off = evaluate_condition(
      expr,
      Json::empty_object(),
      Budget::default(),
      trace_mode=Off,
    )
    @test.assert_eq(full.decision, summary.decision)
    @test.assert_eq(full.decision, off.decision)
    assert_true(trace_node_count(summary.trace) <= trace_node_count(full.trace))
    @test.assert_eq(trace_node_count(off.trace), 1)
  }
}
```

- [ ] **Step 6: Verify focused and full regression**

Run:

```bash
moon fmt
moon test evaluator_test.mbt --target native
moon test properties_test.mbt --target native
moon fmt --check
moon check --deny-warn
moon test --target native
moon test --target wasm-gc
```

Expected: new tests pass; existing Full Trace golden output is unchanged.

- [ ] **Step 7: Update state and commit**

Set next task to diagnostics JSON, then:

```bash
git add trace_mode.mbt evaluator.mbt evaluator_test.mbt properties_test.mbt .ai/TASK_STATE.md
git commit -m "feat: implement summary and off trace modes"
```

---

### Task 3: Stable diagnostic JSON serialization

**Files:**
- Modify: `render.mbt`
- Modify: `render_test.mbt`
- Modify: `properties_test.mbt`
- Modify: `docs/API.md`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Write failing serialization tests**

Append to `render_test.mbt`:

```moonbit
///|
test "diagnostics JSON has stable public fields" {
  let diagnostic : Diagnostic = {
    code: "E_ARITY",
    severity: Error,
    rule_path: "condition.and",
    message: "operator and expects at least 1 argument",
    suggestion: "provide at least 1 argument",
  }
  let json = diagnostics_to_json([diagnostic])
  @test.assert_eq(
    json.stringify(),
    "[{\"code\":\"E_ARITY\",\"severity\":\"error\",\"rule_path\":\"condition.and\",\"message\":\"operator and expects at least 1 argument\",\"suggestion\":\"provide at least 1 argument\"}]",
  )
}

///|
test "empty diagnostics serialize as an array" {
  @test.assert_eq(diagnostics_to_json([]).stringify(), "[]")
}
```

- [ ] **Step 2: Confirm the missing API**

Run:

```bash
moon test render_test.mbt --target native
```

Expected: FAIL because `diagnostics_to_json` is not defined.

- [ ] **Step 3: Implement the public serializer**

Add to `render.mbt`:

```moonbit
///|
fn diagnostic_severity_json(severity : DiagnosticSeverity) -> String {
  match severity {
    DiagnosticSeverity::Error => "error"
    DiagnosticSeverity::Warning => "warning"
  }
}

///|
fn diagnostic_to_json(diagnostic : Diagnostic) -> Json {
  Json::object({
    "code": Json::string(diagnostic.code),
    "severity": Json::string(
      diagnostic_severity_json(diagnostic.severity),
    ),
    "rule_path": Json::string(diagnostic.rule_path),
    "message": Json::string(diagnostic.message),
    "suggestion": Json::string(diagnostic.suggestion),
  })
}

///|
pub fn diagnostics_to_json(diagnostics : Array[Diagnostic]) -> Json {
  Json::array(diagnostics.map(diagnostic_to_json))
}
```

- [ ] **Step 4: Add the stringify/parse property**

Append to `properties_test.mbt`:

```moonbit
///|
test "property: report and diagnostic JSON round-trip through text" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let report = evaluate_condition(
      Expr::Literal(Json::boolean(value)),
      Json::empty_object(),
      Budget::default(),
    )
    let report_text = report_to_json(report).stringify()
    @test.assert_eq(@json.parse(report_text), report_to_json(report))
    let diagnostics = check_expr(
      Expr::Operation(Operator::And, []),
      Budget::default(),
    )
    let diagnostic_text = diagnostics_to_json(diagnostics).stringify()
    @test.assert_eq(
      @json.parse(diagnostic_text),
      diagnostics_to_json(diagnostics),
    )
  }
}
```

- [ ] **Step 5: Document and verify**

Add to `docs/API.md` under structured output:

```markdown
`diagnostics_to_json(diagnostics)` serializes every diagnostic as
`code`, `severity`, `rule_path`, `message`, and `suggestion`. Field names are
part of the v0.2 public JSON contract.
```

Run:

```bash
moon fmt
moon test render_test.mbt --target native
moon test properties_test.mbt --target native
moon fmt --check
moon check --deny-warn
moon test --target native
moon test --target wasm-gc
```

Expected: all tests pass and generated public interface includes
`diagnostics_to_json`.

- [ ] **Step 6: Update state and commit**

```bash
git add render.mbt render_test.mbt properties_test.mbt docs/API.md .ai/TASK_STATE.md
git commit -m "feat: serialize diagnostics as stable JSON"
```

- [ ] **Step 7: Merge the core phase**

```bash
git push -u origin codex/v0.2-core
gh pr create \
  --title "feat: implement MoonRules v0.2 core output modes" \
  --body "Implements deterministic Full/Summary/Off output shapes and stable diagnostic JSON. Preserves V1 decisions, budgets, and Full Trace. Verification: moon fmt --check; moon check --deny-warn; native and wasm-gc tests."
gh pr checks --watch
```

The PR body must contain the Full regression and mode-invariant results. Merge
only after green checks, then create `codex/v0.2-cli` from updated `main`.

---

### Task 4: Pure CLI configuration and output contract

**Files:**
- Create: `cmd/main/cli_config.mbt`
- Create: `cmd/main/cli_output.mbt`
- Modify: `cmd/main/main.mbt`
- Modify: `cmd/main/main_wbtest.mbt`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 0: Start the CLI phase branch**

```bash
git switch main
git pull --ff-only
git switch -c codex/v0.2-cli
```

- [ ] **Step 1: Write the new parser tests**

Replace the existing tests in `cmd/main/main_wbtest.mbt` with:

```moonbit
///|
test "parse check human and JSON commands" {
  @test.assert_eq(
    parse_cli(["check", "rule.json"]),
    Ok(CliConfig::Check("rule.json", OutputMode::Human)),
  )
  @test.assert_eq(
    parse_cli(["check", "rule.json", "--json"]),
    Ok(CliConfig::Check("rule.json", OutputMode::Json)),
  )
}

///|
test "parse eval file and stdin commands" {
  @test.assert_eq(
    parse_cli(["eval", "rule.json", "--data", "data.json", "--json"]),
    Ok(CliConfig::Eval("rule.json", "data.json", OutputMode::Json)),
  )
  @test.assert_eq(
    parse_cli(["eval", "-", "--data", "data.json"]),
    Ok(CliConfig::Eval("-", "data.json", OutputMode::Human)),
  )
}

///|
test "parse help and version" {
  @test.assert_eq(parse_cli(["--help"]), Ok(CliConfig::Help))
  @test.assert_eq(parse_cli(["--version"]), Ok(CliConfig::Version))
}

///|
test "reject ambiguous dual stdin and bad commands" {
  @test.assert_eq(
    parse_cli(["eval", "-", "--data", "-"]),
    Err(CliParseError::DualStdin),
  )
  @test.assert_eq(
    parse_cli(["eval", "rule.json"]),
    Err(CliParseError::Usage),
  )
}
```

- [ ] **Step 2: Verify failure**

Run:

```bash
moon test cmd/main/main_wbtest.mbt --target native
```

Expected: FAIL because the new enums and variants do not exist.

- [ ] **Step 3: Move pure parsing into `cli_config.mbt`**

Create:

```moonbit
///|
pub(all) enum OutputMode {
  Human
  Json
} derive(Eq, Debug)

///|
pub(all) enum CliConfig {
  Check(String, OutputMode)
  Eval(String, String, OutputMode)
  Help
  Version
} derive(Eq, Debug)

///|
pub(all) enum CliParseError {
  Usage
  DualStdin
} derive(Eq, Debug)

///|
fn mode_from_suffix(arguments : ArrayView[String]) -> OutputMode {
  if arguments.length() > 0 &&
    arguments[arguments.length() - 1] == "--json" {
    OutputMode::Json
  } else {
    OutputMode::Human
  }
}

///|
pub fn parse_cli(
  arguments : ArrayView[String],
) -> Result[CliConfig, CliParseError] {
  let mode = mode_from_suffix(arguments)
  match arguments {
    ["check", rule_path] =>
      Ok(CliConfig::Check(rule_path, OutputMode::Human))
    ["check", rule_path, "--json"] =>
      Ok(CliConfig::Check(rule_path, OutputMode::Json))
    ["eval", rule_path, "--data", data_path] =>
      if rule_path == "-" && data_path == "-" {
        Err(CliParseError::DualStdin)
      } else {
        Ok(CliConfig::Eval(rule_path, data_path, OutputMode::Human))
      }
    ["eval", rule_path, "--data", data_path, "--json"] =>
      if rule_path == "-" && data_path == "-" {
        Err(CliParseError::DualStdin)
      } else {
        Ok(CliConfig::Eval(rule_path, data_path, mode))
      }
    ["--help"] | ["-h"] => Ok(CliConfig::Help)
    ["--version"] | ["-V"] => Ok(CliConfig::Version)
    _ => Err(CliParseError::Usage)
  }
}

///|
fn usage() -> String {
  "Usage:\n  moonrules check <rule.json|-> [--json]\n  moonrules eval <rule.json|-> --data <data.json|-> [--json]\n  moonrules --help\n  moonrules --version\n"
}
```

Delete the old enum/parser/usage definitions from `main.mbt`.

- [ ] **Step 4: Create pure JSON envelope helpers**

Create `cmd/main/cli_output.mbt`:

```moonbit
///|
fn cli_error_json(code : String, message : String) -> String {
  Json::object({
    "ok": Json::boolean(false),
    "code": Json::string(code),
    "message": Json::string(message),
  }).stringify()
}

///|
fn cli_check_json(diagnostics : Array[@moonrules.Diagnostic]) -> String {
  Json::object({
    "ok": Json::boolean(diagnostics.length() == 0),
    "kind": Json::string("check"),
    "diagnostics": @moonrules.diagnostics_to_json(diagnostics),
  }).stringify()
}

///|
fn cli_report_json(report : @moonrules.EvaluationReport) -> String {
  Json::object({
    "ok": Json::boolean(true),
    "kind": Json::string("evaluation"),
    "report": @moonrules.report_to_json(report),
  }).stringify()
}
```

Add `"moonbitlang/core/json"` to `cmd/main/moon.pkg`.
Also add the test-only import used by `main_wbtest.mbt`:

```moonbit
import {
  "moonbitlang/core/test",
} for "test"
```

- [ ] **Step 5: Add formatter tests and run**

Append:

```moonbit
///|
test "CLI JSON errors are machine-readable" {
  @test.assert_eq(
    @json.parse(cli_error_json("E_USAGE", "bad arguments")),
    @json.parse(
      "{\"ok\":false,\"code\":\"E_USAGE\",\"message\":\"bad arguments\"}",
    ),
  )
}
```

Run:

```bash
moon fmt
moon test cmd/main/main_wbtest.mbt --target native
moon check --target native --deny-warn
```

Expected: parser and formatter tests pass.

- [ ] **Step 6: Update state and commit**

```bash
git add cmd/main/cli_config.mbt cmd/main/cli_output.mbt cmd/main/main.mbt cmd/main/main_wbtest.mbt cmd/main/moon.pkg .ai/TASK_STATE.md
git commit -m "refactor: define CLI v0.2 contracts"
```

---

### Task 5: CLI stdin, JSON execution, and black-box exit tests

**Files:**
- Modify: `cmd/main/main.mbt`
- Create: `scripts/test_cli.sh`
- Modify: `.github/workflows/ci.yml`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Add the source-reader API probe**

Replace `read_text` with:

```moonbit
///|
async fn read_source(path : String) -> Result[String, String] {
  if path == "-" {
    Ok(@stdio.stdin.read_all().text()) catch {
      error => Err("failed to read stdin: \{error}")
    }
  } else {
    Ok(@fs.read_file(path).text()) catch {
      error => Err("failed to read \{path}: \{error}")
    }
  }
}
```

Run:

```bash
moon check cmd/main --target native --deny-warn
```

Expected: PASS, confirming the checked-in async version supports
`stdin.read_all().text()`. If it fails, inspect
`.mooncakes/moonbitlang/async/src/stdio/stdio.mbt` and
`.mooncakes/moonbitlang/async/src/io/reader.mbt`, then change only this helper.

- [ ] **Step 2: Implement mode-aware check output**

Use this shape in `run_check`:

```moonbit
async fn run_check(rule_path : String, mode : OutputMode) -> Int {
  let rule_source = match read_source(rule_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  let rule = match @moonrules.parse(rule_source) {
    Ok(value) => value
    Err(error) => {
      let message = "rule parse failed: \{error.message()}"
      if mode == OutputMode::Json {
        @stdio.stdout.write(
          "\{cli_error_json("E_RULE_PARSE", message)}\n",
        )
      } else {
        @stdio.stderr.write("\{message}\n")
      }
      return 2
    }
  }
  let diagnostics = @moonrules.check(rule)
  if mode == OutputMode::Json {
    @stdio.stdout.write("\{cli_check_json(diagnostics)}\n")
  } else if diagnostics.length() == 0 {
    @stdio.stdout.write("MoonRules check: OK\n")
  } else {
    @stdio.stderr.write(diagnostics_text(diagnostics))
  }
  if diagnostics.length() == 0 { 0 } else { 2 }
}
```

- [ ] **Step 3: Implement mode-aware evaluation**

Use:

```moonbit
async fn run_eval(
  rule_path : String,
  data_path : String,
  mode : OutputMode,
) -> Int {
  let rule_source = match read_source(rule_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  let data_source = match read_source(data_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  match @moonrules.evaluate_json(rule_source, data_source) {
    Err(message) => {
      if mode == OutputMode::Json {
        @stdio.stdout.write(
          "\{cli_error_json("E_EVALUATE_INPUT", message)}\n",
        )
      } else {
        @stdio.stderr.write("\{message}\n")
      }
      2
    }
    Ok(report) => {
      if mode == OutputMode::Json {
        @stdio.stdout.write("\{cli_report_json(report)}\n")
      } else {
        @stdio.stdout.write(
          "\{@moonrules.render_report(report, @moonrules.Budget::default())}\n",
        )
      }
      report.decision.exit_code()
    }
  }
}
```

Update `main` dispatch:

```moonbit
let code = match parse_cli(arguments[1:]) {
  Err(CliParseError::DualStdin) => {
    @stdio.stderr.write("rule and data cannot both use stdin\n")
    2
  }
  Err(CliParseError::Usage) => {
    @stdio.stderr.write(usage())
    2
  }
  Ok(CliConfig::Help) => {
    @stdio.stdout.write(usage())
    0
  }
  Ok(CliConfig::Version) => {
    @stdio.stdout.write("moonrules 0.2.0\n")
    0
  }
  Ok(CliConfig::Check(rule_path, mode)) => run_check(rule_path, mode)
  Ok(CliConfig::Eval(rule_path, data_path, mode)) =>
    run_eval(rule_path, data_path, mode)
}
```

- [ ] **Step 4: Add black-box CLI verification**

Create executable `scripts/test_cli.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

pass_json="$(moon run --target native cmd/main eval \
  examples/coupon.rule.json \
  --data examples/coupon.data.pass.json \
  --json)"
node -e 'const x=JSON.parse(process.argv[1]); if(x.report.decision.status!=="pass") process.exit(1)' "$pass_json"

set +e
fail_json="$(moon run --target native cmd/main eval \
  examples/coupon.rule.json \
  --data examples/coupon.data.json \
  --json)"
fail_code=$?
set -e
test "$fail_code" -eq 1
node -e 'const x=JSON.parse(process.argv[1]); if(x.report.decision.status!=="fail") process.exit(1)' "$fail_json"

stdin_json="$(moon run --target native cmd/main check - --json \
  < examples/coupon.rule.json)"
node -e 'const x=JSON.parse(process.argv[1]); if(x.ok!==true) process.exit(1)' "$stdin_json"

set +e
cli_tmp_dir="$(mktemp -d /tmp/moonrules-cli.XXXXXX)"
moon run --target native cmd/main eval - --data - \
  < examples/coupon.rule.json >"$cli_tmp_dir/dual-stdin.out" 2>"$cli_tmp_dir/dual-stdin.err"
dual_code=$?
set -e
test "$dual_code" -eq 2
grep -q "cannot both use stdin" "$cli_tmp_dir/dual-stdin.err"

moon run --target native cmd/main --version | grep -q "moonrules 0.2.0"
moon run --target native cmd/main --help | grep -q "moonrules check"
```

Run:

```bash
chmod +x scripts/test_cli.sh
scripts/test_cli.sh
```

Expected: exit `0`; JSON parses; Fail exits `1`; dual stdin exits `2`.

- [ ] **Step 5: Add the CLI script to CI and run regression**

Add after core verification in `.github/workflows/ci.yml`:

```yaml
      - name: CLI contract
        run: scripts/test_cli.sh
```

Run:

```bash
moon fmt
moon fmt --check
moon check --deny-warn
moon test --target native
moon test --target wasm-gc
moon build --target native
scripts/test_cli.sh
```

- [ ] **Step 6: Update state and commit**

```bash
git add cmd/main/main.mbt scripts/test_cli.sh .github/workflows/ci.yml .ai/TASK_STATE.md
git commit -m "feat: add CLI JSON and stdin support"
```

- [ ] **Step 7: Merge the CLI phase**

Push `codex/v0.2-cli`, open a PR whose evidence includes all black-box exit-code
checks, wait for green CI, merge, and create `codex/v0.2-playground` from the
updated `main`.

---

### Task 6: Web Adapter and the two-hour backend gate

**Files:**
- Create: `cmd/playground/moon.pkg`
- Create: `cmd/playground/adapter.mbt`
- Create: `cmd/playground/adapter_wbtest.mbt`
- Create: `scripts/build_playground_engine.sh`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 0: Confirm the Playground phase branch**

Run `git status --short --branch`. Expected:
`## codex/v0.2-playground` with a clean worktree.

- [ ] **Step 1: Write Adapter response tests**

Create `cmd/playground/adapter_wbtest.mbt`:

```moonbit
///|
test "check adapter returns diagnostics envelope" {
  let response = @json.parse(
    check_json(
      "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"and\":[]}}",
      "{}",
    ),
  )
  guard response is Object(fields) else { fail("response must be object") }
  @test.assert_eq(fields.get("ok"), Some(Json::boolean(true)))
  @test.assert_eq(fields.get("kind"), Some(Json::string("check")))
}

///|
test "evaluate adapter preserves fail as a successful evaluation" {
  let response = @json.parse(
    evaluate_json(
      "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"==\":[1,2]}}",
      "{}",
      "{\"trace_mode\":\"off\"}",
    ),
  )
  guard response is Object(fields) else { fail("response must be object") }
  @test.assert_eq(fields.get("ok"), Some(Json::boolean(true)))
  @test.assert_eq(fields.get("kind"), Some(Json::string("evaluation")))
  guard fields.get("report") is Some(Object(report)) else {
    fail("report must be object")
  }
  guard report.get("trace") is Some(Object(trace)) else {
    fail("trace must be object")
  }
  @test.assert_eq(trace.get("children"), Some(Json::array([])))
}

///|
test "adapter rejects invalid options as input_error" {
  let response = @json.parse(check_json("{}", "{\"trace_mode\":\"wide\"}"))
  guard response is Object(fields) else { fail("response must be object") }
  @test.assert_eq(fields.get("ok"), Some(Json::boolean(false)))
  @test.assert_eq(fields.get("kind"), Some(Json::string("input_error")))
}
```

- [ ] **Step 2: Create the foreign-library package**

Create `cmd/playground/moon.pkg`:

```moonbit
import {
  "z2823253773-p/moonrules",
  "moonbitlang/core/json",
}

pkgtype(kind: "foreign_library")

options(
  link: {
    "wasm-gc": {
      "exports": [ "check_json", "evaluate_json" ],
    },
    "js": {
      "exports": [ "check_json", "evaluate_json" ],
      "format": "esm",
    },
  },
)
```

- [ ] **Step 3: Implement the minimal complete Adapter**

Create `cmd/playground/adapter.mbt` with these helpers and exports:

```moonbit
///|
fn adapter_error(code : String, message : String) -> String {
  Json::object({
    "ok": Json::boolean(false),
    "kind": Json::string("input_error"),
    "report": Json::null(),
    "diagnostics": Json::array([
      Json::object({
        "code": Json::string(code),
        "severity": Json::string("error"),
        "rule_path": Json::string("$"),
        "message": Json::string(message),
        "suggestion": Json::string("correct the input and try again"),
      }),
    ]),
  }).stringify()
}

///|
fn parse_trace_mode(options_source : String) -> Result[@moonrules.TraceMode, String] {
  let options = @json.parse(options_source) catch {
    error => return Err("invalid options JSON: \{error}")
  }
  guard options is Object(fields) else {
    return Err("options must be a JSON object")
  }
  match fields.get("trace_mode") {
    None => Ok(@moonrules.TraceMode::Full)
    Some(String("full")) => Ok(@moonrules.TraceMode::Full)
    Some(String("summary")) => Ok(@moonrules.TraceMode::Summary)
    Some(String("off")) => Ok(@moonrules.TraceMode::Off)
    Some(_) => Err("trace_mode must be full, summary, or off")
  }
}

///|
fn check_response(
  diagnostics : Array[@moonrules.Diagnostic],
) -> String {
  Json::object({
    "ok": Json::boolean(true),
    "kind": Json::string("check"),
    "report": Json::null(),
    "diagnostics": @moonrules.diagnostics_to_json(diagnostics),
  }).stringify()
}

///|
#export_name("check_json")
pub fn check_json(rule_source : String, options_source : String) -> String {
  match parse_trace_mode(options_source) {
    Err(message) => adapter_error("E_OPTIONS", message)
    Ok(_) =>
      match @moonrules.parse(rule_source) {
        Err(error) => adapter_error("E_RULE_PARSE", error.message())
        Ok(rule) => check_response(@moonrules.check(rule))
      }
  }
}

///|
#export_name("evaluate_json")
pub fn evaluate_json(
  rule_source : String,
  data_source : String,
  options_source : String,
) -> String {
  let trace_mode = match parse_trace_mode(options_source) {
    Err(message) => return adapter_error("E_OPTIONS", message)
    Ok(value) => value
  }
  let rule = match @moonrules.parse(rule_source) {
    Err(error) => return adapter_error("E_RULE_PARSE", error.message())
    Ok(value) => value
  }
  let diagnostics = @moonrules.check(rule)
  if diagnostics.length() > 0 {
    return check_response(diagnostics)
  }
  let data = @json.parse(data_source) catch {
    error => return adapter_error("E_DATA_JSON", "\{error}")
  }
  let report = @moonrules.evaluate(
    rule,
    data,
    @moonrules.Budget::default(),
    trace_mode~,
  )
  Json::object({
    "ok": Json::boolean(true),
    "kind": Json::string("evaluation"),
    "report": @moonrules.report_to_json(report),
    "diagnostics": Json::array([]),
  }).stringify()
}
```

The initial probe uses only `trace_mode`; Step 5 adds the complete approved
budget contract after string export compiles.

- [ ] **Step 4: Run unit/build probes**

Run:

```bash
moon fmt
moon test cmd/playground --target wasm-gc
moon build cmd/playground --target wasm-gc --release
moon build cmd/playground --target js --release
find _build -path '*cmd/playground*' -type f | sort
```

Expected: tests and both builds pass; record the exact `.wasm` and `.js`
artifact paths in `.ai/TASK_STATE.md`.

- [ ] **Step 5: Complete options and lower-only budget parsing**

Replace `parse_trace_mode` with an `AdapterOptions` parser. Use the external
field names from the design and map them to the existing `Budget` fields:

```moonbit
priv struct AdapterOptions {
  trace_mode : @moonrules.TraceMode
  budget : @moonrules.Budget
}

///|
fn option_int(
  fields : Map[String, Json],
  name : String,
  default : Int,
) -> Result[Int, String] {
  match fields.get(name) {
    None => Ok(default)
    Some(Number(value, ..)) => {
      let integer = value.to_int()
      if integer <= 0 || integer.to_double() != value {
        Err("budget.\{name} must be a positive integer")
      } else {
        Ok(integer)
      }
    }
    Some(_) => Err("budget.\{name} must be a positive integer")
  }
}

///|
fn parse_options(source : String) -> Result[AdapterOptions, String] {
  let json = @json.parse(source) catch {
    error => return Err("invalid options JSON: \{error}")
  }
  guard json is Object(fields) else {
    return Err("options must be a JSON object")
  }
  for key, _ in fields {
    if key != "trace_mode" && key != "budget" {
      return Err("unknown option: \{key}")
    }
  }
  let trace_mode = match fields.get("trace_mode") {
    None | Some(String("full")) => @moonrules.TraceMode::Full
    Some(String("summary")) => @moonrules.TraceMode::Summary
    Some(String("off")) => @moonrules.TraceMode::Off
    Some(_) => return Err("trace_mode must be full, summary, or off")
  }
  let defaults = @moonrules.Budget::default()
  let budget = match fields.get("budget") {
    None => defaults
    Some(Object(budget_fields)) => {
      for key, _ in budget_fields {
        if key != "max_depth" &&
          key != "max_nodes" &&
          key != "max_steps" &&
          key != "max_trace_nodes" &&
          key != "max_value_preview" {
          return Err("unknown budget option: \{key}")
        }
      }
      let max_depth = match
        option_int(budget_fields, "max_depth", defaults.max_depth) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let max_rule_nodes = match
        option_int(budget_fields, "max_nodes", defaults.max_rule_nodes) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let max_steps = match
        option_int(budget_fields, "max_steps", defaults.max_steps) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let max_trace_nodes = match
        option_int(
          budget_fields,
          "max_trace_nodes",
          defaults.max_trace_nodes,
        ) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let max_preview_chars = match
        option_int(
          budget_fields,
          "max_value_preview",
          defaults.max_preview_chars,
        ) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      {
        max_depth,
        max_rule_nodes,
        max_steps,
        max_trace_nodes,
        max_preview_chars,
      }
    }
    Some(_) => return Err("budget must be a JSON object")
  }
  let diagnostics = @moonrules.validate_budget(budget)
  if diagnostics.length() > 0 {
    return Err(diagnostics[0].message)
  }
  Ok({ trace_mode, budget })
}
```

Add tests for an over-ceiling value and an unknown field. In both exports,
replace the earlier `parse_trace_mode` match with:

```moonbit
let options = match parse_options(options_source) {
  Ok(value) => value
  Err(message) => return adapter_error("E_OPTIONS", message)
}
```

Call `@moonrules.check(rule, budget=options.budget)` and
`@moonrules.evaluate(rule, data, options.budget,
trace_mode=options.trace_mode)`.

- [ ] **Step 6: Create a deterministic artifact-copy script**

Create `scripts/build_playground_engine.sh` initially for wasm-gc:

```bash
#!/usr/bin/env bash
set -euo pipefail

moon build cmd/playground --target wasm-gc --release
artifact="$(find _build/wasm-gc/release -path '*cmd/playground*' -type f -name '*.wasm' -print -quit)"
test -n "$artifact"
mkdir -p playground/public/engine
cp "$artifact" playground/public/engine/moonrules.wasm
```

If the recorded output root differs, replace only the `find` root with the
observed path. Run:

```bash
chmod +x scripts/build_playground_engine.sh
scripts/build_playground_engine.sh
test -s playground/public/engine/moonrules.wasm
```

- [ ] **Step 7: Execute the two-hour browser gate**

Start a timer and use the smallest HTML/JavaScript host possible. The gate
passes only if a browser calls exported `check_json` with JavaScript strings
and parses the returned string.

If it passes, record:

```text
PLAYGROUND_BACKEND=wasm-gc
Artifact path:
Host imports/builtins:
Probe command:
Probe result:
```

If it does not pass within two hours, replace the build script with:

```bash
#!/usr/bin/env bash
set -euo pipefail

moon build cmd/playground --target js --release
artifact="$(find _build/js/release -path '*cmd/playground*' -type f -name '*.js' -print -quit)"
test -n "$artifact"
mkdir -p playground/src/generated
cp "$artifact" playground/src/generated/moonrules.js
```

Then record:

```text
PLAYGROUND_BACKEND=js
wasm-gc stop reason:
JS artifact path:
JS import smoke result:
```

This fallback is a planned outcome, not a failed project.

- [ ] **Step 8: Verify, update state, and commit**

Run the selected script plus:

```bash
moon fmt --check
moon check --deny-warn
moon test cmd/playground --target wasm-gc
```

Then:

```bash
git add cmd/playground scripts/build_playground_engine.sh .ai/TASK_STATE.md
git commit -m "feat: expose MoonRules web adapter"
```

---

### Task 7: Playground project shell and engine client

**Files:**
- Create: `playground/package.json`
- Create: `playground/package-lock.json`
- Create: `playground/tsconfig.json`
- Create: `playground/vite.config.ts`
- Create: `playground/index.html`
- Create: `playground/src/contracts.ts`
- Create: `playground/src/engine.ts`
- Create: `playground/src/app.ts`
- Create: `playground/src/styles.css`
- Create: `playground/tests/engine.test.ts`
- Modify: `.gitignore`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Initialize pinned frontend dependencies**

Run:

```bash
mkdir -p playground/src playground/tests playground/public/engine
cd playground
npm init -y
npm install @codemirror/lang-json @codemirror/state @codemirror/view codemirror
npm install --save-dev vite typescript vitest jsdom @types/node
cd ..
```

Expected: `package-lock.json` pins every resolved version. Do not hand-edit the
lock file.

- [ ] **Step 2: Set exact scripts and TypeScript config**

Set `playground/package.json` scripts to:

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc --noEmit && vite build",
    "test": "vitest run",
    "preview": "vite preview"
  }
}
```

Create `playground/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noEmit": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "types": ["vitest/globals", "node"]
  },
  "include": ["src", "tests", "vite.config.ts"]
}
```

Create `playground/vite.config.ts`:

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  base: process.env.GITHUB_ACTIONS ? "/moonrules/" : "/",
  test: {
    environment: "jsdom",
  },
});
```

- [ ] **Step 3: Write the engine-client test first**

Create `playground/tests/engine.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { parseAdapterResponse } from "../src/engine";

describe("parseAdapterResponse", () => {
  it("accepts an evaluation envelope", () => {
    const result = parseAdapterResponse(
      '{"ok":true,"kind":"evaluation","report":{"decision":{"status":"fail"},"trace":{"rule_path":"condition","operator":"==","status":"fail","resolved_inputs":[],"result":false,"message":"x","children":[]},"stats":{"steps_executed":3,"nodes_evaluated":3,"max_depth_reached":2,"trace_nodes_emitted":3}},"diagnostics":[]}',
    );
    expect(result.kind).toBe("evaluation");
    expect(result.report?.decision.status).toBe("fail");
  });

  it("rejects malformed adapter output", () => {
    expect(() => parseAdapterResponse("not-json")).toThrow(
      "MoonRules adapter returned invalid JSON",
    );
  });
});
```

Run:

```bash
cd playground
npm test
```

Expected: FAIL because `engine.ts` does not exist.

- [ ] **Step 4: Define shared contracts**

Create `playground/src/contracts.ts` with:

```ts
export type DecisionStatus = "pass" | "fail" | "indeterminate";
export type TraceStatus = "value" | "pass" | "fail" | "error" | "skipped";
export type TraceMode = "full" | "summary" | "off";

export interface Diagnostic {
  code: string;
  severity: "error" | "warning";
  rule_path: string;
  message: string;
  suggestion: string;
}

export interface TraceNode {
  rule_path: string;
  operator: string;
  status: TraceStatus;
  resolved_inputs: Array<{ source: string; value: unknown }>;
  result: unknown;
  message: string;
  children: TraceNode[];
}

export interface EvaluationReport {
  decision: { status: DecisionStatus; error?: unknown };
  trace: TraceNode;
  stats: {
    steps_executed: number;
    nodes_evaluated: number;
    max_depth_reached: number;
    trace_nodes_emitted: number;
  };
}

export interface AdapterResponse {
  ok: boolean;
  kind: "check" | "evaluation" | "input_error" | "internal_error";
  report: EvaluationReport | null;
  diagnostics: Diagnostic[];
}
```

- [ ] **Step 5: Implement the selected backend client**

Create `playground/src/engine.ts`:

```ts
import type { AdapterResponse, TraceMode } from "./contracts";

export function parseAdapterResponse(source: string): AdapterResponse {
  try {
    return JSON.parse(source) as AdapterResponse;
  } catch {
    throw new Error("MoonRules adapter returned invalid JSON");
  }
}

export interface MoonRulesEngine {
  check(rule: string, traceMode: TraceMode): AdapterResponse;
  evaluate(
    rule: string,
    data: string,
    traceMode: TraceMode,
  ): AdapterResponse;
}
```

For the selected JS backend, append:

```ts
// @ts-expect-error generated MoonBit module has no declaration file
import * as moonrules from "./generated/moonrules.js";

export const engine: MoonRulesEngine = {
  check(rule, traceMode) {
    return parseAdapterResponse(
      moonrules.check_json(rule, JSON.stringify({ trace_mode: traceMode })),
    );
  },
  evaluate(rule, data, traceMode) {
    return parseAdapterResponse(
      moonrules.evaluate_json(
        rule,
        data,
        JSON.stringify({ trace_mode: traceMode }),
      ),
    );
  },
};
```

For wasm-gc, start from this exact loader and retain it only if Task 6 proves it
in the target browser:

```ts
type WasmExports = {
  check_json(rule: string, options: string): string;
  evaluate_json(rule: string, data: string, options: string): string;
};

const imports = {
  "moonbit:ffi": {
    make_closure: (fn: Function, closure: unknown) => fn.bind(null, closure),
  },
  spectest: {
    print_char: (_value: number) => undefined,
  },
};

const instantiated = await WebAssembly.instantiateStreaming(
  fetch(`${import.meta.env.BASE_URL}engine/moonrules.wasm`),
  imports,
  { builtins: ["js-string"], importedStringConstants: "_" },
);
const moonrules = instantiated.instance.exports as unknown as WasmExports;

export const engine: MoonRulesEngine = {
  check(rule, traceMode) {
    return parseAdapterResponse(
      moonrules.check_json(rule, JSON.stringify({ trace_mode: traceMode })),
    );
  },
  evaluate(rule, data, traceMode) {
    return parseAdapterResponse(
      moonrules.evaluate_json(
        rule,
        data,
        JSON.stringify({ trace_mode: traceMode }),
      ),
    );
  },
};
```

If the current TypeScript DOM library does not yet declare the third
`compileOptions` argument, add one narrow local interface/cast; do not suppress
type checking for the whole file. Do not let `app.ts` know which backend was
chosen.

- [ ] **Step 6: Add the minimal page shell**

Create `playground/index.html`:

```html
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Run explainable MoonRules locally in your browser." />
    <title>MoonRules Playground</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/app.ts"></script>
  </body>
</html>
```

Create `playground/src/app.ts`:

```ts
import "./styles.css";

const root = document.querySelector<HTMLDivElement>("#app");
if (!root) throw new Error("missing #app");
root.innerHTML = `
  <main class="shell">
    <header>
      <p class="eyebrow">MoonBit · Explainable rules</p>
      <h1>MoonRules Playground</h1>
      <p>规则和数据只在本地浏览器处理，不会上传服务器。</p>
    </header>
    <section class="notice">Engine connected. Editors arrive in the next task.</section>
  </main>
`;
```

Create `playground/src/styles.css`:

```css
:root {
  color: #182033;
  background: #f4f6fb;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, sans-serif;
}
* { box-sizing: border-box; }
body { margin: 0; min-width: 320px; }
.shell { width: min(1440px, 100%); margin: 0 auto; padding: 32px; }
.eyebrow { color: #5d52d6; font-weight: 700; letter-spacing: .08em; }
h1 { margin: 0; font-size: clamp(2rem, 5vw, 4rem); }
.notice { margin-top: 24px; padding: 20px; background: white; border-radius: 16px; }
@media (max-width: 720px) { .shell { padding: 20px; } }
```

- [ ] **Step 7: Verify and commit**

Add `playground/node_modules/`, `playground/dist/`, and generated engine output
to `.gitignore`, while keeping the source build script tracked.

Run:

```bash
scripts/build_playground_engine.sh
cd playground
npm test
npm run build
cd ..
```

Expected: tests pass and `playground/dist/index.html` exists.

```bash
git add playground .gitignore scripts/build_playground_engine.sh .ai/TASK_STATE.md
git commit -m "feat: scaffold MoonRules playground"
```

---

### Task 8: Examples, dual editors, and Check/Evaluate flow

**Files:**
- Create: `playground/public/examples/*`
- Create: `playground/src/examples.ts`
- Create: `playground/src/editor.ts`
- Modify: `playground/src/app.ts`
- Modify: `playground/src/styles.css`
- Create: `playground/tests/examples.test.ts`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Sync the six pass/fail example inputs**

Create `playground/public/examples/manifest.json`:

```json
[
  {
    "id": "coupon",
    "label": "优惠券资格",
    "rule": "coupon.rule.json",
    "pass": "coupon.data.pass.json",
    "fail": "coupon.data.fail.json"
  },
  {
    "id": "api-access",
    "label": "API 请求准入",
    "rule": "api-access.rule.json",
    "pass": "api-access.data.pass.json",
    "fail": "api-access.data.fail.json"
  },
  {
    "id": "membership",
    "label": "会员资格",
    "rule": "membership.rule.json",
    "pass": "membership.data.pass.json",
    "fail": "membership.data.fail.json"
  }
]
```

Copy root examples with:

```bash
cp examples/coupon.rule.json playground/public/examples/coupon.rule.json
cp examples/coupon.data.pass.json playground/public/examples/coupon.data.pass.json
cp examples/coupon.data.json playground/public/examples/coupon.data.fail.json
cp examples/api-access.rule.json playground/public/examples/api-access.rule.json
cp examples/api-access.data.pass.json playground/public/examples/api-access.data.pass.json
cp examples/api-access.data.fail.json playground/public/examples/api-access.data.fail.json
cp examples/membership.rule.json playground/public/examples/membership.rule.json
cp examples/membership.data.pass.json playground/public/examples/membership.data.pass.json
cp examples/membership.data.fail.json playground/public/examples/membership.data.fail.json
```

- [ ] **Step 2: Test and implement example loading**

Create `playground/tests/examples.test.ts`:

```ts
import { expect, it } from "vitest";
import { exampleUrl } from "../src/examples";

it("builds base-aware example URLs", () => {
  expect(exampleUrl("coupon.rule.json", "/moonrules/")).toBe(
    "/moonrules/examples/coupon.rule.json",
  );
});
```

Create `playground/src/examples.ts`:

```ts
export interface Example {
  id: string;
  label: string;
  rule: string;
  pass: string;
  fail: string;
}

export function exampleUrl(file: string, base = import.meta.env.BASE_URL): string {
  return `${base}examples/${file}`;
}

export async function loadExamples(): Promise<Example[]> {
  const response = await fetch(exampleUrl("manifest.json"));
  if (!response.ok) throw new Error("failed to load example manifest");
  return response.json() as Promise<Example[]>;
}

export async function loadExampleText(file: string): Promise<string> {
  const response = await fetch(exampleUrl(file));
  if (!response.ok) throw new Error(`failed to load ${file}`);
  return response.text();
}
```

Run `cd playground && npm test`; expected PASS.

- [ ] **Step 3: Add the CodeMirror wrapper**

Create `playground/src/editor.ts`:

```ts
import { basicSetup } from "codemirror";
import { json } from "@codemirror/lang-json";
import { EditorState } from "@codemirror/state";
import { EditorView, keymap } from "@codemirror/view";

export class JsonEditor {
  private readonly view: EditorView;

  constructor(parent: HTMLElement, value: string, onRun: () => void) {
    this.view = new EditorView({
      parent,
      state: EditorState.create({
        doc: value,
        extensions: [
          basicSetup,
          json(),
          keymap.of([{
            key: "Mod-Enter",
            run: () => {
              onRun();
              return true;
            },
          }]),
          EditorView.lineWrapping,
        ],
      }),
    });
  }

  getValue(): string {
    return this.view.state.doc.toString();
  }

  setValue(value: string): void {
    this.view.dispatch({
      changes: { from: 0, to: this.view.state.doc.length, insert: value },
    });
  }

  format(): void {
    this.setValue(JSON.stringify(JSON.parse(this.getValue()), null, 2));
  }
}
```

- [ ] **Step 4: Implement the main interaction**

Replace the temporary shell in `app.ts` with controls for:

```html
<select id="example"></select>
<select id="variant">
  <option value="fail">不通过数据</option>
  <option value="pass">通过数据</option>
</select>
<select id="trace-mode">
  <option value="full">Full</option>
  <option value="summary">Summary</option>
  <option value="off">Off</option>
</select>
<button id="check">Check</button>
<button id="evaluate">Evaluate</button>
<button id="format">Format JSON</button>
<div id="rule-editor" aria-label="Rule JSON editor"></div>
<div id="data-editor" aria-label="Data JSON editor"></div>
<section id="result" aria-live="polite"></section>
```

Wire `loadExamples`, `JsonEditor`, and `engine` so:

```ts
checkButton.addEventListener("click", () => {
  renderResponse(engine.check(ruleEditor.getValue(), selectedTraceMode()));
});

evaluateButton.addEventListener("click", () => {
  const checked = engine.check(ruleEditor.getValue(), selectedTraceMode());
  if (!checked.ok || checked.diagnostics.length > 0) {
    renderResponse(checked);
    return;
  }
  renderResponse(
    engine.evaluate(
      ruleEditor.getValue(),
      dataEditor.getValue(),
      selectedTraceMode(),
    ),
  );
});
```

For this task, `renderResponse` may render pretty JSON inside `<pre>`; Task 9
replaces it with the full result experience.

- [ ] **Step 5: Add responsive dual-column styles**

Use:

```css
.toolbar { display: flex; gap: 10px; flex-wrap: wrap; margin: 24px 0; }
.workspace { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.editor-card, .result-card { background: #fff; border: 1px solid #dfe3ec; border-radius: 16px; overflow: hidden; }
.editor-card h2 { padding: 12px 16px; margin: 0; font-size: 1rem; }
.cm-editor { min-height: 360px; max-height: 54vh; }
button, select { min-height: 42px; border-radius: 10px; border: 1px solid #c8cede; padding: 0 14px; }
button:focus-visible, select:focus-visible { outline: 3px solid #8c83ff; outline-offset: 2px; }
@media (max-width: 820px) {
  .workspace { grid-template-columns: 1fr; }
  .cm-editor { min-height: 280px; }
}
```

- [ ] **Step 6: Verify default FAIL flow and commit**

Run:

```bash
scripts/build_playground_engine.sh
cd playground
npm test
npm run build
cd ..
```

Manually open the local preview, select coupon/fail, run Evaluate, and confirm
the JSON report contains `decision.status = "fail"`.

```bash
git add playground .ai/TASK_STATE.md
git commit -m "feat: add interactive rule and data evaluation"
```

---

### Task 9: Status, Trace, diagnostics, JSON, stats, copy, and download

**Files:**
- Create: `playground/src/renderers.ts`
- Modify: `playground/src/app.ts`
- Modify: `playground/src/styles.css`
- Create: `playground/tests/renderers.test.ts`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Write renderer tests**

Create `playground/tests/renderers.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { countTraceNodes, decisionLabel } from "../src/renderers";
import type { TraceNode } from "../src/contracts";

const root: TraceNode = {
  rule_path: "condition",
  operator: "and",
  status: "fail",
  resolved_inputs: [],
  result: false,
  message: "coupon",
  children: [{
    rule_path: "condition.and[0]",
    operator: ">=",
    status: "pass",
    resolved_inputs: [],
    result: true,
    message: "true",
    children: [],
  }],
};

describe("result helpers", () => {
  it("counts the root and descendants", () => {
    expect(countTraceNodes(root)).toBe(2);
  });
  it("uses text labels, not color alone", () => {
    expect(decisionLabel("indeterminate")).toBe("INDETERMINATE");
  });
});
```

Run `cd playground && npm test`; expected FAIL.

- [ ] **Step 2: Implement pure helpers and safe DOM rendering**

Create `playground/src/renderers.ts` with:

```ts
import type {
  AdapterResponse,
  DecisionStatus,
  Diagnostic,
  TraceNode,
} from "./contracts";

export function countTraceNodes(node: TraceNode): number {
  return 1 + node.children.reduce((sum, child) => sum + countTraceNodes(child), 0);
}

export function decisionLabel(status: DecisionStatus): string {
  return status.toUpperCase();
}

function element<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  className?: string,
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  if (className) node.className = className;
  return node;
}

export function renderDiagnostic(diagnostic: Diagnostic): HTMLElement {
  const article = element("article", "diagnostic");
  const title = element("strong");
  title.textContent = `${diagnostic.code} · ${diagnostic.rule_path}`;
  const message = element("p");
  message.textContent = diagnostic.message;
  const suggestion = element("p", "suggestion");
  suggestion.textContent = diagnostic.suggestion;
  article.append(title, message, suggestion);
  return article;
}

export function renderTrace(node: TraceNode, open = false): HTMLElement {
  const details = element("details", `trace-node status-${node.status}`);
  details.open = open || node.status === "fail" || node.status === "error";
  const summary = element("summary");
  summary.textContent = `${node.status.toUpperCase()} · ${node.operator} · ${node.rule_path}`;
  details.append(summary);
  if (node.message) {
    const message = element("p");
    message.textContent = node.message;
    details.append(message);
  }
  for (const child of node.children) details.append(renderTrace(child));
  return details;
}

export function responseJson(response: AdapterResponse): string {
  return JSON.stringify(response, null, 2);
}
```

- [ ] **Step 3: Build the four result tabs**

In `app.ts`, create `Trace`, `Diagnostics`, `JSON`, and `Stats` tab buttons with
matching panels. `renderResponse` must:

```ts
function renderResponse(response: AdapterResponse): void {
  lastResponse = response;
  diagnosticsPanel.replaceChildren(
    ...response.diagnostics.map(renderDiagnostic),
  );
  jsonPanel.textContent = responseJson(response);
  tracePanel.replaceChildren();
  statsPanel.replaceChildren();

  if (response.report) {
    const status = response.report.decision.status;
    statusCard.dataset.status = status;
    statusCard.textContent = `${decisionIcon(status)} ${decisionLabel(status)}`;
    tracePanel.append(renderTrace(response.report.trace, true));
    statsPanel.textContent = [
      `Steps: ${response.report.stats.steps_executed}`,
      `Evaluated nodes: ${response.report.stats.nodes_evaluated}`,
      `Maximum depth: ${response.report.stats.max_depth_reached}`,
      `Full trace nodes: ${response.report.stats.trace_nodes_emitted}`,
      `Returned trace nodes: ${countTraceNodes(response.report.trace)}`,
    ].join("\n");
  } else {
    statusCard.dataset.status = response.ok ? "checked" : "error";
    statusCard.textContent = response.ok ? "✓ CHECKED" : "⚠ INPUT ERROR";
  }
}
```

Implement `decisionIcon` as `✓`, `×`, or `⚠`; never rely on color alone.

- [ ] **Step 4: Add copy and download actions**

Wire:

```ts
copyButton.addEventListener("click", async () => {
  if (!lastResponse) return;
  await navigator.clipboard.writeText(responseJson(lastResponse));
  copyButton.textContent = "Copied";
});

downloadButton.addEventListener("click", () => {
  if (!lastResponse) return;
  const blob = new Blob([responseJson(lastResponse)], {
    type: "application/json",
  });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = "moonrules-report.json";
  anchor.click();
  URL.revokeObjectURL(url);
});
```

If download is cut by the approved degradation order, keep copy and remove only
the download button/test.

- [ ] **Step 5: Complete result styling and accessibility**

Add status styles using both text and icons:

```css
.status-card { padding: 18px; border-radius: 14px; font-weight: 800; }
.status-card[data-status="pass"] { background: #e9f8ef; color: #17643a; }
.status-card[data-status="fail"] { background: #fff0f0; color: #8b2424; }
.status-card[data-status="indeterminate"],
.status-card[data-status="error"] { background: #fff6dc; color: #725100; }
.tabs { display: flex; gap: 6px; border-bottom: 1px solid #dfe3ec; }
.tab[aria-selected="true"] { background: #211b4d; color: white; }
.trace-node { margin: 8px 0 8px 18px; }
.trace-node summary { cursor: pointer; font-family: ui-monospace, monospace; }
.diagnostic { border-left: 4px solid #d67b00; padding: 10px 14px; }
pre { white-space: pre-wrap; overflow-wrap: anywhere; }
```

Every tab button must have `role="tab"`, `aria-selected`, and keyboard focus.

- [ ] **Step 6: Verify and commit**

Run:

```bash
cd playground
npm test
npm run build
cd ..
```

Manually verify Full, Summary, and Off on coupon Fail and a malformed rule.

```bash
git add playground/src playground/tests .ai/TASK_STATE.md
git commit -m "feat: render explainable playground results"
```

---

### Task 10: Browser smoke test and GitHub Pages

**Files:**
- Create: `playground/playwright.config.ts`
- Create: `playground/e2e/playground.spec.ts`
- Modify: `playground/package.json`
- Modify: `playground/package-lock.json`
- Modify: `.github/workflows/ci.yml`
- Create: `.github/workflows/pages.yml`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Install and configure Playwright**

Run:

```bash
cd playground
npm install --save-dev @playwright/test
npx playwright install chromium
cd ..
```

Add script:

```json
"test:e2e": "playwright test"
```

Create `playground/playwright.config.ts`:

```ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  use: {
    baseURL: "http://127.0.0.1:4173",
    trace: "retain-on-failure",
  },
  webServer: {
    command: "npm run preview -- --host 127.0.0.1",
    port: 4173,
    reuseExistingServer: !process.env.CI,
  },
  projects: [{ name: "chromium", use: devices["Desktop Chrome"] }],
});
```

- [ ] **Step 2: Write the main acceptance smoke**

Create `playground/e2e/playground.spec.ts`:

```ts
import { expect, test } from "@playwright/test";

test("default coupon scenario evaluates to FAIL with a trace", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { name: "MoonRules Playground" })).toBeVisible();
  await page.getByRole("button", { name: "Evaluate" }).click();
  await expect(page.locator(".status-card")).toContainText("FAIL");
  await expect(page.getByRole("tab", { name: "Trace" })).toBeVisible();
  await expect(page.locator(".trace-node").first()).toBeVisible();
});

test("mobile layout keeps both editors and actions reachable", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await expect(page.getByLabel("Rule JSON editor")).toBeVisible();
  await expect(page.getByLabel("Data JSON editor")).toBeVisible();
  await expect(page.getByRole("button", { name: "Evaluate" })).toBeVisible();
});
```

- [ ] **Step 3: Run local browser acceptance**

Run:

```bash
scripts/build_playground_engine.sh
cd playground
npm run build
npm run test:e2e
cd ..
```

Expected: both Chromium tests pass.

- [ ] **Step 4: Split CI into core and Playground jobs**

Keep existing core commands in `core`. Add:

```yaml
  playground:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
          cache-dependency-path: playground/package-lock.json
      - name: Install MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
          echo "$HOME/.moon/bin" >> "$GITHUB_PATH"
      - run: moon update
      - run: scripts/build_playground_engine.sh
      - run: npm ci
        working-directory: playground
      - run: npm test
        working-directory: playground
      - run: npm run build
        working-directory: playground
      - run: npx playwright install --with-deps chromium
        working-directory: playground
      - run: npm run test:e2e
        working-directory: playground
```

- [ ] **Step 5: Add Pages deployment**

Create `.github/workflows/pages.yml` using:

```yaml
name: Pages
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: pages
  cancel-in-progress: true
jobs:
  deploy:
    if: >-
      github.event.workflow_run.conclusion == 'success' &&
      github.event.workflow_run.head_branch == 'main'
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.workflow_run.head_sha }}
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
          cache-dependency-path: playground/package-lock.json
      - name: Install MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
          echo "$HOME/.moon/bin" >> "$GITHUB_PATH"
      - run: moon update
      - run: scripts/build_playground_engine.sh
      - run: npm ci
        working-directory: playground
      - run: npm run build
        working-directory: playground
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: playground/dist
      - id: deployment
        uses: actions/deploy-pages@v4
```

Repository Pages settings may require a one-time GitHub UI/API enablement after
merge; record the exact URL and status.

- [ ] **Step 6: Verify and commit**

```bash
git diff --check
git add playground .github/workflows .ai/TASK_STATE.md
git commit -m "ci: test and deploy the playground"
```

- [ ] **Step 7: Merge the Playground phase**

Push `codex/v0.2-playground`, open a PR with desktop/mobile screenshots and the
Playwright result, wait for green checks, merge, verify Pages, and create
`codex/v0.2-evidence` from updated `main`.

---

### Task 11: Reproducible MoonBit benchmarks

**Files:**
- Create: `benchmark_helpers.mbt`
- Create: `benchmark_parse.mbt`
- Create: `benchmark_check.mbt`
- Create: `benchmark_evaluate.mbt`
- Create: `benchmark_render.mbt`
- Create: `benchmark_render_summary.mbt`
- Create: `benchmark_render_off.mbt`
- Modify: `moon.pkg`
- Create: `docs/BENCHMARKS.md`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 0: Confirm the evidence phase branch**

Run `git status --short --branch`. Expected:
`## codex/v0.2-evidence` with a clean worktree.

- [ ] **Step 1: Add the benchmark-only import and fixture helpers**

Add:

```moonbit
import {
  "moonbitlang/core/bench",
} for "test"
```

to the test import block in `moon.pkg`.

Create `benchmark_helpers.mbt`:

```moonbit
///|
fn benchmark_expr(size : Int) -> Expr {
  let children : Array[Expr] = []
  for index = 0; index < size; index += 1 {
    children.push(
      Expr::Operation(Operator::GreaterOrEqual, [
        Expr::Literal(Json::number(index.to_double())),
        Expr::Literal(Json::number(0.0)),
      ]),
    )
  }
  Expr::Operation(Operator::And, children)
}

///|
fn benchmark_rule(size : Int) -> RuleDocument {
  {
    id: "benchmark-\{size}",
    description: "deterministic benchmark fixture",
    condition: benchmark_expr(size),
  }
}

///|
fn benchmark_rule_source(size : Int) -> String {
  let conditions : Array[Json] = []
  for index = 0; index < size; index += 1 {
    conditions.push(
      Json::object({
        ">=": Json::array([
          Json::number(index.to_double()),
          Json::number(0.0),
        ]),
      }),
    )
  }
  Json::object({
    "id": Json::string("benchmark-\{size}"),
    "description": Json::string("deterministic benchmark fixture"),
    "condition": Json::object({ "and": Json::array(conditions) }),
  }).stringify()
}
```

- [ ] **Step 2: Add one phase per benchmark file**

Create `benchmark_parse.mbt`:

```moonbit
///|
test (bench : @bench.T) {
  let source = benchmark_rule_source(1000)
  bench.bench(fn() { ignore(parse(source)) })
}
```

Create `benchmark_check.mbt`:

```moonbit
///|
test (bench : @bench.T) {
  let rule = benchmark_rule(1000)
  bench.bench(fn() { ignore(check(rule)) })
}
```

Create `benchmark_evaluate.mbt`:

```moonbit
///|
test (bench : @bench.T) {
  let rule = benchmark_rule(1000)
  bench.bench(fn() {
    ignore(evaluate(rule, Json::empty_object(), Budget::default()))
  })
}
```

Create `benchmark_render.mbt`:

```moonbit
///|
test (bench : @bench.T) {
  let report = evaluate(
    benchmark_rule(1000),
    Json::empty_object(),
    Budget::default(),
  )
  bench.bench(fn() { ignore(report_to_json(report).stringify()) })
}
```

Create `benchmark_render_summary.mbt`:

```moonbit
///|
test (bench : @bench.T) {
  let report = evaluate(
    benchmark_rule(1000),
    Json::empty_object(),
    Budget::default(),
    trace_mode=Summary,
  )
  bench.bench(fn() { ignore(report_to_json(report).stringify()) })
}
```

Create `benchmark_render_off.mbt`:

```moonbit
///|
test (bench : @bench.T) {
  let report = evaluate(
    benchmark_rule(1000),
    Json::empty_object(),
    Budget::default(),
    trace_mode=Off,
  )
  bench.bench(fn() { ignore(report_to_json(report).stringify()) })
}
```

- [ ] **Step 3: Compile probes and execute release benchmarks**

Run:

```bash
moon fmt
moon bench benchmark_parse.mbt --target native --release
moon bench benchmark_check.mbt --target native --release
moon bench benchmark_evaluate.mbt --target native --release
moon bench benchmark_render.mbt --target native --release
moon bench benchmark_render_summary.mbt --target native --release
moon bench benchmark_render_off.mbt --target native --release
scripts/build_playground_engine.sh
wc -c playground/public/engine/moonrules.wasm 2>/dev/null || true
wc -c playground/src/generated/moonrules.js 2>/dev/null || true
```

Expected: four benchmark reports. Repeat for 10 and 100 nodes by changing only
the fixture size in separate commits or by running three named copies; retain
raw terminal output in the PR description, not as unlabelled claims.

- [ ] **Step 4: Write the benchmark report**

Create `docs/BENCHMARKS.md` with:

```markdown
# MoonRules v0.2 Benchmarks

## Environment

- Date: use the execution date printed by `date +%F`
- Machine: Apple Silicon MacBook Air
- Architecture: arm64
- Moon: 0.1.20260713
- Moonc: 0.10.4
- Target: native release

## Method

Each phase uses MoonBit's `@bench.T` harness. Fixtures contain deterministic
10, 100, and 1000-comparison `and` rules. Parse, check, evaluate, and report
serialization are measured independently. Full/Summary/Off use identical full
evaluation; mode comparisons describe returned report size, not reduced
evaluation work.

## Results

Use columns `Nodes`, `Parse`, `Check`, `Evaluate`, `Render Full`,
`Render Summary`, and `Render Off`; append one measured row for 10, 100, and
1000 nodes from the commands above.

## Browser artifact

Record the selected backend and release artifact bytes.

## Limits

These results describe one machine and toolchain. They demonstrate scaling
trends and reproducibility, not universal latency guarantees.
```

Replace the date and table with measured values in the same task; no blank
result cells may remain when committing.

- [ ] **Step 5: Verify and commit**

```bash
moon fmt --check
moon check --deny-warn
moon test --target native
git add benchmark_*.mbt moon.pkg docs/BENCHMARKS.md .ai/TASK_STATE.md
git commit -m "perf: add reproducible MoonRules benchmarks"
```

---

### Task 12: Repository maturity and contribution documents

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug_report.yml`
- Create: `.github/ISSUE_TEMPLATE/feature_request.yml`
- Create: `.github/pull_request_template.md`
- Create: `CONTRIBUTING.md`
- Create: `SECURITY.md`
- Create: `ROADMAP.md`
- Create: `THIRD_PARTY_NOTICES.md`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Add actionable Issue forms**

Bug form fields must require version, target, minimal rule/data with sensitive
values removed, expected result, actual result, and reproduction commands.
Feature form fields must require use case, proposed behavior, scope fit, and
alternatives. Use GitHub YAML forms, not empty Markdown prompts.

- [ ] **Step 2: Add the PR evidence template**

Create:

```markdown
## Goal

## Scope

## Behavior before / after

## Verification

- [ ] `moon fmt --check`
- [ ] `moon check --deny-warn`
- [ ] `moon test --target native`
- [ ] `moon test --target wasm-gc`
- [ ] Playground tests/build when affected

## Evidence

Include terminal output, screenshots, or benchmark data relevant to this PR.

## Boundaries

- [ ] No DSL or three-state semantic change unless separately approved
- [ ] No credentials or unrelated generated files
```

- [ ] **Step 3: Write the four maturity documents**

`CONTRIBUTING.md` must include environment setup, TDD loop, commands, module
boundaries, commit style, and PR evidence.

`SECURITY.md` must state:

```markdown
MoonRules never executes arbitrary code and the Playground processes data
locally. Do not report secrets through public Issues. Report security concerns
privately through GitHub's security advisory interface. Supported versions:
latest published minor release.
```

`ROADMAP.md` must separate:

- v0.2: Playground, Trace modes, CLI JSON/stdin, evidence.
- v0.3 candidate: schema-aware variable type environment.
- Explicit non-goals: full JSONLogic, arbitrary code, server/database, array
  indexes until separately designed.

`THIRD_PARTY_NOTICES.md` must list MoonBit core/toolchain, `moonbitlang/async`,
`moonbitlang/x`, Vite, TypeScript, CodeMirror, Vitest, Playwright, their
repository URLs, and licenses as verified from installed package metadata.

- [ ] **Step 4: Verify no boilerplate placeholders and commit**

Run:

```bash
rg -n "TBD|TODO|FIXME|fill in|your email|example.com" .github CONTRIBUTING.md SECURITY.md ROADMAP.md THIRD_PARTY_NOTICES.md
git diff --check
```

Expected: no hits.

```bash
git add .github CONTRIBUTING.md SECURITY.md ROADMAP.md THIRD_PARTY_NOTICES.md .ai/TASK_STATE.md
git commit -m "docs: add project contribution and security guidance"
```

---

### Task 13: Architecture, API, README, and technical report

**Files:**
- Create: `docs/ARCHITECTURE.md`
- Create: `docs/technical-report.md`
- Modify: `docs/API.md`
- Modify: `docs/ERRORS.md`
- Modify: `README.md`
- Modify: `README.en.md`
- Modify: `README.mbt.md`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Write architecture from the implemented backend**

`docs/ARCHITECTURE.md` must include:

```text
JSON source -> Parser -> Checker -> Evaluator -> Full report
                                             -> TraceMode compressor
                                             -> Renderer / CLI / Web Adapter
```

Document the exact selected Web backend, string boundary, local-only data flow,
core side-effect boundary, and why Summary/Off do not reduce evaluation cost.

- [ ] **Step 2: Update API and error contracts**

Add runnable examples for:

```moonbit
let full = evaluate(rule, data, Budget::default(), trace_mode=Full)
let summary = evaluate(rule, data, Budget::default(), trace_mode=Summary)
let off = evaluate(rule, data, Budget::default(), trace_mode=Off)
let diagnostic_json = diagnostics_to_json(check(rule)).stringify()
```

Remove every statement that Summary/Off are unsupported. Keep
`UnsupportedTraceMode` documented as a retained compatibility variant that v0.2
does not normally produce.

- [ ] **Step 3: Rewrite the README first screen**

The first screen must contain, in this order:

1. CI badge and v0.2 status.
2. One-sentence positioning.
3. Online Playground link.
4. GIF.
5. JSON Schema boundary.
6. Install and 30-second example.

Then add architecture, innovations, support matrix, CLI v0.2 commands, tests,
benchmarks, limitations, roadmap, and evidence links. Use measured counts only.

- [ ] **Step 4: Write the complete technical report**

`docs/technical-report.md` must have separate sections for:

- Problem and positioning.
- DSL and JSON Schema boundary.
- Parser/checker/evaluator architecture.
- Three-state logic.
- Budgets and partial Trace.
- Full/Summary/Off semantics.
- Adapter and chosen backend.
- Playground interaction and privacy.
- Tests and actual counts.
- Benchmark method/results.
- AI-assisted development responsibility.
- Dependency/license provenance.
- Known limitations and v0.3.

The AI section must state that agents assisted planning, implementation, tests,
and documentation, while the entrant owns scope, review, verification,
security, licensing, and final claims.

- [ ] **Step 5: Verify links, commands, and claims**

Run:

```bash
rg -n "0\\.1\\.0|UnsupportedTraceMode|GUI|not implemented|尚未实现" README.md README.en.md README.mbt.md docs
moon fmt --check
moon check --deny-warn
moon test --target native
scripts/test_cli.sh
cd playground
npm test
npm run build
cd ..
```

Every remaining `0.1.0` mention must be historical and labelled.

- [ ] **Step 6: Commit**

```bash
git add README.md README.en.md README.mbt.md docs .ai/TASK_STATE.md
git commit -m "docs: explain MoonRules v0.2 architecture and usage"
```

---

### Task 14: Application PDF, screenshots, GIF, and demo script

**Files:**
- Modify: `docs/submission/moonrules-application.md`
- Modify: `scripts/build_application_pdf.py`
- Create: `docs/demo-script.md`
- Create: `docs/acceptance-checklist.md`
- Create: `docs/assets/*`
- Modify: `output/pdf/moonrules-application.pdf`
- Modify: `.ai/TASK_STATE.md`

- [ ] **Step 1: Capture truthful product evidence**

From the production Playground build, capture:

- Coupon Fail with expanded failure Trace.
- Coupon Pass.
- An Indeterminate/error result.
- Summary versus Full.
- CLI `--json`.

Store optimized assets under `docs/assets/` with descriptive filenames. Do not
include browser account UI, tokens, local paths, or unrelated tabs.

- [ ] **Step 2: Produce the main GIF**

Record this sequence in 15–25 seconds:

```text
Open Playground -> coupon fail -> Evaluate -> expand failed Trace ->
switch data to pass -> Evaluate -> PASS
```

Keep the GIF readable at README width and below GitHub's practical file-size
limit. If GIF quality is poor, use an MP4 for the repository and a still image
in the PDF.

- [ ] **Step 3: Rewrite the one-page application source**

`docs/submission/moonrules-application.md` must contain:

- Project/title and public links.
- User problem and JSON Schema boundary.
- v0.1 existing foundation.
- v0.2 new work.
- Three innovations.
- Architecture.
- Actual implementation/test/benchmark/release numbers.
- July 27–31 schedule and controlled risks.
- AI assistance and open-source compliance statement.

No section may say only “complete” without a measurable artifact or link.

- [ ] **Step 4: Rebuild the PDF layout**

Update `scripts/build_application_pdf.py` to render the new content on one A4
page. Keep:

- minimum 8 pt body text,
- clear visual hierarchy,
- working shortened links or QR codes,
- no clipped text,
- no unverified metric.

Run:

```bash
python3 scripts/build_application_pdf.py
pdfinfo output/pdf/moonrules-application.pdf
pdftoppm -png -f 1 -singlefile -r 150 output/pdf/moonrules-application.pdf /tmp/moonrules-application
```

Expected: exactly one A4 page. Visually inspect
`/tmp/moonrules-application.png` at full size.

- [ ] **Step 5: Write the 90-second demo script**

Use exact time boxes:

```markdown
0–12s: problem and JSON Schema boundary
12–28s: open default failing coupon example
28–48s: read variable, comparison, failure, skipped Trace
48–60s: switch Full to Summary/Off
60–72s: show Check diagnostic and Indeterminate
72–82s: show CLI JSON and exit semantics
82–90s: tests, benchmark, Mooncakes, GitHub/Pages links
```

- [ ] **Step 6: Create the acceptance checklist**

Every item in design section 16 becomes a checkbox with an evidence URL,
command, or file path. Empty evidence cells block release.

- [ ] **Step 7: Verify and commit**

```bash
test -s output/pdf/moonrules-application.pdf
test -s docs/assets/moonrules-playground.gif
git diff --check
git add docs scripts/build_application_pdf.py output/pdf/moonrules-application.pdf .ai/TASK_STATE.md
git commit -m "docs: prepare v0.2 submission and demo"
```

---

### Task 15: Full CI, package audit, PRs, and pre-release candidate

**Files:**
- Modify: `moon.mod`
- Modify: `CHANGELOG.md`
- Modify: `.ai/TASK_STATE.md`
- Generated audit artifacts are not committed unless explicitly documented.

- [ ] **Step 1: Bump the candidate version**

Set:

```moonbit
version = "0.2.0"
```

in `moon.mod`. Add a dated `0.2.0` CHANGELOG section listing Trace modes, CLI,
Playground, tests/benchmark/docs, and compatibility.

- [ ] **Step 2: Run the entire local acceptance matrix**

Run:

```bash
moon fmt --check
moon check --deny-warn
moon test --target native
moon test --target wasm-gc
moon build --target native
moon build --target wasm-gc
scripts/test_cli.sh
scripts/build_playground_engine.sh
cd playground
npm ci
npm test
npm run build
npm run test:e2e
cd ..
git diff --check
```

Expected: all pass. Record exact test totals and artifact sizes.

- [ ] **Step 3: Audit the publish archive**

Run:

```bash
moon package --list --frozen
find _build/publish -type f -maxdepth 2 -print
unzip -l _build/publish/z2823253773-p-moonrules-0.2.0.zip
shasum -a 256 _build/publish/z2823253773-p-moonrules-0.2.0.zip
```

Audit for credentials, `.env`, `.ai`, `node_modules`, `playground/dist`,
screenshots with private UI, and nested `_build`. Any hit blocks release.

- [ ] **Step 4: Verify a consumer before and after registry publication**

Before publication, use the toolchain-supported workspace/path mechanism if
Task 10 confirmed one; otherwise validate the archive list and public interface.
After publication, the mandatory clean consumer commands are:

```bash
consumer_dir="$(mktemp -d /tmp/moonrules-consumer.XXXXXX)"
moon new "$consumer_dir" --user test --name consumer
cd "$consumer_dir"
moon add z2823253773-p/moonrules@0.2.0
moon check
```

Do not run the registry install before the package exists.

- [ ] **Step 5: Push phase branches and open evidence-rich PRs**

For each phase branch:

```bash
git push -u origin HEAD
gh pr create --fill
gh pr checks --watch
```

PR descriptions must include commands/results and Playground screenshots when
applicable. Merge only green PRs in dependency order: core → CLI → Playground →
evidence/release.

- [ ] **Step 6: Verify main and Pages**

After merges:

```bash
git switch main
git pull --ff-only
gh run list --limit 10
gh run watch
```

Open the public Pages URL and repeat the default coupon Fail smoke. Record the
URL and successful run IDs in `.ai/TASK_STATE.md`.

- [ ] **Step 7: Commit the release candidate metadata**

```bash
git add moon.mod CHANGELOG.md .ai/TASK_STATE.md
git commit -m "chore: prepare MoonRules 0.2.0"
```

Stop and present the complete audit to the user. Do not publish yet.

---

### Task 16: Authorized publication and final freeze

**Files:**
- Modify only if verification finds a truthful release-link correction:
  `README.md`, `README.en.md`, `docs/acceptance-checklist.md`,
  `.ai/TASK_STATE.md`

- [ ] **Step 1: Obtain explicit release confirmation**

Present:

- clean git status,
- commit SHA,
- CI run URLs,
- Pages URL,
- test totals,
- package archive entries/size/SHA-256,
- consumer-test status,
- PDF/GIF/demo status,
- known limitations.

Ask for confirmation to publish
`z2823253773-p/moonrules@0.2.0` and create the GitHub v0.2.0 Release.

- [ ] **Step 2: Publish Mooncakes**

After confirmation:

```bash
moon publish --frozen
```

If isolated frozen verification cannot install pinned dependencies in the same
known way as v0.1.0, stop, show the exact error, re-audit the identical package,
and ask before retrying without `--frozen`.

Expected: server reports success for version `0.2.0`.

- [ ] **Step 3: Run the clean registry consumer smoke**

Use the Task 15 consumer commands. Expected: `moon add` and `moon check` pass.

- [ ] **Step 4: Create the GitHub Release**

Create release notes containing:

```markdown
## Highlights
- Local-only static Playground
- Full, Summary, and Off explainability modes
- CLI JSON/stdin/help/version contract
- Reproducible tests and benchmarks

## Compatibility
V1 DSL, three-state decisions, budgets, and Full Trace remain compatible.

## Links
Playground, Mooncakes, benchmark report, technical report, and changelog.
```

Run:

```bash
gh release create v0.2.0 \
  --title "MoonRules v0.2.0" \
  --notes-file /tmp/moonrules-v0.2.0-release.md
```

- [ ] **Step 5: Final public verification**

Verify:

```bash
gh release view v0.2.0
gh run list --limit 5
git status --short --branch
```

Open and test the Pages URL, Mooncakes docs page, README links, and Release
links. Record verified URLs in `docs/acceptance-checklist.md`.

- [ ] **Step 6: Freeze project state**

Update `.ai/TASK_STATE.md`:

```markdown
MoonRules v0.2.0 is complete: core/CLI/Playground tests green, GitHub Pages
public, Mooncakes 0.2.0 published and consumer-verified, GitHub Release created,
and submission/demo evidence finalized. Further features belong to v0.3.
```

Commit and push only the final evidence-link update:

```bash
git add README.md README.en.md docs/acceptance-checklist.md .ai/TASK_STATE.md
git commit -m "docs: record MoonRules 0.2.0 release evidence"
git push
```

Expected: clean worktree, green main, and no remaining v0.2 task.
