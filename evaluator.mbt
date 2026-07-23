///|
priv struct EvalContext {
  budget : Budget
  mut steps : Int
  mut nodes : Int
  mut max_depth : Int
  mut trace_nodes : Int
}

///|
priv struct EvalNodeResult {
  value : Result[Json, EvalError]
  trace : TraceNode
}

///|
fn eval_error_message(error : EvalError) -> String {
  match error {
    MissingVariable(path) => "missing variable: \{path}"
    TypeMismatch(message) => message
    BudgetExceeded(kind, current, limit) =>
      "budget \{kind} exceeded: \{current} > \{limit}"
    UnsupportedTraceMode(mode) => "trace mode \{mode} is not supported in V1"
  }
}

///|
fn trace_mode_name(mode : TraceMode) -> String {
  match mode {
    Off => "Off"
    Summary => "Summary"
    Full => "Full"
  }
}

///|
fn first_budget_excess(budget : Budget) -> EvalError? {
  let maximum = Budget::default()
  if budget.max_depth > maximum.max_depth {
    Some(BudgetExceeded("max_depth", budget.max_depth, maximum.max_depth))
  } else if budget.max_rule_nodes > maximum.max_rule_nodes {
    Some(
      BudgetExceeded(
        "max_rule_nodes",
        budget.max_rule_nodes,
        maximum.max_rule_nodes,
      ),
    )
  } else if budget.max_steps > maximum.max_steps {
    Some(BudgetExceeded("max_steps", budget.max_steps, maximum.max_steps))
  } else if budget.max_trace_nodes > maximum.max_trace_nodes {
    Some(
      BudgetExceeded(
        "max_trace_nodes",
        budget.max_trace_nodes,
        maximum.max_trace_nodes,
      ),
    )
  } else if budget.max_preview_chars > maximum.max_preview_chars {
    Some(
      BudgetExceeded(
        "max_preview_chars",
        budget.max_preview_chars,
        maximum.max_preview_chars,
      ),
    )
  } else {
    None
  }
}

///|
fn terminal_error_report(error : EvalError) -> EvaluationReport {
  {
    decision: Indeterminate(error),
    trace: {
      rule_path: "condition",
      operator: "error",
      status: Error,
      resolved_inputs: [],
      result: None,
      message: eval_error_message(error),
      children: [],
    },
    stats: {
      steps_executed: 0,
      nodes_evaluated: 0,
      max_depth_reached: 0,
      trace_nodes_emitted: 1,
    },
  }
}

///|
pub fn evaluate(
  rule : RuleDocument,
  data : Json,
  budget : Budget,
  trace_mode? : TraceMode = Full,
) -> EvaluationReport {
  if trace_mode != Full {
    return terminal_error_report(
      UnsupportedTraceMode(trace_mode_name(trace_mode)),
    )
  }
  match first_budget_excess(budget) {
    Some(error) => return terminal_error_report(error)
    None => ()
  }
  let context : EvalContext = {
    budget,
    steps: 0,
    nodes: 0,
    max_depth: 0,
    trace_nodes: 0,
  }
  let evaluated = eval_expr(
    context,
    rule.condition,
    data,
    RulePath::root().field("condition"),
    1,
  )
  let decision = match evaluated.value {
    Ok(True) => Decision::Pass
    Ok(False) => Decision::Fail
    Ok(_) =>
      Indeterminate(TypeMismatch("rule condition must evaluate to a boolean"))
    Err(error) => Indeterminate(error)
  }
  {
    decision,
    trace: evaluated.trace,
    stats: {
      steps_executed: context.steps,
      nodes_evaluated: context.nodes,
      max_depth_reached: context.max_depth,
      trace_nodes_emitted: context.trace_nodes,
    },
  }
}

///|
pub fn evaluate_condition(
  condition : Expr,
  data : Json,
  budget : Budget,
  trace_mode? : TraceMode = Full,
) -> EvaluationReport {
  let rule : RuleDocument = {
    id: "condition",
    description: "synthetic condition",
    condition,
  }
  evaluate(rule, data, budget, trace_mode~)
}

///|
fn value_trace(
  context : EvalContext,
  path : RulePath,
  operator : String,
  value : Json,
  source : String,
) -> TraceNode {
  context.trace_nodes += 1
  {
    rule_path: path.to_string(),
    operator,
    status: Value,
    resolved_inputs: [{ source, value }],
    result: Some(value),
    message: "resolved \{source}",
    children: [],
  }
}

///|
fn error_trace(
  context : EvalContext,
  path : RulePath,
  operator : String,
  error : EvalError,
  children? : Array[TraceNode] = [],
) -> TraceNode {
  context.trace_nodes += 1
  {
    rule_path: path.to_string(),
    operator,
    status: Error,
    resolved_inputs: [],
    result: None,
    message: eval_error_message(error),
    children,
  }
}

///|
fn skipped_trace(
  context : EvalContext,
  expr : Expr,
  path : RulePath,
  reason : String,
) -> TraceNode {
  context.trace_nodes += 1
  let label = match expr {
    Literal(_) => "literal"
    Variable(data_path) => "var(\{data_path})"
    Operation(operator, _) => operator_name(operator)
  }
  {
    rule_path: path.to_string(),
    operator: label,
    status: Skipped,
    resolved_inputs: [],
    result: None,
    message: reason,
    children: [],
  }
}

