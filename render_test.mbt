///|
fn coupon_report_for_test() -> EvaluationReport raise {
  let rule_source = "{\"id\":\"student-coupon\",\"description\":\"coupon\",\"condition\":{\"and\":[{\">=\":[{\"var\":\"user.age\"},18]},{\"==\":[{\"var\":\"user.role\"},\"student\"]},{\">=\":[{\"var\":\"order.total\"},100]}]}}"
  let rule = match parse_rule_document(@json.parse(rule_source)) {
    Ok(value) => value
    Err(_) => fail("coupon rule must parse")
  }
  let data = @json.parse(
    "{\"user\":{\"age\":20,\"role\":\"guest\"},\"order\":{\"total\":128}}",
  )
  evaluate(rule, data, Budget::default())
}

///|
test "coupon text trace is stable and explainable" {
  let report = coupon_report_for_test()
  let expected =
    #|FAIL student-coupon [and]
    #|├─ PASS >=
    #|│  ├─ VALUE var(user.age)
    #|│  │  └─ result = 20
    #|│  ├─ VALUE literal
    #|│  │  └─ result = 18
    #|│  └─ result = true
    #|├─ FAIL ==
    #|│  ├─ VALUE var(user.role)
    #|│  │  └─ result = "guest"
    #|│  ├─ VALUE literal
    #|│  │  └─ result = "student"
    #|│  └─ result = false
    #|├─ SKIPPED >=
    #|│  └─ reason: and short-circuited
    #|└─ result = false
  @test.assert_eq(render_report(report, Budget::default()), expected)
}

///|
test "structured report JSON exposes decision trace and stats" {
  let json = report_to_json(coupon_report_for_test())
  guard json is Object(fields) else { fail("report JSON must be an object") }
  debug_inspect(fields.contains("decision"), content="true")
  debug_inspect(fields.contains("trace"), content="true")
  debug_inspect(fields.contains("stats"), content="true")
  guard fields.get("stats") is Some(Object(stats)) else {
    fail("stats must be an object")
  }
  debug_inspect(stats.contains("steps_executed"), content="true")
  debug_inspect(stats.contains("nodes_evaluated"), content="true")
  debug_inspect(stats.contains("max_depth_reached"), content="true")
  debug_inspect(stats.contains("trace_nodes_emitted"), content="true")
}

///|
test "text rendering truncates long JSON previews" {
  let long_value = Expr::Literal(@json.parse("\"abcdefghij\""))
  let report = evaluate_condition(
    Expr::Operation(Operator::Equal, [long_value, long_value]),
    Json::empty_object(),
    Budget::default(),
  )
  let budget : Budget = {
    max_depth: 64,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 5,
  }
  debug_inspect(
    render_report(report, budget).contains("…(truncated)"),
    content="true",
  )
}

///|
test "public facade parses checks and evaluates JSON sources" {
  let rule_source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"==\":[1,1.0]}}"
  match parse(rule_source) {
    Ok(rule) => debug_inspect(check(rule), content="[]")
    Err(_) => fail("valid rule must parse")
  }
  match evaluate_json(rule_source, "{}") {
    Ok(report) => debug_inspect(report.decision, content="Pass")
    Err(_) => fail("valid rule and data must evaluate")
  }
  debug_inspect(parse("{") is Err(_), content="true")
}
