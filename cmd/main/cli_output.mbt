///|
pub fn cli_error_json(code : String, message : String) -> String {
  Json::object({
    "ok": Json::boolean(false),
    "code": Json::string(code),
    "message": Json::string(message),
  }).stringify()
}

///|
fn cli_check_json(diagnostics : Array[@moonrules.Diagnostic]) -> String {
  Json::object({
    "ok": Json::boolean(diagnostics.length() == 0),
    "kind": Json::string("check"),
    "diagnostics": @moonrules.diagnostics_to_json(diagnostics),
  }).stringify()
}

///|
fn cli_report_json(report : @moonrules.EvaluationReport) -> String {
  Json::object({
    "ok": Json::boolean(true),
    "kind": Json::string("evaluation"),
    "report": @moonrules.report_to_json(report),
  }).stringify()
}
