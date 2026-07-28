# MoonRules API

## `parse`

`parse(source : String) -> Result[RuleDocument, RuleParseError]`

解析规则 JSON 字符串。非法 JSON、缺失顶层字段、未知操作符、多操作符键和错误的 `var`/`literal` 形状会返回结构化错误。

## `check`

`check(rule : RuleDocument, budget? : Budget) -> Array[Diagnostic]`

运行不依赖输入数据的检查。空数组表示通过。诊断按规则树先序输出，包含 `code`、`severity`、`rule_path`、`message` 和 `suggestion`。

## `evaluate`

`evaluate(rule : RuleDocument, data : Json, budget : Budget, trace_mode? : TraceMode) -> EvaluationReport`

执行已解析规则，返回三态 `decision`、按 `TraceMode::Full`、`TraceMode::Summary`
或 `TraceMode::Off` 成形的 `trace`，以及确定性 `stats`。

## `evaluate_json`

`evaluate_json(rule_source : String, data_source : String, budget? : Budget, trace_mode? : TraceMode) -> Result[EvaluationReport, String]`

便利入口，依次完成规则解析、运行前检查、数据 JSON 解析和求值。解析或检查失败返回 `Err`；规则运行时错误保留在 `EvaluationReport.decision` 的 `Indeterminate` 中。

## 输出

- `render_report(report, budget)` 生成受预览长度约束的人类可读树。
- `report_to_json(report)` 生成稳定字段的 JSON：`decision`、`trace`、`stats`。
- `diagnostics_to_json(diagnostics)` serializes every diagnostic as
  `code`, `severity`, `rule_path`, `message`, and `suggestion`. Field names are
  part of the v0.2 public JSON contract.

## Budget

`Budget::default()` 返回深度 64、规则节点 4096、步骤 10000、Trace 节点 4096、预览字符 256。调用方只能降低限制。

## ExecutionStats

- `steps_executed`
- `nodes_evaluated`
- `max_depth_reached`
- `trace_nodes_emitted`

统计不包含墙钟时间、内存地址或其他非确定性信息。
