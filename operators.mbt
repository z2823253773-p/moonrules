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
