///|
test "coupon trace has independent variable and literal nodes" {
  let source = "{\"id\":\"student-coupon\",\"description\":\"adult students\",\"condition\":{\">=\":[{\"var\":\"user.age\"},18]}}"
  let rule = match parse_rule_document(@json.parse(source)) {
    Ok(value) => value
    Err(_) => fail("test rule must parse")
  }
  let data = @json.parse("{\"user\":{\"age\":20}}")
  let report = evaluate(rule, data, Budget::default())
  debug_inspect(report.decision, content="Pass")
  debug_inspect(report.trace.children.length(), content="2")
  debug_inspect(report.trace.children[0].status, content="Value")
  debug_inspect(report.trace.children[0].result, content="Some(Number(20))")
  debug_inspect(report.trace.children[1].status, content="Value")
  debug_inspect(report.trace.children[1].result, content="Some(Number(18))")
}

///|
test "minimal evaluator reports missing variable" {
  let source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\">=\":[{\"var\":\"user.age\"},18]}}"
  let rule = match parse_rule_document(@json.parse(source)) {
    Ok(value) => value
    Err(_) => fail("test rule must parse")
  }
  let report = evaluate(rule, Json::empty_object(), Budget::default())
  debug_inspect(
    report.decision,
    content="Indeterminate(MissingVariable(\"user.age\"))",
  )
  debug_inspect(report.trace.status, content="Error")
}

///|
test "minimal and short-circuits after false" {
  let source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"and\":[{\">=\":[1,2]},{\"var\":\"never\"}]}}"
  let rule = match parse_rule_document(@json.parse(source)) {
    Ok(value) => value
    Err(_) => fail("test rule must parse")
  }
  let report = evaluate(rule, Json::empty_object(), Budget::default())
  debug_inspect(report.decision, content="Fail")
  debug_inspect(report.trace.children.length(), content="2")
  debug_inspect(report.trace.children[1].status, content="Skipped")
}

///|
test "and false dominates earlier error" {
  let expr = Expr::Operation(Operator::And, [
    Expr::Variable("missing"),
    Expr::Literal(Json::boolean(false)),
    Expr::Variable("never"),
  ])
  let report = evaluate_condition(expr, Json::empty_object(), Budget::default())
  debug_inspect(report.decision, content="Fail")
  debug_inspect(report.trace.children[0].status, content="Error")
  debug_inspect(report.trace.children[1].status, content="Value")
  debug_inspect(report.trace.children[2].status, content="Skipped")
}

///|
test "or true dominates earlier error" {
  let expr = Expr::Operation(Operator::Or, [
    Expr::Variable("missing"),
    Expr::Literal(Json::boolean(true)),
    Expr::Variable("never"),
  ])
  let report = evaluate_condition(expr, Json::empty_object(), Budget::default())
  debug_inspect(report.decision, content="Pass")
  debug_inspect(report.trace.children[0].status, content="Error")
  debug_inspect(report.trace.children[2].status, content="Skipped")
}

///|
test "error remains indeterminate without decisive boolean" {
  let expr = Expr::Operation(Operator::And, [
    Expr::Literal(Json::boolean(true)),
    Expr::Variable("missing"),
  ])
  debug_inspect(
    evaluate_condition(expr, Json::empty_object(), Budget::default()).decision,
    content="Indeterminate(MissingVariable(\"missing\"))",
  )
}

///|
test "not inverts booleans and preserves errors" {
  let false_expr = Expr::Operation(Operator::Not, [
    Expr::Literal(Json::boolean(true)),
  ])
  debug_inspect(
    evaluate_condition(false_expr, Json::empty_object(), Budget::default()).decision,
    content="Fail",
  )
  let error_expr = Expr::Operation(Operator::Not, [Expr::Variable("missing")])
  debug_inspect(
    evaluate_condition(error_expr, Json::empty_object(), Budget::default()).decision,
    content="Indeterminate(MissingVariable(\"missing\"))",
  )
}

///|
test "V1 rejects unimplemented trace modes explicitly" {
  let expr = Expr::Literal(Json::boolean(true))
  debug_inspect(
    evaluate_condition(
      expr,
      Json::empty_object(),
      Budget::default(),
      trace_mode=TraceMode::Off,
    ).decision,
    content="Indeterminate(UnsupportedTraceMode(\"Off\"))",
  )
}

///|
test "max depth budget keeps a partial error trace" {
  let expr = Expr::Operation(Operator::Not, [Expr::Literal(Json::boolean(true))])
  let budget : Budget = {
    max_depth: 1,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
  let report = evaluate_condition(expr, Json::empty_object(), budget)
  debug_inspect(
    report.decision,
    content="Indeterminate(BudgetExceeded(\"max_depth\", 2, 1))",
  )
  debug_inspect(report.trace.children[0].status, content="Error")
}

///|
test "rule node budget stops before executing later nodes" {
  let expr = Expr::Operation(Operator::And, [
    Expr::Literal(Json::boolean(true)),
    Expr::Literal(Json::boolean(true)),
  ])
  let budget : Budget = {
    max_depth: 64,
    max_rule_nodes: 1,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
  let report = evaluate_condition(expr, Json::empty_object(), budget)
  debug_inspect(
    report.decision,
    content="Indeterminate(BudgetExceeded(\"max_rule_nodes\", 2, 1))",
  )
  debug_inspect(report.trace.children.length(), content="1")
}

///|
test "step budget is enforced independently" {
  let expr = Expr::Operation(Operator::And, [
    Expr::Literal(Json::boolean(true)),
    Expr::Literal(Json::boolean(true)),
  ])
  let budget : Budget = {
    max_depth: 64,
    max_rule_nodes: 4096,
    max_steps: 1,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
  let report = evaluate_condition(expr, Json::empty_object(), budget)
  debug_inspect(
    report.decision,
    content="Indeterminate(BudgetExceeded(\"max_steps\", 2, 1))",
  )
  debug_inspect(report.stats.steps_executed, content="1")
}

///|
test "trace budget reserves its final slot for truncation error" {
  let expr = Expr::Operation(Operator::And, [
    Expr::Literal(Json::boolean(true)),
    Expr::Literal(Json::boolean(true)),
    Expr::Literal(Json::boolean(true)),
  ])
  let budget : Budget = {
    max_depth: 64,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 3,
    max_preview_chars: 256,
  }
  let report = evaluate_condition(expr, Json::empty_object(), budget)
  debug_inspect(
    report.decision,
    content="Indeterminate(BudgetExceeded(\"max_trace_nodes\", 3, 3))",
  )
  debug_inspect(report.trace.children.length(), content="2")
  debug_inspect(report.trace.children[1].status, content="Error")
  debug_inspect(
    report.trace.children[1].message.contains("max_trace_nodes"),
    content="true",
  )
  debug_inspect(report.stats.trace_nodes_emitted, content="3")
}
