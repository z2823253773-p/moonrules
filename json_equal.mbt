///|
pub fn json_deep_equal(left : Json, right : Json) -> Bool {
  match (left, right) {
    (Null, Null) | (True, True) | (False, False) => true
    (Number(a, ..), Number(b, ..)) => a == b
    (String(a), String(b)) => a == b
    (Array(a), Array(b)) => {
      if a.length() != b.length() {
        return false
      }
      for index, value in a {
        if !json_deep_equal(value, b[index]) {
          return false
        }
      }
      true
    }
    (Object(a), Object(b)) => {
      if a.length() != b.length() {
        return false
      }
      for key, value in a {
        match b.get(key) {
          Some(other) => if !json_deep_equal(value, other) { return false }
          None => return false
        }
      }
      true
    }
    _ => false
  }
}
