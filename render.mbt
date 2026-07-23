///|
fn trace_status_text(status : TraceStatus) -> String {
  match status {
    Value => "VALUE"
    Pass => "PASS"
    Fail => "FAIL"
    Error => "ERROR"
    Skipped => "SKIPPED"
  }
}

///|
fn trace_status_json(status : TraceStatus) -> String {
  match status {
    Value => "value"
    Pass => "pass"
    Fail => "fail"
    Error => "error"
    Skipped => "skipped"
  }
}

///|
fn root_message_parts(message : String) -> (String, String) {
  match message.split_once("\n") {
    Some((rule_id, detail)) => (rule_id.to_owned(), detail.to_owned())
    None => (message, "")
  }
}

///|
fn take_chars(text : String, limit : Int) -> String {
  if limit <= 0 {
    return ""
  }
  let out = StringBuilder()
  let mut count = 0
  for character in text {
    if count >= limit {
      break
    }
    out.write_char(character)
    count += 1
  }
  out.to_string()
}

///|
fn preview_json(value : Json, max_chars : Int) -> String {
  let text = value.stringify()
  if text.char_length() <= max_chars {
    text
  } else {
    "\{take_chars(text, max_chars)}…(truncated)"
  }
}

///|
fn node_has_detail(node : TraceNode) -> Bool {
  node.result is Some(_) || node.status == Error || node.status == Skipped
}

///|
fn render_detail(
  out : StringBuilder,
  node : TraceNode,
  prefix : String,
  budget : Budget,
  is_root : Bool,
) -> Unit {
  out.write_string(prefix)
  out.write_string("└─ ")
  match node.status {
    Skipped => out.write_string("reason: \{node.message}")
    Error => {
      let detail = if is_root {
        root_message_parts(node.message).1
      } else {
        node.message
      }
      out.write_string("error: \{detail}")
    }
    _ =>
      match node.result {
        Some(value) =>
          out.write_string(
            "result = \{preview_json(value, budget.max_preview_chars)}",
          )
        None => out.write_string("result = null")
      }
  }
  out.write_char('\n')
}

///|
fn render_node(
  out : StringBuilder,
  node : TraceNode,
  prefix : String,
  is_last : Bool,
  budget : Budget,
  is_root : Bool,
) -> Unit {
  if !is_root {
    out.write_string(prefix)
    out.write_string(if is_last { "└─ " } else { "├─ " })
  }
  out.write_string(trace_status_text(node.status))
  out.write_char(' ')
  if is_root {
    let (rule_id, _) = root_message_parts(node.message)
    out.write_string("\{rule_id} [\{node.operator}]")
  } else {
    out.write_string(node.operator)
  }
  out.write_char('\n')

  let child_prefix = if is_root {
    ""
  } else {
    "\{prefix}\{if is_last { "   " } else { "│  " }}"
  }
  let has_detail = node_has_detail(node)
  for index, child in node.children {
    let child_is_last = index == node.children.length() - 1 && !has_detail
    render_node(out, child, child_prefix, child_is_last, budget, false)
  }
  if has_detail {
    render_detail(out, node, child_prefix, budget, is_root)
  }
}

///|
pub fn render_report(report : EvaluationReport, budget : Budget) -> String {
  let out = StringBuilder()
  render_node(out, report.trace, "", true, budget, true)
  let text = out.to_string()
  if text.has_suffix("\n") {
    text[:text.length() - 1].to_owned()
  } else {
    text
  }
}

///|
fn eval_error_to_json(error : EvalError) -> Json {
  match error {
    MissingVariable(path) =>
      Json::object({
        "type": Json::string("missing_variable"),
        "path": Json::string(path),
      })
    TypeMismatch(message) =>
      Json::object({
        "type": Json::string("type_mismatch"),
        "message": Json::string(message),
      })
    BudgetExceeded(kind, current, limit) =>
      Json::object({
        "type": Json::string("budget_exceeded"),
        "budget": Json::string(kind),
        "current": Json::number(current.to_double()),
        "limit": Json::number(limit.to_double()),
      })
    UnsupportedTraceMode(mode) =>
      Json::object({
        "type": Json::string("unsupported_trace_mode"),
        "mode": Json::string(mode),
      })
  }
}

///|
fn decision_to_json(decision : Decision) -> Json {
  match decision {
    Decision::Pass => Json::object({ "status": Json::string("pass") })
    Decision::Fail => Json::object({ "status": Json::string("fail") })
    Decision::Indeterminate(error) =>
      Json::object({
        "status": Json::string("indeterminate"),
        "error": eval_error_to_json(error),
      })
  }
}

///|
fn resolved_input_to_json(input : ResolvedInput) -> Json {
  Json::object({ "source": Json::string(input.source), "value": input.value })
}

///|
fn trace_to_json(node : TraceNode) -> Json {
  let result = match node.result {
    Some(value) => value
    None => Json::null()
  }
  Json::object({
    "rule_path": Json::string(node.rule_path),
    "operator": Json::string(node.operator),
    "status": Json::string(trace_status_json(node.status)),
    "resolved_inputs": Json::array(
      node.resolved_inputs.map(resolved_input_to_json),
    ),
    "result": result,
    "message": Json::string(node.message),
    "children": Json::array(node.children.map(trace_to_json)),
  })
}

///|
pub fn report_to_json(report : EvaluationReport) -> Json {
  Json::object({
    "decision": decision_to_json(report.decision),
    "trace": trace_to_json(report.trace),
    "stats": Json::object({
      "steps_executed": Json::number(report.stats.steps_executed.to_double()),
      "nodes_evaluated": Json::number(report.stats.nodes_evaluated.to_double()),
      "max_depth_reached": Json::number(
        report.stats.max_depth_reached.to_double(),
      ),
      "trace_nodes_emitted": Json::number(
        report.stats.trace_nodes_emitted.to_double(),
      ),
    }),
  })
}
