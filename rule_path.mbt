///|
pub(all) enum RulePathSegment {
  Field(String)
  Index(Int)
} derive(Eq, Debug)

///|
pub(all) struct RulePath {
  segments : Array[RulePathSegment]
} derive(Eq, Debug)

///|
pub fn RulePath::root() -> RulePath {
  { segments: [] }
}

///|
pub fn RulePath::field(self : RulePath, name : String) -> RulePath {
  let segments = self.segments.copy()
  segments.push(Field(name))
  { segments, }
}

///|
pub fn RulePath::index(self : RulePath, index : Int) -> RulePath {
  let segments = self.segments.copy()
  segments.push(Index(index))
  { segments, }
}

///|
pub fn RulePath::to_string(self : RulePath) -> String {
  let out = StringBuilder()
  for segment in self.segments {
    match segment {
      Field(name) => {
        if !out.is_empty() {
          out.write_char('.')
        }
        out.write_string(name)
      }
      Index(index) => out.write_string("[\{index}]")
    }
  }
  out.to_string()
}
