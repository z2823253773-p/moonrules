///|
test "coupon trace has independent variable and literal nodes" {
  let source = "{\"id\":\"student-coupon\",\"description\":\"adult students\",\"condition\":{\">=\":[{\"var\":\"user.age\"},18]}}"
  let rule = match @moonrules.parse_rule_document(@json.parse(source)) {
    Ok(value) => value
    Err(_) => fail("test rule must parse")
  }
  let data = @json.parse("{\"user\":{\"age\":20}}")
  let report = @moonrules.evaluate(rule, data, @moonrules.Budget::default())
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
  let rule = match @moonrules.parse_rule_document(@json.parse(source)) {
    Ok(value) => value
    Err(_) => fail("test rule must parse")
  }
  let report = @moonrules.evaluate(
    rule,
    Json::empty_object(),
    @moonrules.Budget::default(),
  )
  debug_inspect(
    report.decision,
    content="Indeterminate(MissingVariable(\"user.age\"))",
  )
  debug_inspect(report.trace.status, content="Error")
}

///|
test "minimal and short-circuits after false" {
  let source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"and\":[{\">=\":[1,2]},{\"var\":\"never\"}]}}"
  let rule = match @moonrules.parse_rule_document(@json.parse(source)) {
    Ok(value) => value
    Err(_) => fail("test rule must parse")
  }
  let report = @moonrules.evaluate(
    rule,
    Json::empty_object(),
    @moonrules.Budget::default(),
  )
  debug_inspect(report.decision, content="Fail")
  debug_inspect(report.trace.children.length(), content="2")
  debug_inspect(report.trace.children[1].status, content="Skipped")
}

///|
test "and false dominates earlier error" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
    @moonrules.Expr::Variable("missing"),
    @moonrules.Expr::Literal(Json::boolean(false)),
    @moonrules.Expr::Variable("never"),
  ])
  let report = @moonrules.evaluate_condition(
    expr,
    Json::empty_object(),
    @moonrules.Budget::default(),
  )
  debug_inspect(report.decision, content="Fail")
  debug_inspect(report.trace.children[0].status, content="Error")
  debug_inspect(report.trace.children[1].status, content="Value")
  debug_inspect(report.trace.children[2].status, content="Skipped")
}

///|
test "or true dominates earlier error" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::Or, [
    @moonrules.Expr::Variable("missing"),
    @moonrules.Expr::Literal(Json::boolean(true)),
    @moonrules.Expr::Variable("never"),
  ])
  let report = @moonrules.evaluate_condition(
    expr,
    Json::empty_object(),
    @moonrules.Budget::default(),
  )
  debug_inspect(report.decision, content="Pass")
  debug_inspect(report.trace.children[0].status, content="Error")
  debug_inspect(report.trace.children[2].status, content="Skipped")
}

///|
test "error remains indeterminate without decisive boolean" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
    @moonrules.Expr::Literal(Json::boolean(true)),
    @moonrules.Expr::Variable("missing"),
  ])
  debug_inspect(
    @moonrules.evaluate_condition(
      expr,
      Json::empty_object(),
      @moonrules.Budget::default(),
    ).decision,
    content="Indeterminate(MissingVariable(\"missing\"))",
  )
}

///|
test "not inverts booleans and preserves errors" {
  let false_expr = @moonrules.Expr::Operation(@moonrules.Operator::Not, [
    @moonrules.Expr::Literal(Json::boolean(true)),
  ])
  debug_inspect(
    @moonrules.evaluate_condition(
      false_expr,
      Json::empty_object(),
      @moonrules.Budget::default(),
    ).decision,
    content="Fail",
  )
  let error_expr = @moonrules.Expr::Operation(@moonrules.Operator::Not, [
    @moonrules.Expr::Variable("missing"),
  ])
  debug_inspect(
    @moonrules.evaluate_condition(
      error_expr,
      Json::empty_object(),
      @moonrules.Budget::default(),
    ).decision,
    content="Indeterminate(MissingVariable(\"missing\"))",
  )
}

