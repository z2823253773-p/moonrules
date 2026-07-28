///|
fn evaluate_property_expr(expr : Expr) -> EvaluationReport {
  evaluate_condition(expr, Json::empty_object(), Budget::default())
}

///|
fn trace_node_count(node : TraceNode) -> Int {
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
    let expr = Expr::Operation(Operator::Not, [
      Expr::Operation(Operator::Not, [Expr::Literal(Json::boolean(value))]),
    ])
    let expected = if value { Decision::Pass } else { Decision::Fail }
    @test.assert_eq(evaluate_property_expr(expr).decision, expected)
  }
}

///|
test "property: evaluation is deterministic" {
  let values : Array[Int] = @quickcheck.samples(100)
  for value in values {
    let json = Json::number(value.to_double())
    let expr = Expr::Operation(Operator::Equal, [
      Expr::Literal(json),
      Expr::Literal(json),
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
    let expr = Expr::Operation(Operator::And, [
      Expr::Literal(Json::boolean(value)),
      Expr::Literal(Json::boolean(false)),
      Expr::Variable("must.not.execute"),
    ])
    let report = evaluate_property_expr(expr)
    @test.assert_eq(report.decision, Decision::Fail)
    @test.assert_eq(report.trace.children[2].status, TraceStatus::Skipped)
  }
}

///|
test "property: or true short-circuits every later node" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let expr = Expr::Operation(Operator::Or, [
      Expr::Literal(Json::boolean(value)),
      Expr::Literal(Json::boolean(true)),
      Expr::Variable("must.not.execute"),
    ])
    let report = evaluate_property_expr(expr)
    @test.assert_eq(report.decision, Decision::Pass)
    @test.assert_eq(report.trace.children[2].status, TraceStatus::Skipped)
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
    let expr = Expr::Variable(name)
    let first = evaluate_property_expr(expr)
    let second = evaluate_property_expr(expr)
    @test.assert_eq(first, second)
    assert_true(first.decision is Decision::Indeterminate(_))
  }
}

///|
test "property: depth budget always returns a structured error" {
  let values : Array[Bool] = @quickcheck.samples(50)
  for value in values {
    let budget : Budget = {
      max_depth: 1,
      max_rule_nodes: 4096,
      max_steps: 10000,
      max_trace_nodes: 4096,
      max_preview_chars: 256,
    }
    let expr = Expr::Operation(Operator::Not, [
      Expr::Literal(Json::boolean(value)),
    ])
    let report = evaluate_condition(expr, Json::empty_object(), budget)
    assert_true(
      report.decision
      is Decision::Indeterminate(BudgetExceeded("max_depth", _, _)),
    )
  }
}

///|
test "property: rule node budget always returns a structured error" {
  let values : Array[Bool] = @quickcheck.samples(50)
  for value in values {
    let budget : Budget = {
      max_depth: 64,
      max_rule_nodes: 1,
      max_steps: 10000,
      max_trace_nodes: 4096,
      max_preview_chars: 256,
    }
    let expr = Expr::Operation(Operator::And, [
      Expr::Literal(Json::boolean(value)),
      Expr::Literal(Json::boolean(true)),
    ])
    let report = evaluate_condition(expr, Json::empty_object(), budget)
    assert_true(
      report.decision
      is Decision::Indeterminate(BudgetExceeded("max_rule_nodes", _, _)),
    )
  }
}

///|
test "property: step budget always returns a structured error" {
  let values : Array[Bool] = @quickcheck.samples(50)
  for value in values {
    let budget : Budget = {
      max_depth: 64,
      max_rule_nodes: 4096,
      max_steps: 1,
      max_trace_nodes: 4096,
      max_preview_chars: 256,
    }
    let expr = Expr::Operation(Operator::Not, [
      Expr::Literal(Json::boolean(value)),
    ])
    let report = evaluate_condition(expr, Json::empty_object(), budget)
    assert_true(
      report.decision
      is Decision::Indeterminate(BudgetExceeded("max_steps", _, _)),
    )
  }
}

