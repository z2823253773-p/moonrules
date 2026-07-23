///|
pub(all) enum CliConfig {
  Check(String)
  Eval(String, String)
} derive(Eq, Debug)

///|
pub(all) enum CliParseError {
  Usage
} derive(Eq, Debug)

///|
pub fn parse_cli(
  arguments : ArrayView[String],
) -> Result[CliConfig, CliParseError] {
  match arguments {
    ["check", rule_path] => Ok(Check(rule_path))
    ["eval", rule_path, "--data", data_path] => Ok(Eval(rule_path, data_path))
    _ => Err(Usage)
  }
}

///|
fn usage() -> String {
  "Usage:\n  moonrules check <rule.json>\n  moonrules eval <rule.json> --data <data.json>\n"
}

///|
async fn read_text(path : String) -> Result[String, String] {
  Ok(@fs.read_file(path).text()) catch {
    error => Err("failed to read \{path}: \{error}")
  }
}

///|
fn diagnostics_text(diagnostics : Array[@moonrules.Diagnostic]) -> String {
  let out = StringBuilder()
  for diagnostic in diagnostics {
    out.write_string(
      "\{diagnostic.code} \{diagnostic.rule_path}: \{diagnostic.message}\n",
    )
    if diagnostic.suggestion != "" {
      out.write_string("  suggestion: \{diagnostic.suggestion}\n")
    }
  }
  out.to_string()
}

///|
async fn run_check(rule_path : String) -> Int {
  let rule_source = match read_text(rule_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  let rule = match @moonrules.parse(rule_source) {
    Ok(value) => value
    Err(error) => {
      @stdio.stderr.write("rule parse failed: \{error.message()}\n")
      return 2
    }
  }
  let diagnostics = @moonrules.check(rule)
  if diagnostics.length() == 0 {
    @stdio.stdout.write("MoonRules check: OK\n")
    0
  } else {
    @stdio.stderr.write(diagnostics_text(diagnostics))
    2
  }
}

///|
async fn run_eval(rule_path : String, data_path : String) -> Int {
  let rule_source = match read_text(rule_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  let data_source = match read_text(data_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  match @moonrules.evaluate_json(rule_source, data_source) {
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      2
    }
    Ok(report) => {
      @stdio.stdout.write(
        "\{@moonrules.render_report(report, @moonrules.Budget::default())}\n",
      )
      report.decision.exit_code()
    }
  }
}

///|
async fn main {
  let arguments = @sys.get_cli_args()
  let code = match parse_cli(arguments[1:]) {
    Err(Usage) => {
      @stdio.stderr.write(usage())
      2
    }
    Ok(Check(rule_path)) => run_check(rule_path)
    Ok(Eval(rule_path, data_path)) => run_eval(rule_path, data_path)
  }
  @sys.exit(code)
}
