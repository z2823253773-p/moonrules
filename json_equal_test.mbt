///|
test "object equality ignores key order and numeric representation" {
  let left = @json.parse("{\"a\":1,\"b\":2}")
  let right = @json.parse("{\"b\":2.0,\"a\":1.0}")
  debug_inspect(json_deep_equal(left, right), content="true")
}

///|
test "array equality is ordered and recursive" {
  let same = json_deep_equal(
    @json.parse("[1,{\"x\":true},null]"),
    @json.parse("[1.0,{\"x\":true},null]"),
  )
  let reordered = json_deep_equal(@json.parse("[1,2]"), @json.parse("[2,1]"))
  debug_inspect(same, content="true")
  debug_inspect(reordered, content="false")
}

///|
test "object equality requires identical key sets" {
  debug_inspect(
    json_deep_equal(@json.parse("{\"a\":1}"), @json.parse("{\"a\":1,\"b\":2}")),
    content="false",
  )
  debug_inspect(
    json_deep_equal(@json.parse("{\"a\":1}"), @json.parse("{\"b\":1}")),
    content="false",
  )
}

///|
test "primitive equality never coerces JSON types" {
  debug_inspect(
    json_deep_equal(@json.parse("null"), @json.parse("null")),
    content="true",
  )
  debug_inspect(
    json_deep_equal(@json.parse("null"), @json.parse("false")),
    content="false",
  )
  debug_inspect(
    json_deep_equal(@json.parse("\"1\""), @json.parse("1")),
    content="false",
  )
  debug_inspect(
    json_deep_equal(@json.parse("\"moon\""), @json.parse("\"moon\"")),
    content="true",
  )
}
