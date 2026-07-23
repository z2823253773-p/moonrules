///|
test "rule path uses fields and indexes consistently" {
  let path = RulePath::root()
    .field("condition")
    .field("and")
    .index(1)
    .field("==")
    .index(0)
    .field("var")
  debug_inspect(path.to_string(), content="\"condition.and[1].==[0].var\"")
}

///|
test "data path reads nested object fields" {
  let data = @json.parse("{\"user\":{\"age\":20}}")
  debug_inspect(resolve_data_path(data, "user.age"), content="Ok(Number(20))")
}

///|
test "data path rejects V2 syntax" {
  debug_inspect(
    parse_data_path("items[0].price"),
    content="Err(InvalidDataPath(\"items[0].price\"))",
  )
  debug_inspect(
    parse_data_path("user..age"),
    content="Err(InvalidDataPath(\"user..age\"))",
  )
}

///|
test "data path distinguishes missing and non-object segments" {
  let data = @json.parse("{\"user\":{\"age\":20},\"active\":true}")
  debug_inspect(
    resolve_data_path(data, "user.role"),
    content="Err(MissingDataPath(\"user.role\"))",
  )
  debug_inspect(
    resolve_data_path(data, "active.value"),
    content="Err(NonObjectSegment(\"value\"))",
  )
}