///|
fn operation_trace(
  context : EvalContext,
  path : RulePath,
  operator : Operator,
  value : Result[Json, EvalError],
  children : Array[TraceNode],
) -> TraceNode {
  context.trace_nodes += 1
  let resolved_inputs : Array[ResolvedInput] = []
  for child in children {
    match child.result {
      Some(result) =>
        resolved_inputs.push({ source: child.operator, value: result })
      None => ()
    }
  }
  match value {
    Ok(True) =>
      {
        rule_path: path.to_string(),
        operator: operator_name(operator),
        status: Pass,
        resolved_inputs,
        result: Some(Json::boolean(true)),
        message: "operation passed",
        children,
      }
    Ok(False) =>
      {
        rule_path: path.to_string(),
        operator: operator_name(operator),
        status: Fail,
        resolved_inputs,
        result: Some(Json::boolean(false)),
        message: "operation failed",
        children,
      }
    Ok(other) =>
      {
        rule_path: path.to_string(),
        operator: operator_name(operator),
        status: Value,
        resolved_inputs,
        result: Some(other),
        message: "operation produced a value",
        children,
      }
    Err(error) =>
      {
        rule_path: path.to_string(),
        operator: operator_name(operator),
        status: Error,
        resolved_inputs,
        result: None,
        message: eval_error_message(error),
        children,
      }
  }
}

///|
fn eval_and(
  context : EvalContext,
  arguments : Array[Expr],
  data : Json,
  operation_path : RulePath,
  depth : Int,
) -> EvalNodeResult {
  let children : Array[TraceNode] = []
  let mut first_error : EvalError? = None
  let mut decisive_false = false
  for index, argument in arguments {
    if decisive_false {
      children.push(
        skipped_trace(
          context,
          argument,
          operation_path.index(index),
          "and short-circuited",
        ),
      )
      continue
    }
    let child = eval_expr(
      context,
      argument,
      data,
      operation_path.index(index),
      depth + 1,
    )
    children.push(child.trace)
    match child.value {
      Ok(True) => ()
      Ok(False) => decisive_false = true
      Ok(_) =>
        if first_error is None {
          first_error = Some(TypeMismatch("and requires boolean operands"))
        }
      Err(error) => if first_error is None { first_error = Some(error) }
    }
  }
  let value = if decisive_false {
    Ok(Json::boolean(false))
  } else {
    match first_error {
      Some(error) => Err(error)
      None => Ok(Json::boolean(true))
    }
  }
  {
    value,
    trace: operation_trace(context, operation_path, And, value, children),
  }
}

///|
fn eval_binary_comparison(
  context : EvalContext,
  operator : Operator,
  arguments : Array[Expr],
  data : Json,
  operation_path : RulePath,
  depth : Int,
) -> EvalNodeResult {
  let children : Array[TraceNode] = []
  if arguments.length() != 2 {
    let error = TypeMismatch(
      "operator \{operator_name(operator)} requires two operands",
    )
    return {
      value: Err(error),
      trace: error_trace(
        context,
        operation_path,
        operator_name(operator),
        error,
      ),
    }
  }
  let values : Array[Json] = []
  let mut first_error : EvalError? = None
  for index, argument in arguments {
    let child = eval_expr(
      context,
      argument,
      data,
      operation_path.index(index),
      depth + 1,
    )
    children.push(child.trace)
    match child.value {
      Ok(value) => values.push(value)
      Err(error) => if first_error is None { first_error = Some(error) }
    }
  }
  let value : Result[Json, EvalError] = match first_error {
    Some(error) => Err(error)
    None =>
      match compare_numbers(operator, values[0], values[1]) {
        Ok(result) => Ok(Json::boolean(result))
        Err(error) => Err(error)
      }
  }
  {
    value,
    trace: operation_trace(context, operation_path, operator, value, children),
  }
}

///|
fn eval_expr(
  context : EvalContext,
  expr : Expr,
  data : Json,
  path : RulePath,
  depth : Int,
) -> EvalNodeResult {
  context.steps += 1
  context.nodes += 1
  if depth > context.max_depth {
    context.max_depth = depth
  }
  if depth > context.budget.max_depth {
    let error = BudgetExceeded("max_depth", depth, context.budget.max_depth)
    return {
      value: Err(error),
      trace: error_trace(context, path, "budget", error),
    }
  }
  match expr {
    Literal(value) =>
      {
        value: Ok(value),
        trace: value_trace(context, path, "literal", value, "literal"),
      }
    Variable(data_path) =>
      match resolve_data_path(data, data_path) {
        Ok(value) =>
          {
            value: Ok(value),
            trace: value_trace(
              context,
              path.field("var"),
              "var(\{data_path})",
              value,
              "var(\{data_path})",
            ),
          }
        Err(MissingDataPath(_)) => {
          let error = MissingVariable(data_path)
          {
            value: Err(error),
            trace: error_trace(
              context,
              path.field("var"),
              "var(\{data_path})",
              error,
            ),
          }
        }
        Err(InvalidDataPath(_) | NonObjectSegment(_)) => {
          let error = TypeMismatch(
            "cannot resolve data path \{data_path} through a non-object value",
          )
          {
            value: Err(error),
            trace: error_trace(
              context,
              path.field("var"),
              "var(\{data_path})",
              error,
            ),
          }
        }
      }
    Operation(operator, arguments) => {
      let operation_path = path.field(operator_name(operator))
      match operator {
        And => eval_and(context, arguments, data, operation_path, depth)
        GreaterOrEqual =>
          eval_binary_comparison(
            context, operator, arguments, data, operation_path, depth,
          )
        _ => {
          let error = TypeMismatch(
            "operator \{operator_name(operator)} is not implemented yet",
          )
          {
            value: Err(error),
            trace: error_trace(
              context,
              operation_path,
              operator_name(operator),
              error,
            ),
          }
        }
      }
    }
  }
}
