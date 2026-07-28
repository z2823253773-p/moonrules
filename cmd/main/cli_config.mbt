///|
pub(all) enum OutputMode {
  Human
  Json
} derive(Eq, Debug)

///|
pub(all) enum CliConfig {
  Check(String, OutputMode)
  Eval(String, String, OutputMode)
  Help
  Version
} derive(Eq, Debug)

///|
pub(all) enum CliParseError {
  Usage
  DualStdin
} derive(Eq, Debug)

///|
fn mode_from_suffix(arguments : ArrayView[String]) -> OutputMode {
  if arguments.length() > 0 && arguments[arguments.length() - 1] == "--json" {
    OutputMode::Json
  } else {
    OutputMode::Human
  }
}

///|
pub fn parse_cli(
  arguments : ArrayView[String],
) -> Result[CliConfig, CliParseError] {
  let mode = mode_from_suffix(arguments)
  match arguments {
    ["check", rule_path] => Ok(CliConfig::Check(rule_path, OutputMode::Human))
    ["check", rule_path, "--json"] =>
      Ok(CliConfig::Check(rule_path, OutputMode::Json))
    ["eval", rule_path, "--data", data_path] =>
      if rule_path == "-" && data_path == "-" {
        Err(CliParseError::DualStdin)
      } else {
        Ok(CliConfig::Eval(rule_path, data_path, OutputMode::Human))
      }
    ["eval", rule_path, "--data", data_path, "--json"] =>
      if rule_path == "-" && data_path == "-" {
        Err(CliParseError::DualStdin)
      } else {
        Ok(CliConfig::Eval(rule_path, data_path, mode))
      }
    ["--help"] | ["-h"] => Ok(CliConfig::Help)
    ["--version"] | ["-V"] => Ok(CliConfig::Version)
    _ => Err(CliParseError::Usage)
  }
}

///|
fn usage() -> String {
  "Usage:\n  moonrules check <rule.json|-> [--json]\n  moonrules eval <rule.json|-> --data <data.json|-> [--json]\n  moonrules --help\n  moonrules --version\n"
}
