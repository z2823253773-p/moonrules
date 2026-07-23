///|
pub(all) enum DataPathError {
  InvalidDataPath(String)
  MissingDataPath(String)
  NonObjectSegment(String)
} derive(Eq, Debug)

///|
pub fn parse_data_path(path : String) -> Result[Array[String], DataPathError] {
  if path == "" {
    return Err(InvalidDataPath(path))
  }
  let parts : Array[String] = []
  for part_view in path.split(".") {
    let part = part_view.to_owned()
    if part == "" || part.contains("[") || part.contains("]") {
      return Err(InvalidDataPath(path))
    }
    parts.push(part)
  }
  Ok(parts)
}

///|
pub fn resolve_data_path(
  data : Json,
  path : String,
) -> Result[Json, DataPathError] {
  let parts = match parse_data_path(path) {
    Ok(parts) => parts
    Err(error) => return Err(error)
  }
  let mut current = data
  for part in parts {
    match current {
      Object(fields) =>
        match fields.get(part) {
          Some(value) => current = value
          None => return Err(MissingDataPath(path))
        }
      _ => return Err(NonObjectSegment(part))
    }
  }
  Ok(current)
}
