///|
fn benchmark_expr(size : Int) -> Expr {
  let children : Array[Expr] = []
  for index in 0..<size {
    children.push(
      Expr::Operation(Operator::GreaterOrEqual, [
        Expr::Literal(Json::number(index.to_double())),
        Expr::Literal(Json::number(0.0)),
      ]),
    )
  }
  Expr::Operation(Operator::And, children)
}

///|
fn benchmark_rule(size : Int) -> RuleDocument {
  {
    id: "benchmark-\{size}",
    description: "deterministic benchmark fixture",
    condition: benchmark_expr(size),
  }
}

///|
fn benchmark_rule_source(size : Int) -> String {
  let conditions : Array[Json] = []
  for index in 0..<size {
    conditions.push(
      Json::object({
        ">=": Json::array([Json::number(index.to_double()), Json::number(0.0)]),
      }),
    )
  }
  Json::object({
    "id": Json::string("benchmark-\{size}"),
    "description": Json::string("deterministic benchmark fixture"),
    "condition": Json::object({ "and": Json::array(conditions) }),
  }).stringify()
}
