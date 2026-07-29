///|
fn run_parse_benchmark(it : @bench.T, size : Int) -> Unit {
  let source = benchmark_rule_source(size)
  it.bench(fn() { it.keep(parse(source)) })
}

///|
test "bench parse n=1" (it : @bench.T) {
  run_parse_benchmark(it, 1)
}

///|
test "bench parse n=10" (it : @bench.T) {
  run_parse_benchmark(it, 10)
}

///|
test "bench parse n=100" (it : @bench.T) {
  run_parse_benchmark(it, 100)
}

///|
test "bench parse n=1000" (it : @bench.T) {
  run_parse_benchmark(it, 1000)
}
