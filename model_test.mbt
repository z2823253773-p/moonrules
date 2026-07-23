///|
test "default budget is locked" {
  let budget = Budget::default()
  debug_inspect(
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
  debug_inspect(Decision::Fail, content="Fail")
  debug_inspect(
    Decision::Indeterminate(EvalError::MissingVariable("user.age")),
    content="Indeterminate(MissingVariable(\"user.age\"))",
  )
}

///|
test "V1 exposes trace modes but implements full only" {
  debug_inspect(
    [TraceMode::Off, TraceMode::Summary, TraceMode::Full],
    content="[Off, Summary, Full]",
  )
}
