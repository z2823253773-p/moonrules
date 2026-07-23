///|
test "parse coupon rule" {
  let source = "{\"id\":\"student-coupon\",\"description\":\"adult student\",\"condition\":{\"and\":[{\">=\":[{\"var\":\"user.age\"},18]},{\"==\":[{\"var\":\"user.role\"},\"student\"]}]}}"
  let json = @json.parse(source)
  match parse_rule_document(json) {
    Ok(rule) => {
      debug_inspect(rule.id, content="\"student-coupon\"")
      debug_inspect(rule.condition is Operation(And, _), content="true")
    }
    Err(_) => fail("unexpected parse error")
  }
}

///|
test "reject object with multiple operator keys" {
  let source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"and\":[],\"or\":[]}}"
  let json = @json.parse(source)
  debug_inspect(
    parse_rule_document(json),
    content="Err(MultipleOperatorKeys(\"condition\"))",
  )
}

///|
test "reject malformed var and unwrapped object literal" {
  let bad_var_source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"var\":42}}"
  let bad_var = @json.parse(bad_var_source)
  debug_inspect(
    parse_rule_document(bad_var),
    content="Err(InvalidVariable(\"condition.var\"))",
  )
  let object_literal_source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"country\":\"CN\"}}"
  let object_literal = @json.parse(object_literal_source)
  debug_inspect(
    parse_rule_document(object_literal),
    content="Err(UnknownOperator(\"country\"))",
  )
}

///|
test "parse literal object wrapper and primitive array literals" {
  let object_source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"literal\":{\"country\":\"CN\"}}}"
  match parse_rule_document(@json.parse(object_source)) {
    Ok(rule) =>
      debug_inspect(rule.condition is Literal(Object(_)), content="true")
    Err(_) => fail("unexpected parse error")
  }
  let array_source = "{\"id\":\"x\",\"description\":\"x\",\"condition\":[1,\"student\",true]}"
  match parse_rule_document(@json.parse(array_source)) {
    Ok(rule) =>
      debug_inspect(rule.condition is Literal(Array(_)), content="true")
    Err(_) => fail("unexpected parse error")
  }
}

///|
test "reject missing and wrongly typed document fields" {
  let missing_source = "{\"id\":\"x\",\"description\":\"x\"}"
  debug_inspect(
    parse_rule_document(@json.parse(missing_source)),
    content="Err(MissingField(\"condition\"))",
  )
  let bad_id_source = "{\"id\":42,\"description\":\"x\",\"condition\":true}"
  debug_inspect(
    parse_rule_document(@json.parse(bad_id_source)),
    content="Err(ExpectedString(\"id\"))",
  )
}
