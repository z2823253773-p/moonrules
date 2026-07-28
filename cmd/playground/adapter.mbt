///|
priv struct AdapterOptions {
  trace_mode : @moonrules.TraceMode
  budget : @moonrules.Budget
}

///|
fn adapter_error(code : String, message : String) -> String {
  Json::object({
    "ok": Json::boolean(false),
    "kind": Json::string("input_error"),
    "report": Json::null(),
    "diagnostics": Json::array([
      Json::object({
        "code": Json::string(code),
        "severity": Json::string("error"),
        "rule_path": Json::string("$"),
        "message": Json::string(message),
        "suggestion": Json::string("correct the input and try again"),
      }),
    ]),
  }).stringify()
}

///|
fn option_int(
  fields : Map[String, Json],
  name : String,
  default : Int,
) -> Result[Int, String] {
  match fields.get(name) {
    None => Ok(default)
    Some(Number(value, ..)) => {
      let integer = value.to_int()
      if integer <= 0 || integer.to_double() != value {
        Err("budget.\{name} must be a positive integer")
      } else {
        Ok(integer)
      }
    }
    Some(_) => Err("budget.\{name} must be a positive integer")
  }
}

///|
fn parse_options(source : String) -> Result[AdapterOptions, String] {
  let json = @json.parse(source) catch {
    error => return Err("invalid options JSON: \{error}")
  }
  guard json is Object(fields) else {
    return Err("options must be a JSON object")
  }
  for key, _ in fields {
    if key != "trace_mode" && key != "budget" {
      return Err("unknown option: \{key}")
    }
  }
  let trace_mode = match fields.get("trace_mode") {
    None | Some(String("full")) => @moonrules.TraceMode::Full
    Some(String("summary")) => @moonrules.TraceMode::Summary
    Some(String("off")) => @moonrules.TraceMode::Off
    Some(_) => return Err("trace_mode must be full, summary, or off")
  }
  let defaults = @moonrules.Budget::default()
  let budget = match fields.get("budget") {
    None => defaults
    Some(Object(budget_fields)) => {
      for key, _ in budget_fields {
        if key != "max_depth" &&
          key != "max_nodes" &&
          key != "max_steps" &&
          key != "max_trace_nodes" &&
          key != "max_value_preview" {
          return Err("unknown budget option: \{key}")
        }
      }
      let max_depth = match
        option_int(budget_fields, "max_depth", defaults.max_depth) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let max_rule_nodes = match
        option_int(budget_fields, "max_nodes", defaults.max_rule_nodes) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let max_steps = match
        option_int(budget_fields, "max_steps", defaults.max_steps) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let max_trace_nodes = match
        option_int(budget_fields, "max_trace_nodes", defaults.max_trace_nodes) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let max_preview_chars = match
        option_int(
          budget_fields,
          "max_value_preview",
          defaults.max_preview_chars,
        ) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      {
        max_depth,
        max_rule_nodes,
        max_steps,
        max_trace_nodes,
        max_preview_chars,
      }
    }
    Some(_) => return Err("budget must be a JSON object")
  }
  let diagnostics = @moonrules.validate_budget(budget)
  if diagnostics.length() > 0 {
    return Err(diagnostics[0].message)
  }
  Ok({ trace_mode, budget })
}

///|
fn check_response(diagnostics : Array[@moonrules.Diagnostic]) -> String {
  Json::object({
    "ok": Json::boolean(true),
    "kind": Json::string("check"),
    "report": Json::null(),
    "diagnostics": @moonrules.diagnostics_to_json(diagnostics),
  }).stringify()
}

///|
pub fn check_json(rule_source : String, options_source : String) -> String {
  let options = match parse_options(options_source) {
    Ok(value) => value
    Err(message) => return adapter_error("E_OPTIONS", message)
  }
  match @moonrules.parse(rule_source) {
    Err(error) => adapter_error("E_RULE_PARSE", error.message())
    Ok(rule) => check_response(@moonrules.check(rule, budget=options.budget))
  }
}

///|
pub fn evaluate_json(
  rule_source : String,
  data_source : String,
  options_source : String,
) -> String {
  let options = match parse_options(options_source) {
    Ok(value) => value
    Err(message) => return adapter_error("E_OPTIONS", message)
  }
  let rule = match @moonrules.parse(rule_source) {
    Err(error) => return adapter_error("E_RULE_PARSE", error.message())
    Ok(value) => value
  }
  let diagnostics = @moonrules.check(rule, budget=options.budget)
  if diagnostics.length() > 0 {
    return check_response(diagnostics)
  }
  let data = @json.parse(data_source) catch {
    error => return adapter_error("E_DATA_JSON", "\{error}")
  }
  let report = @moonrules.evaluate(
    rule,
    data,
    options.budget,
    trace_mode=options.trace_mode,
  )
  Json::object({
    "ok": Json::boolean(true),
    "kind": Json::string("evaluation"),
    "report": @moonrules.report_to_json(report),
    "diagnostics": Json::array([]),
  }).stringify()
}
