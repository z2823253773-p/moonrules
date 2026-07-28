///|
fn run_evaluate_benchmark(it : @bench.T, size : Int) -> Unit {
  let rule = benchmark_rule(size)
  it.bench(fn() {
    it.keep(evaluate(rule, Json::empty_object(), Budget::default()))
  })
}

///|
test "bench evaluate n=1" (it : @bench.T) {
  run_evaluate_benchmark(it, 1)
}

///|
test "bench evaluate n=10" (it : @bench.T) {
  run_evaluate_benchmark(it, 10)
}

///|
test "bench evaluate n=100" (it : @bench.T) {
  run_evaluate_benchmark(it, 100)
}

///|
test "bench evaluate n=1000" (it : @bench.T) {
  run_evaluate_benchmark(it, 1000)
}
