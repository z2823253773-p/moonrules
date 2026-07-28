///|
test "parse check human and JSON commands" {
  @test.assert_eq(
    parse_cli(["check", "rule.json"]),
    Ok(CliConfig::Check("rule.json", OutputMode::Human)),
  )
  @test.assert_eq(
    parse_cli(["check", "rule.json", "--json"]),
    Ok(CliConfig::Check("rule.json", OutputMode::Json)),
  )
}

///|
test "parse eval file and stdin commands" {
  @test.assert_eq(
    parse_cli(["eval", "rule.json", "--data", "data.json", "--json"]),
    Ok(CliConfig::Eval("rule.json", "data.json", OutputMode::Json)),
  )
  @test.assert_eq(
    parse_cli(["eval", "-", "--data", "data.json"]),
    Ok(CliConfig::Eval("-", "data.json", OutputMode::Human)),
  )
}

///|
test "parse help and version" {
  @test.assert_eq(parse_cli(["--help"]), Ok(CliConfig::Help))
  @test.assert_eq(parse_cli(["--version"]), Ok(CliConfig::Version))
}

///|
test "reject ambiguous dual stdin and bad commands" {
  @test.assert_eq(
    parse_cli(["eval", "-", "--data", "-"]),
    Err(CliParseError::DualStdin),
  )
  @test.assert_eq(parse_cli(["eval", "rule.json"]), Err(CliParseError::Usage))
}

///|
test "CLI JSON errors are machine-readable" {
  @test.assert_eq(
    @json.parse(cli_error_json("E_USAGE", "bad arguments")),
    @json.parse(
      "{\"ok\":false,\"code\":\"E_USAGE\",\"message\":\"bad arguments\"}",
    ),
  )
}
