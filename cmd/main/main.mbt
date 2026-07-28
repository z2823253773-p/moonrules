///|
async fn read_source(path : String) -> Result[String, String] {
  if path == "-" {
    Ok(@stdio.stdin.read_all().text()) catch {
      error => Err("failed to read stdin: \{error}")
    }
  } else {
    Ok(@fs.read_file(path).text()) catch {
      error => Err("failed to read \{path}: \{error}")
    }
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
async fn run_check(rule_path : String, mode : OutputMode) -> Int {
  let rule_source = match read_source(rule_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  let rule = match @moonrules.parse(rule_source) {
    Ok(value) => value
    Err(error) => {
      let message = "rule parse failed: \{error.message()}"
      if mode == OutputMode::Json {
        @stdio.stdout.write("\{cli_error_json("E_RULE_PARSE", message)}\n")
      } else {
        @stdio.stderr.write("\{message}\n")
      }
      return 2
    }
  }
  let diagnostics = @moonrules.check(rule)
  if mode == OutputMode::Json {
    @stdio.stdout.write("\{cli_check_json(diagnostics)}\n")
  } else if diagnostics.length() == 0 {
    @stdio.stdout.write("MoonRules check: OK\n")
  } else {
    @stdio.stderr.write(diagnostics_text(diagnostics))
  }
  if diagnostics.length() == 0 {
    0
  } else {
    2
  }
}

///|
async fn run_eval(
  rule_path : String,
  data_path : String,
  mode : OutputMode,
) -> Int {
  let rule_source = match read_source(rule_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  let data_source = match read_source(data_path) {
    Ok(value) => value
    Err(message) => {
      @stdio.stderr.write("\{message}\n")
      return 2
    }
  }
  match @moonrules.evaluate_json(rule_source, data_source) {
    Err(message) => {
      if mode == OutputMode::Json {
        @stdio.stdout.write("\{cli_error_json("E_EVALUATE_INPUT", message)}\n")
      } else {
        @stdio.stderr.write("\{message}\n")
      }
      2
    }
    Ok(report) => {
      if mode == OutputMode::Json {
        @stdio.stdout.write("\{cli_report_json(report)}\n")
      } else {
        @stdio.stdout.write(
          "\{@moonrules.render_report(report, @moonrules.Budget::default())}\n",
        )
      }
      report.decision.exit_code()
    }
  }
}

///|
async fn main {
  let arguments = @sys.get_cli_args()
  let code = match parse_cli(arguments[1:]) {
    Err(CliParseError::DualStdin) => {
      @stdio.stderr.write("rule and data cannot both use stdin\n")
      2
    }
    Err(CliParseError::Usage) => {
      @stdio.stderr.write(usage())
      2
    }
    Ok(CliConfig::Help) => {
      @stdio.stdout.write(usage())
      0
    }
    Ok(CliConfig::Version) => {
      @stdio.stdout.write("moonrules 0.2.0\n")
      0
    }
    Ok(CliConfig::Check(rule_path, mode)) => run_check(rule_path, mode)
    Ok(CliConfig::Eval(rule_path, data_path, mode)) =>
      run_eval(rule_path, data_path, mode)
  }
  @sys.exit(code)
}
