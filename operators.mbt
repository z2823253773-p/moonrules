///|
fn compare_numbers(
  operator : Operator,
  left : Json,
  right : Json,
) -> Result[Bool, EvalError] {
  guard left is Number(a, ..) && right is Number(b, ..) else {
    return Err(TypeMismatch("numeric comparison requires two numbers"))
  }
  Ok(
    match operator {
      GreaterThan => a > b
      GreaterOrEqual => a >= b
      LessThan => a < b
      LessOrEqual => a <= b
      _ => false
    },
  )
}

///|
fn evaluate_comparison(
  operator : Operator,
  left : Json,
  right : Json,
) -> Result[Bool, EvalError] {
  match operator {
    Equal => Ok(json_deep_equal(left, right))
    NotEqual => Ok(!json_deep_equal(left, right))
    GreaterThan | GreaterOrEqual | LessThan | LessOrEqual =>
      compare_numbers(operator, left, right)
    _ =>
      Err(
        TypeMismatch("operator \{operator_name(operator)} is not a comparison"),
      )
  }
}

///|
fn evaluate_in(needle : Json, haystack : Json) -> Result[Bool, EvalError] {
  guard haystack is Array(values) else {
    return Err(TypeMismatch("in requires an array as its second argument"))
  }
  Ok(values.any(value => json_deep_equal(needle, value)))
}

///|
fn evaluate_text(
  operator : Operator,
  left : Json,
  right : Json,
) -> Result[Bool, EvalError] {
  guard left is String(text) && right is String(part) else {
    return Err(TypeMismatch("string operator requires two strings"))
  }
  Ok(
    match operator {
      Contains => text.contains(part)
      StartsWith => text.has_prefix(part)
      EndsWith => text.has_suffix(part)
      _ => false
    },
  )
}

///|
fn evaluate_binary_operator(
  operator : Operator,
  left : Json,
  right : Json,
) -> Result[Bool, EvalError] {
  match operator {
    In => evaluate_in(left, right)
    Contains | StartsWith | EndsWith => evaluate_text(operator, left, right)
    Equal | NotEqual | GreaterThan | GreaterOrEqual | LessThan | LessOrEqual =>
      evaluate_comparison(operator, left, right)
    _ =>
      Err(
        TypeMismatch(
          "operator \{operator_name(operator)} is not a binary value operator",
        ),
      )
  }
}
