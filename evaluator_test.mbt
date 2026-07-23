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
