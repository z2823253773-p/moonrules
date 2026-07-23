///|
pub fn parse(source : String) -> Result[RuleDocument, RuleParseError] {
  parse_rule_document(@json.parse(source)) catch {
    error => Err(ExpectedObject("invalid JSON: \{error}"))
  }
}

///|
pub fn check(
  rule : RuleDocument,
  budget? : Budget = Budget::default(),
) -> Array[Diagnostic] {
  check_expr(rule.condition, budget)
}

///|
fn diagnostics_message(diagnostics : Array[Diagnostic]) -> String {
  let out = StringBuilder()
  for index, diagnostic in diagnostics {
    if index > 0 {
      out.write_string("; ")
    }
    out.write_string(
      "\{diagnostic.code} at \{diagnostic.rule_path}: \{diagnostic.message}",
    )
  }
  out.to_string()
}

///|
pub fn evaluate_json(
  rule_source : String,
  data_source : String,
  budget? : Budget = Budget::default(),
  trace_mode? : TraceMode = Full,
) -> Result[EvaluationReport, String] {
  let rule = match parse(rule_source) {
    Ok(value) => value
    Err(error) => return Err("rule parse failed: \{error.message()}")
  }
  let diagnostics = check(rule, budget~)
  if diagnostics.length() > 0 {
    return Err("rule check failed: \{diagnostics_message(diagnostics)}")
  }
  let data = @json.parse(data_source) catch {
    error => return Err("invalid data JSON: \{error}")
  }
  Ok(evaluate(rule, data, budget, trace_mode~))
}