///|
test "property: trace budget uses its final slot for an error" {
  let values : Array[Bool] = @quickcheck.samples(50)
  for value in values {
    let budget : Budget = {
      max_depth: 64,
      max_rule_nodes: 4096,
      max_steps: 10000,
      max_trace_nodes: 2,
      max_preview_chars: 256,
    }
    let expr = Expr::Operation(Operator::Not, [
      Expr::Literal(Json::boolean(value)),
    ])
    let report = evaluate_condition(expr, Json::empty_object(), budget)
    assert_true(
      report.decision
      is Decision::Indeterminate(BudgetExceeded("max_trace_nodes", _, _)),
    )
    @test.assert_eq(report.stats.trace_nodes_emitted, 2)
  }
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

///|
test "property: JSON deep equality is reflexive for strings" {
  let values : Array[String] = @quickcheck.samples(100)
  for value in values {
    let json = Json::string(value)
    assert_true(json_deep_equal(json, json))
  }
}

///|
test "property: JSON deep equality is symmetric" {
  let left_values : Array[Int] = @quickcheck.samples(100)
  let right_values : Array[Int] = @quickcheck.samples(100)
  for index, left in left_values {
    let a = Json::number(left.to_double())
    let b = Json::number(right_values[index].to_double())
    @test.assert_eq(json_deep_equal(a, b), json_deep_equal(b, a))
  }
}

///|
test "property: greater-than reverses to less-than" {
  let left_values : Array[Int] = @quickcheck.samples(100)
  let right_values : Array[Int] = @quickcheck.samples(100)
  for index, left in left_values {
    let right = right_values[index]
    let a = Json::number(left.to_double())
    let b = Json::number(right.to_double())
    let greater = evaluate_property_expr(
      Expr::Operation(Operator::GreaterThan, [
        Expr::Literal(a),
        Expr::Literal(b),
      ]),
    )
    let less = evaluate_property_expr(
      Expr::Operation(Operator::LessThan, [Expr::Literal(b), Expr::Literal(a)]),
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
      Expr::Operation(Operator::In, [
        Expr::Literal(json),
        Expr::Literal(Json::array([json])),
      ]),
    )
    @test.assert_eq(report.decision, Decision::Pass)
  }
}

///|
test "property: every string contains itself" {
  let values : Array[String] = @quickcheck.samples(100)
  for value in values {
    let json = Json::string(value)
    let report = evaluate_property_expr(
      Expr::Operation(Operator::Contains, [
        Expr::Literal(json),
        Expr::Literal(json),
      ]),
    )
    @test.assert_eq(report.decision, Decision::Pass)
  }
}

///|
test "property: every string starts and ends with itself" {
  let values : Array[String] = @quickcheck.samples(100)
  for value in values {
    let json = Json::string(value)
    let starts = evaluate_property_expr(
      Expr::Operation(Operator::StartsWith, [
        Expr::Literal(json),
        Expr::Literal(json),
      ]),
    )
    let ends = evaluate_property_expr(
      Expr::Operation(Operator::EndsWith, [
        Expr::Literal(json),
        Expr::Literal(json),
      ]),
    )
    @test.assert_eq(starts.decision, Decision::Pass)
    @test.assert_eq(ends.decision, Decision::Pass)
  }
}

///|
test "property: checker and report JSON are deterministic" {
  let values : Array[Bool] = @quickcheck.samples(100)
  for value in values {
    let expr = Expr::Operation(Operator::Not, [
      Expr::Literal(Json::boolean(value)),
    ])
    let first_diagnostics = check_expr(expr, Budget::default())
    let second_diagnostics = check_expr(expr, Budget::default())
    @test.assert_eq(first_diagnostics, second_diagnostics)
    let report = evaluate_property_expr(expr)
    @test.assert_eq(report_to_json(report), report_to_json(report))
  }
}
