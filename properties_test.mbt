///|
fn evaluate_property_expr(
  expr : @moonrules.Expr,
) -> @moonrules.EvaluationReport {
  @moonrules.evaluate_condition(
    expr,
    Json::empty_object(),
    @moonrules.Budget::default(),
  )
}

///|
fn trace_node_count(node : @moonrules.TraceNode) -> Int32 {
  let mut count = 1
  for child in node.children {
    count += trace_node_count(child)
  }
  count
}

///|
test "property: double negation preserves booleans" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::Not, [
      @moonrules.Expr::Operation(@moonrules.Operator::Not, [
        @moonrules.Expr::Literal(Json::boolean(value)),
      ]),
    ])
    let expected = if value {
      @moonrules.Decision::Pass
    } else {
      @moonrules.Decision::Fail
    }
    @test.assert_eq(evaluate_property_expr(expr).decision, expected)
  }
}

///|
test "property: evaluation is deterministic" {
  let values : Array[Int32] = @quickcheck.samples(100)
  for value in values {
    let json = Json::number(value.to_double())
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::Equal, [
      @moonrules.Expr::Literal(json),
      @moonrules.Expr::Literal(json),
    ])
    let first = evaluate_property_expr(expr)
    let second = evaluate_property_expr(expr)
    @test.assert_eq(first, second)
  }
}

///|
test "property: and false short-circuits every later node" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
      @moonrules.Expr::Literal(Json::boolean(value)),
      @moonrules.Expr::Literal(Json::boolean(false)),
      @moonrules.Expr::Variable("must.not.execute"),
    ])
    let report = evaluate_property_expr(expr)
    @test.assert_eq(report.decision, @moonrules.Decision::Fail)
    @test.assert_eq(
      report.trace.children[2].status,
      @moonrules.TraceStatus::Skipped,
    )
  }
}

///|
test "property: or true short-circuits every later node" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::Or, [
      @moonrules.Expr::Literal(Json::boolean(value)),
      @moonrules.Expr::Literal(Json::boolean(true)),
      @moonrules.Expr::Variable("must.not.execute"),
    ])
    let report = evaluate_property_expr(expr)
    @test.assert_eq(report.decision, @moonrules.Decision::Pass)
    @test.assert_eq(
      report.trace.children[2].status,
      @moonrules.TraceStatus::Skipped,
    )
  }
}

///|
test "property: missing variables are deterministic errors" {
  let names : Array[String] = @quickcheck.samples(100)
  for raw_name in names {
    let name = if raw_name == "" || raw_name.contains(".") {
      "missing"
    } else {
      raw_name
    }
    let expr = @moonrules.Expr::Variable(name)
    let first = evaluate_property_expr(expr)
    let second = evaluate_property_expr(expr)
    @test.assert_eq(first, second)
    assert_true(first.decision is @moonrules.Decision::Indeterminate(_))
  }
}

///|
test "property: depth budget always returns a structured error" {
  let values : Array[Bool] = @quickcheck.samples(50)
  for value in values {
    let budget : @moonrules.Budget = {
      max_depth: 1,
      max_rule_nodes: 4096,
      max_steps: 10000,
      max_trace_nodes: 4096,
      max_preview_chars: 256,
    }
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::Not, [
      @moonrules.Expr::Literal(Json::boolean(value)),
    ])
    let report = @moonrules.evaluate_condition(
      expr,
      Json::empty_object(),
      budget,
    )
    assert_true(
      report.decision
      is @moonrules.Decision::Indeterminate(BudgetExceeded("max_depth", _, _)),
    )
  }
}

