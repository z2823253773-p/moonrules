///|
#derive(Eq, Debug)
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
}

///|
#derive(Eq, Debug)
pub(all) enum Expr {
  Literal(Json)
  Variable(String)
  Operation(Operator, Array[Expr])
}

///|
#derive(Eq, Debug)
pub(all) struct RuleDocument {
  id : String
  description : String
  condition : Expr
}

///|
#derive(Eq, Debug)
pub(all) enum DiagnosticSeverity {
  Error
  Warning
}

///|
#derive(Eq, Debug)
pub(all) struct Diagnostic {
  code : String
  severity : DiagnosticSeverity
  rule_path : String
  message : String
  suggestion : String
}

///|
#derive(Eq, Debug)
pub(all) enum EvalError {
  MissingVariable(String)
  TypeMismatch(String)
  BudgetExceeded(String, Int32, Int32)
  UnsupportedTraceMode(String)
}

///|
#derive(Eq, Debug)
pub(all) enum Decision {
  Pass
  Fail
  Indeterminate(EvalError)
}

///|
pub fn Decision::exit_code(self : Decision) -> Int32 {
  match self {
    Decision::Pass => 0
    Decision::Fail => 1
    Decision::Indeterminate(_) => 2
  }
}

///|
#derive(Eq, Debug)
pub(all) enum TraceStatus {
  Value
  Pass
  Fail
  Error
  Skipped
}

///|
#derive(Eq, Debug)
pub(all) enum TraceMode {
  Off
  Summary
  Full
}

///|
#derive(Eq, Debug)
pub(all) struct ResolvedInput {
  source : String
  value : Json
}

///|
#derive(Eq, Debug)
pub(all) struct TraceNode {
  rule_path : String
  operator : String
  status : TraceStatus
  resolved_inputs : Array[ResolvedInput]
  result : Json?
  message : String
  children : Array[TraceNode]
}

///|
#derive(Eq, Debug)
pub(all) struct ExecutionStats {
  steps_executed : Int32
  nodes_evaluated : Int32
  max_depth_reached : Int32
  trace_nodes_emitted : Int32
}

///|
#derive(Eq, Debug)
pub(all) struct EvaluationReport {
  decision : Decision
  trace : TraceNode
  stats : ExecutionStats
}

///|
#derive(Eq, Debug)
pub(all) struct Budget {
  max_depth : Int32
  max_rule_nodes : Int32
  max_steps : Int32
  max_trace_nodes : Int32
  max_preview_chars : Int32
}

///|
#deprecated
pub extend Operator with Eq::{not_equal, equal}

///|
#deprecated
pub extend Operator with Debug::{to_repr}

///|
#deprecated
pub extend Expr with Eq::{not_equal, equal}

///|
#deprecated
pub extend Expr with Debug::{to_repr}

///|
#deprecated
pub extend RuleDocument with Eq::{not_equal, equal}

///|
#deprecated
pub extend RuleDocument with Debug::{to_repr}

///|
#deprecated
pub extend DiagnosticSeverity with Eq::{not_equal, equal}

///|
#deprecated
pub extend DiagnosticSeverity with Debug::{to_repr}

///|
#deprecated
pub extend Diagnostic with Eq::{not_equal, equal}

///|
#deprecated
pub extend Diagnostic with Debug::{to_repr}

///|
#deprecated
pub extend EvalError with Eq::{not_equal, equal}

///|
#deprecated
pub extend EvalError with Debug::{to_repr}

///|
#deprecated
pub extend Decision with Eq::{not_equal, equal}

///|
#deprecated
pub extend Decision with Debug::{to_repr}

///|
#deprecated
pub extend TraceStatus with Eq::{not_equal, equal}

///|
#deprecated
pub extend TraceStatus with Debug::{to_repr}

///|
#deprecated
pub extend TraceMode with Eq::{not_equal, equal}

///|
#deprecated
pub extend TraceMode with Debug::{to_repr}

///|
#deprecated
pub extend ResolvedInput with Eq::{not_equal, equal}

///|
#deprecated
pub extend ResolvedInput with Debug::{to_repr}

///|
#deprecated
pub extend TraceNode with Eq::{not_equal, equal}

///|
#deprecated
pub extend TraceNode with Debug::{to_repr}

///|
#deprecated
pub extend ExecutionStats with Eq::{not_equal, equal}

///|
#deprecated
pub extend ExecutionStats with Debug::{to_repr}

///|
#deprecated
pub extend EvaluationReport with Eq::{not_equal, equal}

///|
#deprecated
pub extend EvaluationReport with Debug::{to_repr}

///|
#deprecated
pub extend Budget with Eq::{not_equal, equal}

///|
#deprecated
pub extend Budget with Debug::{to_repr}

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
