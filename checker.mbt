///|
fn operator_name(operator : Operator) -> String {
  match operator {
    And => "and"
    Or => "or"
    Not => "not"
    Equal => "=="
    NotEqual => "!="
    GreaterThan => ">"
    GreaterOrEqual => ">="
    LessThan => "<"
    LessOrEqual => "<="
    In => "in"
    Contains => "contains"
    StartsWith => "starts_with"
    EndsWith => "ends_with"
  }
}

///|
fn valid_arity(operator : Operator, count : Int) -> Bool {
  match operator {
    And | Or => count >= 1
    Not => count == 1
    Equal
    | NotEqual
    | GreaterThan
    | GreaterOrEqual
    | LessThan
    | LessOrEqual
    | In
    | Contains
    | StartsWith
    | EndsWith => count == 2
  }
}

///|
fn arity_message(operator : Operator, count : Int) -> (String, String) {
  let name = operator_name(operator)
  match operator {
    And | Or =>
      (
        "operator \{name} expects at least 1 argument, received \{count}",
        "provide at least 1 argument",
      )
    _ =>
      (
        "operator \{name} expects \{if operator == Not { 1 } else { 2 }} arguments, received \{count}",
        "provide exactly \{if operator == Not { 1 } else { 2 }} arguments",
      )
  }
}

///|
fn diagnostic(
  code : String,
  rule_path : String,
  message : String,
  suggestion : String,
) -> Diagnostic {
  { code, severity: Error, rule_path, message, suggestion }
}

///|
fn add_literal_type_diagnostic(
  out : Array[Diagnostic],
  path : RulePath,
  expected : String,
) -> Unit {
  out.push(
    diagnostic(
      "E_LITERAL_TYPE",
      path.to_string(),
      "literal operand must be \{expected}",
      "replace the literal or use a variable with a \{expected} value",
    ),
  )
}

///|
fn check_literal_operand_types(
  operator : Operator,
  arguments : Array[Expr],
  operation_path : RulePath,
  out : Array[Diagnostic],
) -> Unit {
  match operator {
    GreaterThan | GreaterOrEqual | LessThan | LessOrEqual =>
      for index, argument in arguments {
        if argument is Literal(value) && !(value is Number(_)) {
          add_literal_type_diagnostic(
            out,
            operation_path.index(index),
            "a number",
          )
        }
      }
    Contains | StartsWith | EndsWith =>
      for index, argument in arguments {
        if argument is Literal(value) && !(value is String(_)) {
          add_literal_type_diagnostic(
            out,
            operation_path.index(index),
            "a string",
          )
        }
      }
    In =>
      if arguments.length() >= 2 {
        let candidate = arguments[1]
        if candidate is Literal(value) && !(value is Array(_)) {
          add_literal_type_diagnostic(out, operation_path.index(1), "an array")
        }
      }
    And | Or | Not =>
      for index, argument in arguments {
        if argument is Literal(value) && !(value is True) && !(value is False) {
          add_literal_type_diagnostic(
            out,
            operation_path.index(index),
            "a boolean",
          )
        }
      }
    Equal | NotEqual => ()
  }
}

///|
pub fn validate_budget(budget : Budget) -> Array[Diagnostic] {
  let maximum = Budget::default()
  let diagnostics : Array[Diagnostic] = []
  fn check_limit(
    diagnostics : Array[Diagnostic],
    field : String,
    supplied : Int,
    allowed : Int,
  ) -> Unit {
    if supplied > allowed {
      diagnostics.push(
        diagnostic(
          "E_BUDGET_LIMIT",
          "budget.\{field}",
          "budget \{field} cannot exceed the library ceiling of \{allowed}; received \{supplied}",
          "lower \{field} to \{allowed} or less",
        ),
      )
    }
  }

  check_limit(diagnostics, "max_depth", budget.max_depth, maximum.max_depth)
  check_limit(
    diagnostics,
    "max_rule_nodes",
    budget.max_rule_nodes,
    maximum.max_rule_nodes,
  )
  check_limit(diagnostics, "max_steps", budget.max_steps, maximum.max_steps)
  check_limit(
    diagnostics,
    "max_trace_nodes",
    budget.max_trace_nodes,
    maximum.max_trace_nodes,
  )
  check_limit(
    diagnostics,
    "max_preview_chars",
    budget.max_preview_chars,
    maximum.max_preview_chars,
  )
  diagnostics
}

///|
pub fn check_expr(expr : Expr, budget : Budget) -> Array[Diagnostic] {
  let diagnostics = validate_budget(budget)
  let count : Ref[Int] = Ref(0)
  check_node(
    expr,
    RulePath::root().field("condition"),
    1,
    count,
    budget,
    diagnostics,
  )
  diagnostics
}

///|
fn check_node(
  expr : Expr,
  path : RulePath,
  depth : Int,
  count : Ref[Int],
  budget : Budget,
  out : Array[Diagnostic],
) -> Unit {
  count.val += 1
  if depth > budget.max_depth {
    out.push(
      diagnostic(
        "E_MAX_DEPTH",
        path.to_string(),
        "rule depth \{depth} exceeds the configured maximum of \{budget.max_depth}",
        "reduce rule nesting or raise the caller limit within the library ceiling",
      ),
    )
  }
  if count.val > budget.max_rule_nodes {
    out.push(
      diagnostic(
        "E_MAX_RULE_NODES",
        path.to_string(),
        "rule node count exceeds the configured maximum of \{budget.max_rule_nodes}",
        "remove rule nodes or raise the caller limit within the library ceiling",
      ),
    )
  }
  match expr {
    Literal(_) => ()
    Variable(data_path) =>
      if parse_data_path(data_path) is Err(_) {
        out.push(
          diagnostic(
            "E_DATA_PATH",
            path.field("var").to_string(),
            "V1 data paths only support dot-separated object fields",
            "replace \{data_path} with an object-field path",
          ),
        )
      }
    Operation(operator, arguments) => {
      let operation_path = path.field(operator_name(operator))
      if !valid_arity(operator, arguments.length()) {
        let (message, suggestion) = arity_message(operator, arguments.length())
        out.push(
          diagnostic("E_ARITY", operation_path.to_string(), message, suggestion),
        )
      }
      check_literal_operand_types(operator, arguments, operation_path, out)
      for index, argument in arguments {
        check_node(
          argument,
          operation_path.index(index),
          depth + 1,
          count,
          budget,
          out,
        )
      }
    }
  }
}
