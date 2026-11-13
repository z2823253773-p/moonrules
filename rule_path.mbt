///|
#derive(Eq, Debug)
pub(all) enum RulePathSegment {
  Field(String)
  Index(Int32)
}

///|
#derive(Eq, Debug)
pub(all) struct RulePath {
  segments : Array[RulePathSegment]
}

///|
#deprecated
pub extend RulePathSegment with Eq::{not_equal, equal}

///|
#deprecated
pub extend RulePathSegment with Debug::{to_repr}

///|
#deprecated
pub extend RulePath with Eq::{not_equal, equal}

///|
#deprecated
pub extend RulePath with Debug::{to_repr}

///|
pub fn RulePath::root() -> RulePath {
  { segments: [], }
}

///|
pub fn RulePath::field(self : RulePath, name : String) -> RulePath {
  let segments = self.segments.copy()
  segments.push(Field(name))
  { segments, }
}

///|
pub fn RulePath::index(self : RulePath, index : Int32) -> RulePath {
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
