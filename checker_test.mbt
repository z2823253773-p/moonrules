///|
test "checker reports arity and data path in deterministic preorder" {
  let expr = Expr::Operation(Operator::And, [
    Expr::Operation(Operator::GreaterThan, [Expr::Literal(@json.parse("18"))]),
    Expr::Variable("items[0].price"),
  ])
  let diagnostics = check_expr(expr, Budget::default())
  debug_inspect(diagnostics.length(), content="2")
  debug_inspect(diagnostics[0].code, content="\"E_ARITY\"")
  debug_inspect(diagnostics[0].rule_path, content="\"condition.and[0].>\"")
  debug_inspect(diagnostics[1].code, content="\"E_DATA_PATH\"")
  debug_inspect(diagnostics[1].rule_path, content="\"condition.and[1].var\"")
}

///|
test "empty diagnostics means check passed" {
  let expr = Expr::Operation(Operator::GreaterOrEqual, [
    Expr::Variable("user.age"),
    Expr::Literal(@json.parse("18")),
  ])
  debug_inspect(check_expr(expr, Budget::default()), content="[]")
}

///|
test "caller cannot raise library budget ceilings" {
  let budget : Budget = {
    max_depth: 65,
    max_rule_nodes: 4096,
    max_steps: 10000,
    max_trace_nodes: 4096,
    max_preview_chars: 256,
  }
  let diagnostics = validate_budget(budget)
  debug_inspect(diagnostics.length(), content="1")
  debug_inspect(diagnostics[0].code, content="\"E_BUDGET_LIMIT\"")
  debug_inspect(diagnostics[0].rule_path, content="\"budget.max_depth\"")
}

///|
test "checker catches obvious literal operand types" {
  let expr = Expr::Operation(Operator::And, [
    Expr::Operation(Operator::GreaterThan, [
      Expr::Literal(@json.parse("\"18\"")),
      Expr::Literal(@json.parse("21")),
    ]),
    Expr::Operation(Operator::Contains, [
      Expr::Literal(@json.parse("42")),
      Expr::Literal(@json.parse("\"2\"")),
    ]),
    Expr::Operation(Operator::In, [
      Expr::Literal(@json.parse("\"admin\"")),
      Expr::Literal(@json.parse("\"admins\"")),
    ]),
  ])
  let diagnostics = check_expr(expr, Budget::default())
  debug_inspect(
    diagnostics.map(diagnostic => diagnostic.code),
    content=(
      #|["E_LITERAL_TYPE", "E_LITERAL_TYPE", "E_LITERAL_TYPE"]
    ),
  )
}

///|
test "caller may lower every budget ceiling" {
  let budget : Budget = {
    max_depth: 8,
    max_rule_nodes: 100,
    max_steps: 200,
    max_trace_nodes: 100,
    max_preview_chars: 80,
  }
  debug_inspect(validate_budget(budget), content="[]")
}
