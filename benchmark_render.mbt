///|
fn run_render_full_benchmark(it : @bench.T, size : Int) -> Unit {
  let report = evaluate(
    benchmark_rule(size),
    Json::empty_object(),
    Budget::default(),
  )
  it.bench(fn() { it.keep(report_to_json(report).stringify()) })
}

///|
test "bench render full n=1" (it : @bench.T) {
  run_render_full_benchmark(it, 1)
}

///|
test "bench render full n=10" (it : @bench.T) {
  run_render_full_benchmark(it, 10)
}

///|
test "bench render full n=100" (it : @bench.T) {
  run_render_full_benchmark(it, 100)
}

///|
test "bench render full n=1000" (it : @bench.T) {
  run_render_full_benchmark(it, 1000)
}