///|
test "summary removes ordinary value leaves but keeps decisions" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::GreaterOrEqual, [
    @moonrules.Expr::Variable("user.age"),
    @moonrules.Expr::Literal(Json::number(18.0)),
  ])
  let data = @json.parse("{\"user\":{\"age\":20}}")
  let full = @moonrules.evaluate_condition(
    expr,
    data,
    @moonrules.Budget::default(),
    trace_mode=Full,
  )
  let summary = @moonrules.evaluate_condition(
    expr,
    data,
    @moonrules.Budget::default(),
    trace_mode=Summary,
  )
  @test.assert_eq(summary.decision, full.decision)
  @test.assert_eq(summary.trace.children.length(), 0)
  @test.assert_eq(summary.trace.resolved_inputs.length(), 2)
}

///|
test "summary keeps error and skipped nodes" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
    @moonrules.Expr::Variable("missing"),
    @moonrules.Expr::Literal(Json::boolean(false)),
    @moonrules.Expr::Variable("never"),
  ])
  let report = @moonrules.evaluate_condition(
    expr,
    Json::empty_object(),
    @moonrules.Budget::default(),
    trace_mode=Summary,
  )
  @test.assert_eq(report.decision, @moonrules.Decision::Fail)
  @test.assert_eq(
    report.trace.children[0].status,
    @moonrules.TraceStatus::Error,
  )
  @test.assert_eq(
    report.trace.children[1].status,
    @moonrules.TraceStatus::Skipped,
  )
}

///|
test "off returns one root and preserves report semantics" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::Equal, [
    @moonrules.Expr::Literal(Json::number(1.0)),
    @moonrules.Expr::Literal(Json::number(1.0)),
  ])
  let full = @moonrules.evaluate_condition(
    expr,
    Json::empty_object(),
    @moonrules.Budget::default(),
  )
  let off = @moonrules.evaluate_condition(
    expr,
    Json::empty_object(),
    @moonrules.Budget::default(),
    trace_mode=Off,
  )
  @test.assert_eq(off.decision, full.decision)
  @test.assert_eq(off.stats, full.stats)
  @test.assert_eq(off.trace.children.length(), 0)
  @test.assert_eq(off.trace.resolved_inputs.length(), 0)
}

///|
test "max depth budget keeps a partial error trace" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::Not, [
    @moonrules.Expr::Literal(Json::boolean(true)),
  ])
  let budget : @moonrules.Budget = {
    max_depth: 1,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
  let report = @moonrules.evaluate_condition(expr, Json::empty_object(), budget)
  debug_inspect(
    report.decision,
    content="Indeterminate(BudgetExceeded(\"max_depth\", 2, 1))",
  )
  debug_inspect(report.trace.children[0].status, content="Error")
}

///|
test "rule node budget stops before executing later nodes" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
    @moonrules.Expr::Literal(Json::boolean(true)),
    @moonrules.Expr::Literal(Json::boolean(true)),
  ])
  let budget : @moonrules.Budget = {
    max_depth: 64,
    max_rule_nodes: 1,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
  let report = @moonrules.evaluate_condition(expr, Json::empty_object(), budget)
  debug_inspect(
    report.decision,
    content="Indeterminate(BudgetExceeded(\"max_rule_nodes\", 2, 1))",
  )
  debug_inspect(report.trace.children.length(), content="1")
}

///|
test "step budget is enforced independently" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
    @moonrules.Expr::Literal(Json::boolean(true)),
    @moonrules.Expr::Literal(Json::boolean(true)),
  ])
  let budget : @moonrules.Budget = {
    max_depth: 64,
    max_rule_nodes: 4096,
    max_steps: 1,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
  let report = @moonrules.evaluate_condition(expr, Json::empty_object(), budget)
  debug_inspect(
    report.decision,
    content="Indeterminate(BudgetExceeded(\"max_steps\", 2, 1))",
  )
  debug_inspect(report.stats.steps_executed, content="1")
}

