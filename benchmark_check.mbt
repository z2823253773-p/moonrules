///|
fn run_check_benchmark(it : @bench.T, size : Int) -> Unit {
  let rule = benchmark_rule(size)
  it.bench(fn() { it.keep(check(rule)) })
}

///|
test "bench check n=1" (it : @bench.T) {
  run_check_benchmark(it, 1)
}

///|
test "bench check n=10" (it : @bench.T) {
  run_check_benchmark(it, 10)
}

///|
test "bench check n=100" (it : @bench.T) {
  run_check_benchmark(it, 100)
}

///|
test "bench check n=1000" (it : @bench.T) {
  run_check_benchmark(it, 1000)
}
