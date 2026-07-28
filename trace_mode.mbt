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
