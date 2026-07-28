///|
test "check adapter returns diagnostics envelope" {
  let response = @json.parse(
    check_json(
      "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"and\":[]}}", "{}",
    ),
  )
  guard response is Object(fields) else { fail("response must be object") }
  @test.assert_eq(fields.get("ok"), Some(Json::boolean(true)))
  @test.assert_eq(fields.get("kind"), Some(Json::string("check")))
}

///|
test "evaluate adapter preserves fail as a successful evaluation" {
  let response = @json.parse(
    evaluate_json(
      "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"==\":[1,2]}}", "{}",
      "{\"trace_mode\":\"off\"}",
    ),
  )
  guard response is Object(fields) else { fail("response must be object") }
  @test.assert_eq(fields.get("ok"), Some(Json::boolean(true)))
  @test.assert_eq(fields.get("kind"), Some(Json::string("evaluation")))
  guard fields.get("report") is Some(Object(report)) else {
    fail("report must be object")
  }
  guard report.get("trace") is Some(Object(trace)) else {
    fail("trace must be object")
  }
  @test.assert_eq(trace.get("children"), Some(Json::array([])))
}

///|
test "adapter rejects invalid options as input_error" {
  let response = @json.parse(check_json("{}", "{\"trace_mode\":\"wide\"}"))
  guard response is Object(fields) else { fail("response must be object") }
  @test.assert_eq(fields.get("ok"), Some(Json::boolean(false)))
  @test.assert_eq(fields.get("kind"), Some(Json::string("input_error")))
}

///|
test "adapter rejects over-ceiling budget as input_error" {
  let response = @json.parse(
    check_json(
      "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"and\":[]}}", "{\"budget\":{\"max_nodes\":4097}}",
    ),
  )
  guard response is Object(fields) else { fail("response must be object") }
  @test.assert_eq(fields.get("ok"), Some(Json::boolean(false)))
  @test.assert_eq(fields.get("kind"), Some(Json::string("input_error")))
}

///|
test "adapter rejects unknown option fields" {
  let response = @json.parse(
    evaluate_json(
      "{\"id\":\"x\",\"description\":\"x\",\"condition\":{\"==\":[1,1]}}", "{}",
      "{\"trace_mode\":\"full\",\"extra\":true}",
    ),
  )
  guard response is Object(fields) else { fail("response must be object") }
  @test.assert_eq(fields.get("ok"), Some(Json::boolean(false)))
  @test.assert_eq(fields.get("kind"), Some(Json::string("input_error")))
}
