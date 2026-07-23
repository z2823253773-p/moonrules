///|
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
} derive(Eq, Debug)

///|
pub(all) enum Expr {
  Literal(Json)
  Variable(String)
  Operation(Operator, Array[Expr])
} derive(Eq, Debug)

///|
pub(all) struct RuleDocument {
  id : String
  description : String
  condition : Expr
} derive(Eq, Debug)

///|
pub(all) enum DiagnosticSeverity {
  Error
  Warning
} derive(Eq, Debug)

///|
pub(all) struct Diagnostic {
  code : String
  severity : DiagnosticSeverity
  rule_path : String
  message : String
  suggestion : String
} derive(Eq, Debug)

///|
pub(all) enum EvalError {
  MissingVariable(String)
  TypeMismatch(String)
  BudgetExceeded(String, Int, Int)
  UnsupportedTraceMode(String)
} derive(Eq, Debug)

///|
pub(all) enum Decision {
  Pass
  Fail
  Indeterminate(EvalError)
} derive(Eq, Debug)

///|
pub fn Decision::exit_code(self : Decision) -> Int {
  match self {
    Decision::Pass => 0
    Decision::Fail => 1
    Decision::Indeterminate(_) => 2
  }
}

///|
pub(all) enum TraceStatus {
  Value
  Pass
  Fail
  Error
  Skipped
} derive(Eq, Debug)

///|
pub(all) enum TraceMode {
  Off
  Summary
  Full
} derive(Eq, Debug)

///|
pub(all) struct ResolvedInput {
  source : String
  value : Json
} derive(Eq, Debug)

///|
pub(all) struct TraceNode {
  rule_path : String
  operator : String
  status : TraceStatus
  resolved_inputs : Array[ResolvedInput]
  result : Json?
  message : String
  children : Array[TraceNode]
} derive(Eq, Debug)

///|
pub(all) struct ExecutionStats {
  steps_executed : Int
  nodes_evaluated : Int
  max_depth_reached : Int
  trace_nodes_emitted : Int
} derive(Eq, Debug)

///|
pub(all) struct EvaluationReport {
  decision : Decision
  trace : TraceNode
  stats : ExecutionStats
} derive(Eq, Debug)

///|
pub(all) struct Budget {
  max_depth : Int
  max_rule_nodes : Int
  max_steps : Int
  max_trace_nodes : Int
  max_preview_chars : Int
} derive(Eq, Debug)

///|
pub fn Budget::default() -> Budget {
  {
    max_depth: 64,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
}
