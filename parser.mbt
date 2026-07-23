///|
pub(all) enum RuleParseError {
  ExpectedObject(String)
  MissingField(String)
  ExpectedString(String)
  MultipleOperatorKeys(String)
  UnknownOperator(String)
  InvalidVariable(String)
  InvalidLiteral(String)
  InvalidArguments(String)
} derive(Eq, Debug)

///|
pub fn RuleParseError::message(self : RuleParseError) -> String {
  match self {
    ExpectedObject(path) => "expected an object at \{path}"
    MissingField(field) => "missing required field \{field}"
    ExpectedString(path) => "expected a string at \{path}"
    MultipleOperatorKeys(path) => "expected exactly one operator key at \{path}"
    UnknownOperator(name) => "unknown operator \{name}"
    InvalidVariable(path) => "invalid variable expression at \{path}"
    InvalidLiteral(path) => "invalid object literal at \{path}"
    InvalidArguments(path) => "expected an argument array at \{path}"
  }
}

///|
fn parse_operator(name : String) -> Result[Operator, RuleParseError] {
  match name {
    "and" => Ok(And)
    "or" => Ok(Or)
    "not" => Ok(Not)
    "==" => Ok(Equal)
    "!=" => Ok(NotEqual)
    ">" => Ok(GreaterThan)
    ">=" => Ok(GreaterOrEqual)
    "<" => Ok(LessThan)
    "<=" => Ok(LessOrEqual)
    "in" => Ok(In)
    "contains" => Ok(Contains)
    "starts_with" => Ok(StartsWith)
    "ends_with" => Ok(EndsWith)
    name => Err(UnknownOperator(name))
  }
}

///|
fn required_string(
  fields : Map[String, Json],
  name : String,
) -> Result[String, RuleParseError] {
  match fields.get(name) {
    None => Err(MissingField(name))
    Some(String(value)) => Ok(value)
    Some(_) => Err(ExpectedString(name))
  }
}

///|
pub fn parse_rule_document(json : Json) -> Result[RuleDocument, RuleParseError] {
  guard json is Object(fields) else { return Err(ExpectedObject("$")) }
  let id = match required_string(fields, "id") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let description = match required_string(fields, "description") {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let condition_json = match fields.get("condition") {
    Some(value) => value
    None => return Err(MissingField("condition"))
  }
  let condition = match
    parse_expr(condition_json, RulePath::root().field("condition")) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  Ok({ id, description, condition })
}

///|
fn parse_expr(json : Json, path : RulePath) -> Result[Expr, RuleParseError] {
  match json {
    Object(fields) => {
      if fields.length() != 1 {
        return Err(MultipleOperatorKeys(path.to_string()))
      }
      let (name, argument) = match fields.iter().next() {
        Some(entry) => entry
        None => return Err(MultipleOperatorKeys(path.to_string()))
      }
      let argument_path = path.field(name)
      match name {
        "var" =>
          match argument {
            String(data_path) => Ok(Variable(data_path))
            _ => Err(InvalidVariable(argument_path.to_string()))
          }
        "literal" =>
          match argument {
            Object(_) => Ok(Literal(argument))
            _ => Err(InvalidLiteral(argument_path.to_string()))
          }
        _ => {
          let operator = match parse_operator(name) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          match argument {
            Array(values) =>
              parse_expr_array(values, argument_path).map(fn(arguments) {
                Operation(operator, arguments)
              })
            _ => Err(InvalidArguments(argument_path.to_string()))
          }
        }
      }
    }
    value => Ok(Literal(value))
  }
}

///|
fn parse_expr_array(
  values : Array[Json],
  path : RulePath,
) -> Result[Array[Expr], RuleParseError] {
  let expressions : Array[Expr] = []
  for index, value in values {
    let expression = match parse_expr(value, path.index(index)) {
      Ok(parsed) => parsed
      Err(error) => return Err(error)
    }
    expressions.push(expression)
  }
  Ok(expressions)
}