///|
test "trace budget reserves its final slot for truncation error" {
  let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
    @moonrules.Expr::Literal(Json::boolean(true)),
    @moonrules.Expr::Literal(Json::boolean(true)),
    @moonrules.Expr::Literal(Json::boolean(true)),
  ])
  let budget : @moonrules.Budget = {
    max_depth: 64,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 3,
    max_preview_chars: 256,
  }
  let report = @moonrules.evaluate_condition(expr, Json::empty_object(), budget)
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

///|
fn evaluate_binary_for_test(
  operator : @moonrules.Operator,
  left : String,
  right : String,
) -> @moonrules.EvaluationReport raise {
  @moonrules.evaluate_condition(
    @moonrules.Expr::Operation(operator, [
      @moonrules.Expr::Literal(@json.parse(left)),
      @moonrules.Expr::Literal(@json.parse(right)),
    ]),
    Json::empty_object(),
    @moonrules.Budget::default(),
  )
}

///|
test "equality and inequality accept every JSON type" {
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::Equal,
      "{\"a\":1}",
      "{\"a\":1.0}",
    ).decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(@moonrules.Operator::NotEqual, "[1,2]", "[2,1]").decision,
    content="Pass",
  )
}

///|
test "all ordered comparisons use strict numeric semantics" {
  debug_inspect(
    evaluate_binary_for_test(@moonrules.Operator::GreaterThan, "3", "2").decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(@moonrules.Operator::GreaterOrEqual, "2", "2.0").decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(@moonrules.Operator::LessThan, "2", "3").decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(@moonrules.Operator::LessOrEqual, "2", "2").decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(@moonrules.Operator::GreaterThan, "2", "3").decision,
    content="Fail",
  )
}

///|
test "ordered comparison rejects cross-type coercion" {
  debug_inspect(
    evaluate_binary_for_test(@moonrules.Operator::GreaterThan, "\"3\"", "2").decision,
    content="Indeterminate(TypeMismatch(\"numeric comparison requires two numbers\"))",
  )
}

///|
test "in uses JSON deep equality for array membership" {
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::In,
      "\"admin\"",
      "[\"viewer\",\"admin\"]",
    ).decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::In,
      "{\"a\":1}",
      "[{\"a\":1.0}]",
    ).decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::In,
      "\"owner\"",
      "[\"viewer\",\"admin\"]",
    ).decision,
    content="Fail",
  )
}

///|
test "in rejects non-array haystacks" {
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::In,
      "\"admin\"",
      "\"administrator\"",
    ).decision,
    content="Indeterminate(TypeMismatch(\"in requires an array as its second argument\"))",
  )
}

///|
test "contains is a strict string operator" {
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::Contains,
      "\"moonrules\"",
      "\"rules\"",
    ).decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::Contains,
      "\"moonrules\"",
      "\"sun\"",
    ).decision,
    content="Fail",
  )
  debug_inspect(
    evaluate_binary_for_test(@moonrules.Operator::Contains, "[1,2]", "1").decision,
    content="Indeterminate(TypeMismatch(\"string operator requires two strings\"))",
  )
}

///|
test "starts_with and ends_with are strict string operators" {
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::StartsWith,
      "\"moonrules\"",
      "\"moon\"",
    ).decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::StartsWith,
      "\"moonrules\"",
      "\"rules\"",
    ).decision,
    content="Fail",
  )
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::EndsWith,
      "\"moonrules\"",
      "\"rules\"",
    ).decision,
    content="Pass",
  )
  debug_inspect(
    evaluate_binary_for_test(
      @moonrules.Operator::EndsWith,
      "\"moonrules\"",
      "\"moon\"",
    ).decision,
    content="Fail",
  )
}
