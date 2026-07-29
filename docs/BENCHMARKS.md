# MoonRules v0.2 Benchmarks

## Environment

- Date: 2026-07-28
- Machine: Apple Silicon MacBook Air
- Architecture: arm64
- Moon: 0.1.20260713
- Moonc: 0.10.4
- Moonrun: 0.1.20260713
- Target: native release

## Method

Each phase uses MoonBit's `@bench.T` harness. Fixtures contain deterministic 1,
10, 100, and 1000-comparison `and` rules. Parse, check, evaluate, and report
serialization are measured independently.

Full, Summary, and Off use identical full evaluation before output shaping.
The render-mode comparison therefore describes returned report serialization
cost and size shape, not reduced rule-evaluation work.

The benchmark files are committed as reproducible source fixtures:

- `benchmark_parse.mbt`
- `benchmark_check.mbt`
- `benchmark_evaluate.mbt`
- `benchmark_render.mbt`
- `benchmark_render_summary.mbt`
- `benchmark_render_off.mbt`

The current MoonBit toolchain checks these benchmark files as package sources,
so `moonbitlang/core/bench` is imported in `moon.pkg` to keep
`moon check --deny-warn` clean.

## Results

Times are benchmark means from `moon bench ... --target native --release`.
Values in parentheses record the harness sample shape printed as
`10 × <runs>`.

| Nodes | Parse | Check | Evaluate | Render Full | Render Summary | Render Off |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 1.07 µs (10 × 96689) | 333.85 ns (10 × 100000) | 1.34 µs (10 × 75565) | 8.10 µs (10 × 12310) | 4.82 µs (10 × 20579) | 2.61 µs (10 × 32734) |
| 10 | 5.25 µs (10 × 18865) | 2.33 µs (10 × 42831) | 10.06 µs (10 × 9870) | 52.73 µs (10 × 1696) | 23.29 µs (10 × 4287) | 2.58 µs (10 × 35434) |
| 100 | 46.78 µs (10 × 1981) | 21.75 µs (10 × 4609) | 104.74 µs (10 × 1047) | 511.56 µs (10 × 197) | 207.84 µs (10 × 488) | 2.66 µs (10 × 38379) |
| 1000 | 449.78 µs (10 × 224) | 237.79 µs (10 × 447) | 1.08 ms (10 × 97) | 5.18 ms (10 × 20) | 2.08 ms (10 × 49) | 2.61 µs (10 × 38609) |

## Raw command set

```bash
moon bench benchmark_parse.mbt --target native --release
moon bench benchmark_check.mbt --target native --release
moon bench benchmark_evaluate.mbt --target native --release
moon bench benchmark_render.mbt --target native --release
moon bench benchmark_render_summary.mbt --target native --release
moon bench benchmark_render_off.mbt --target native --release
```

## Browser artifact

- Selected Playground backend: MoonBit JavaScript target fallback.
- `playground/src/generated/moonrules.js`: 309,275 bytes.
- `playground/public/engine/moonrules.wasm`: not emitted for the selected JS
  fallback backend.

## Limits

These results describe one machine and toolchain. They demonstrate scaling
trends and reproducibility, not universal latency guarantees.
