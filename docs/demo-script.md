# MoonRules v0.2 Demo Script (90 seconds)

## Time boxes

| Time | Segment | Action | Key message |
|---|---|---|---|
| 0–12s | Problem | Show the coupon rule JSON. "一个电商平台需要判断优惠券资格：成年人、学生、满 100 元。JSON Schema 能校验字段类型，但无法表达这些跨字段业务条件。" | JSON Schema validates structure; MoonRules evaluates business decisions. |
| 12–28s | Default example | Open Playground, coupon rule loaded, fail data selected. Click Evaluate. Status card shows FAIL. | "默认打开优惠券不通过案例——用户 role 是 guest 而非 student，虽然年龄和金额都满足。" |
| 28–48s | Trace reading | Expand the FAIL node. Point to: `PASS user.age >= 18 (resolved: 20 >= 18)`, `FAIL user.role == "student" (resolved: "guest" != "student")`, `SKIPPED order.total >= 100`. | "不仅告诉你失败，还告诉你哪个条件失败了、实际读取的值是什么、哪些分支因为 and 短路被跳过。" |
| 48–60s | Trace modes | Switch trace mode to Summary: value leaves gone, operators remain. Switch to Off: single root node, Decision and Stats preserved. | "三种输出模式，Decision 永远一致。Full 用于调试，Summary 用于日志，Off 用于高性能场景。" |
| 60–72s | Diagnostics | Switch to a malformed rule. Click Check. Show diagnostic: `E_ARITY`, `condition.and[0].>`. "参数数量错误在执行前就被发现，带规则路径和修改建议。" | "运行前检查在执行前拦截错误，不会等到运行时才崩溃。" |
| 72–82s | CLI | Show terminal: `moon run eval rule.json --data data.json --json`. Parse JSON output, show exit codes. | "CLI 支持文件输入、stdin 和 JSON 输出，固定退出码便于脚本集成。" |
| 82–90s | Evidence | Show CI badge, test counts (71 MoonBit + 18 property + 11 browser), benchmark table, repo links. | "71 个 MoonBit 测试、18 个性质测试、11 个浏览器测试、可复现基准测试——全部绿色。" |

## Setup

1. Start the Playground locally: `cd playground && npm run preview`
2. Open `http://127.0.0.1:4173` in a clean browser window.
3. Have a terminal ready with `moon run --target native cmd/main` aliased.

## Recording tips

- Use a 1920×1080 viewport.
- Hide bookmarks bar, extensions, and personal tabs.
- Use system light mode for maximum contrast.
- Record at 15 fps for a reasonable GIF file size.
- Alternate between Playground (primary) and terminal (CLI segment only).
- If GIF exceeds GitHub's practical limit (~10 MB), upload an MP4 to the repo and embed a still frame in the README.

## Alternate: still-image walkthrough

If animated recording is impractical:
1. Screenshot: Playground with coupon FAIL and expanded Trace.
2. Screenshot: Playground with coupon PASS after switching data.
3. Screenshot: Playground showing diagnostic for a malformed rule.
4. Screenshot: Terminal with `--json` output and exit code.
5. Arrange in README as a numbered walkthrough.
