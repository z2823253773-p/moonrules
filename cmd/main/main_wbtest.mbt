///|
test "parse check command" {
  debug_inspect(
    parse_cli(["check", "rule.json"]),
    content="Ok(Check(\"rule.json\"))",
  )
}

///|
test "parse eval command" {
  debug_inspect(
    parse_cli(["eval", "rule.json", "--data", "data.json"]),
    content="Ok(Eval(\"rule.json\", \"data.json\"))",
  )
}

///|
test "reject incomplete and unknown commands" {
  debug_inspect(parse_cli(["eval", "rule.json"]), content="Err(Usage)")
  debug_inspect(parse_cli(["serve"]), content="Err(Usage)")
}
