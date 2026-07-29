# Third-Party Notices

MoonRules depends on the following third-party software. Each entry lists the package name, version (as pinned in the v0.2.0 release), license, and upstream repository.

## MoonBit toolchain and standard library

| Package | Version | License | Repository |
|---|---|---|---|
| MoonBit compiler & toolchain | 0.1.20260713 (moonc 0.10.4) | Apache-2.0 | <https://github.com/moonbitlang/moonbit-compiler> |
| `moonbitlang/core` (json, quickcheck, bench, test, argparse, env) | bundled with toolchain | Apache-2.0 | <https://github.com/moonbitlang/core> |
| `moonbitlang/async` | 0.20.2 | Apache-2.0 | <https://github.com/moonbitlang/async> |
| `moonbitlang/x` | 0.4.46 | Apache-2.0 | <https://github.com/moonbitlang/x> |

The MoonBit compiler, standard library, and official packages are licensed under the Apache License 2.0. See <https://www.apache.org/licenses/LICENSE-2.0>.

## Playground runtime dependencies

| Package | Version | License | Repository |
|---|---|---|---|
| codemirror | 6.0.2 | MIT | <https://github.com/codemirror/basic-setup> |
| @codemirror/state | 6.7.1 | MIT | <https://github.com/codemirror/state> |
| @codemirror/view | 6.43.7 | MIT | <https://github.com/codemirror/view> |
| @codemirror/lang-json | 6.0.2 | MIT | <https://github.com/codemirror/lang-json> |
| @codemirror/language | 6.12.4 | MIT | <https://github.com/codemirror/language> |
| @codemirror/autocomplete | 6.20.3 | MIT | <https://github.com/codemirror/autocomplete> |
| @codemirror/commands | 6.10.4 | MIT | <https://github.com/codemirror/commands> |
| @codemirror/lint | 6.9.7 | MIT | <https://github.com/codemirror/lint> |
| @codemirror/search | 6.7.1 | MIT | <https://github.com/codemirror/search> |
| @lezer/common | 1.5.2 | MIT | <https://github.com/lezer-parser/common> |
| @lezer/lr | 1.4.10 | MIT | <https://github.com/lezer-parser/lr> |
| @lezer/json | 1.0.3 | MIT | <https://github.com/lezer-parser/json> |
| @lezer/highlight | 1.2.3 | MIT | <https://github.com/lezer-parser/highlight> |

CodeMirror and Lezer are copyright Marijn Haverbeke and contributors, licensed under the MIT License. See <https://github.com/codemirror/dev/>.

## Playground development dependencies

| Package | Version | License | Repository |
|---|---|---|---|
| vite | 8.1.5 | MIT | <https://github.com/vitejs/vite> |
| typescript | 7.0.2 | Apache-2.0 | <https://github.com/microsoft/TypeScript> |
| vitest | 4.1.10 | MIT | <https://github.com/vitest-dev/vitest> |
| @playwright/test | 1.62.0 | Apache-2.0 | <https://github.com/microsoft/playwright> |
| jsdom | 30.0.0 | MIT | <https://github.com/jsdom/jsdom> |
| @types/node | 26.1.2 | MIT | <https://github.com/DefinitelyTyped/DefinitelyTyped> |

## Full license texts

- Apache License 2.0: <https://www.apache.org/licenses/LICENSE-2.0>
- MIT License: <https://opensource.org/licenses/MIT>

## Notes

- All version numbers reflect the locked dependencies in `moon.mod` and `playground/package-lock.json` at the time of the v0.2.0 release.
- MoonRules itself is licensed under Apache-2.0. See [LICENSE](LICENSE).
- No part of MoonRules copies or derives from JSONLogic source code. References to JSONLogic in documentation describe semantic inspiration only.