///|
test "property: rule node budget always returns a structured error" {
  let values : Array[Bool] = @quickcheck.samples(50)
  for value in values {
    let budget : @moonrules.Budget = {
      max_depth: 64,
      max_rule_nodes: 1,
      max_steps: 10000,
      max_trace_nodes: 4096,
      max_preview_chars: 256,
    }
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
      @moonrules.Expr::Literal(Json::boolean(value)),
      @moonrules.Expr::Literal(Json::boolean(true)),
    ])
    let report = @moonrules.evaluate_condition(
      expr,
      Json::empty_object(),
      budget,
    )
    assert_true(
      report.decision
      is @moonrules.Decision::Indeterminate(
        BudgetExceeded("max_rule_nodes", _, _)
      ),
    )
  }
}

///|
test "property: step budget always returns a structured error" {
  let values : Array[Bool] = @quickcheck.samples(50)
  for value in values {
    let budget : @moonrules.Budget = {
      max_depth: 64,
      max_rule_nodes: 4096,
      max_steps: 1,
      max_trace_nodes: 4096,
      max_preview_chars: 256,
    }
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::Not, [
      @moonrules.Expr::Literal(Json::boolean(value)),
    ])
    let report = @moonrules.evaluate_condition(
      expr,
      Json::empty_object(),
      budget,
    )
    assert_true(
      report.decision
      is @moonrules.Decision::Indeterminate(BudgetExceeded("max_steps", _, _)),
    )
  }
}

///|
test "property: trace budget uses its final slot for an error" {
  let values : Array[Bool] = @quickcheck.samples(50)
  for value in values {
    let budget : @moonrules.Budget = {
      max_depth: 64,
      max_rule_nodes: 4096,
      max_steps: 10000,
      max_trace_nodes: 2,
      max_preview_chars: 256,
    }
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::Not, [
      @moonrules.Expr::Literal(Json::boolean(value)),
    ])
    let report = @moonrules.evaluate_condition(
      expr,
      Json::empty_object(),
      budget,
    )
    assert_true(
      report.decision
      is @moonrules.Decision::Indeterminate(
        BudgetExceeded("max_trace_nodes", _, _)
      ),
    )
    @test.assert_eq(report.stats.trace_nodes_emitted, 2)
  }
}

///|
test "property: trace modes preserve decisions and reduce output" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::And, [
      @moonrules.Expr::Literal(Json::boolean(value)),
      @moonrules.Expr::Literal(Json::boolean(true)),
    ])
    let full = @moonrules.evaluate_condition(
      expr,
      Json::empty_object(),
      @moonrules.Budget::default(),
      trace_mode=Full,
    )
    let summary = @moonrules.evaluate_condition(
      expr,
      Json::empty_object(),
      @moonrules.Budget::default(),
      trace_mode=Summary,
    )
    let off = @moonrules.evaluate_condition(
      expr,
      Json::empty_object(),
      @moonrules.Budget::default(),
      trace_mode=Off,
    )
    @test.assert_eq(full.decision, summary.decision)
    @test.assert_eq(full.decision, off.decision)
    assert_true(trace_node_count(summary.trace) <= trace_node_count(full.trace))
    @test.assert_eq(trace_node_count(off.trace), 1)
  }
}

///|
test "property: JSON deep equality is reflexive for strings" {
  let values : Array[String] = @quickcheck.samples(100)
  for value in values {
    let json = Json::string(value)
    assert_true(@moonrules.json_deep_equal(json, json))
  }
}

///|
test "property: JSON deep equality is symmetric" {
  let left_values : Array[Int32] = @quickcheck.samples(100)
  let right_values : Array[Int32] = @quickcheck.samples(100)
  for index, left in left_values {
    let a = Json::number(left.to_double())
    let b = Json::number(right_values[index].to_double())
    @test.assert_eq(
      @moonrules.json_deep_equal(a, b),
      @moonrules.json_deep_equal(b, a),
    )
  }
}

///|
test "property: greater-than reverses to less-than" {
  let left_values : Array[Int32] = @quickcheck.samples(100)
  let right_values : Array[Int32] = @quickcheck.samples(100)
  for index, left in left_values {
    let right = right_values[index]
    let a = Json::number(left.to_double())
    let b = Json::number(right.to_double())
    let greater = evaluate_property_expr(
      @moonrules.Expr::Operation(@moonrules.Operator::GreaterThan, [
        @moonrules.Expr::Literal(a),
        @moonrules.Expr::Literal(b),
      ]),
    )
    let less = evaluate_property_expr(
      @moonrules.Expr::Operation(@moonrules.Operator::LessThan, [
        @moonrules.Expr::Literal(b),
        @moonrules.Expr::Literal(a),
      ]),
    )
    @test.assert_eq(greater.decision, less.decision)
  }
}

///|
test "property: an inserted JSON string is always in its array" {
  let values : Array[String] = @quickcheck.samples(100)
  for value in values {
    let json = Json::string(value)
    let report = evaluate_property_expr(
      @moonrules.Expr::Operation(@moonrules.Operator::In, [
        @moonrules.Expr::Literal(json),
        @moonrules.Expr::Literal(Json::array([json])),
      ]),
    )
    @test.assert_eq(report.decision, @moonrules.Decision::Pass)
  }
}

///|
test "property: every string contains itself" {
  let values : Array[String] = @quickcheck.samples(100)
  for value in values {
    let json = Json::string(value)
    let report = evaluate_property_expr(
      @moonrules.Expr::Operation(@moonrules.Operator::Contains, [
        @moonrules.Expr::Literal(json),
        @moonrules.Expr::Literal(json),
      ]),
    )
    @test.assert_eq(report.decision, @moonrules.Decision::Pass)
  }
}

///|
test "property: every string starts and ends with itself" {
  let values : Array[String] = @quickcheck.samples(100)
  for value in values {
    let json = Json::string(value)
    let starts = evaluate_property_expr(
      @moonrules.Expr::Operation(@moonrules.Operator::StartsWith, [
        @moonrules.Expr::Literal(json),
        @moonrules.Expr::Literal(json),
      ]),
    )
    let ends = evaluate_property_expr(
      @moonrules.Expr::Operation(@moonrules.Operator::EndsWith, [
        @moonrules.Expr::Literal(json),
        @moonrules.Expr::Literal(json),
      ]),
    )
    @test.assert_eq(starts.decision, @moonrules.Decision::Pass)
    @test.assert_eq(ends.decision, @moonrules.Decision::Pass)
  }
}

///|
test "property: checker and report JSON are deterministic" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let expr = @moonrules.Expr::Operation(@moonrules.Operator::Not, [
      @moonrules.Expr::Literal(Json::boolean(value)),
    ])
    let first_diagnostics = @moonrules.check_expr(
      expr,
      @moonrules.Budget::default(),
    )
    let second_diagnostics = @moonrules.check_expr(
      expr,
      @moonrules.Budget::default(),
    )
    @test.assert_eq(first_diagnostics, second_diagnostics)
    let report = evaluate_property_expr(expr)
    @test.assert_eq(
      @moonrules.report_to_json(report),
      @moonrules.report_to_json(report),
    )
  }
}

///|
test "property: report and diagnostic JSON round-trip through text" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let report = @moonrules.evaluate_condition(
      @moonrules.Expr::Literal(Json::boolean(value)),
      Json::empty_object(),
      @moonrules.Budget::default(),
    )
    let report_text = @moonrules.report_to_json(report).stringify()
    @test.assert_eq(@json.parse(report_text), @moonrules.report_to_json(report))
    let diagnostics = @moonrules.check_expr(
      @moonrules.Expr::Operation(@moonrules.Operator::And, []),
      @moonrules.Budget::default(),
    )
    let diagnostic_text = @moonrules.diagnostics_to_json(diagnostics).stringify()
    @test.assert_eq(
      @json.parse(diagnostic_text),
      @moonrules.diagnostics_to_json(diagnostics),
    )
  }
}
