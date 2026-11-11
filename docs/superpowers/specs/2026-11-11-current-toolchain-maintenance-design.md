# MoonRules 当前工具链兼容性维护设计

日期：2026-11-11

## 意图

在不改变 MoonRules v0.2 的 DSL、公开 API、求值语义、CLI 退出码或 Playground 行为的前提下，使仓库能够在 2026-11-11 可获得的 MoonBit 官方当前发布工具链上重新通过格式、严格检查、测试、构建和核心示例验证，并留下可复核的维护证据。

## 已复现的基线

- 原验证环境为 `moon 0.1.20260713`、`moonc 0.10.4`、`moonrun 0.1.20260713`。
- 官方 `latest` 隔离安装实际得到 `moon 0.1.20261104`、`moonc 0.10.20`、`moonrun 0.1.20261104`。
- `moon fmt --check` 因当前格式器要求的 `Int32`、标签参数、`#derive` 与尾逗号格式而失败。
- `moon check --deny-warn` 因弃用语法、黑盒测试隐式包引用及未使用导入而失败。
- 旧依赖 `moonbitlang/async@0.20.2` 与 `moonbitlang/x@0.4.46` 在 macOS arm64 的当前 native 后端下令 CLI 测试链接失败，缺少 `_moonbit_get_cli_args`。
- 隔离副本升级至 `moonbitlang/async@0.22.9` 与 `moonbitlang/x@0.5.7` 后，CLI 白盒测试在当前 native 后端下通过；进一步验证表明 CLI 可直接迁移到当前标准库 `moonbitlang/core/env` 并移除 `x`。

## 目标

- 迁移至当前格式器生成的 MoonBit 语法，不手工改变运行语义。
- 使用当前工具链重新生成已跟踪的公开接口文件，确保接口快照与源码一致。
- 更新 `async`，并把 CLI 从已弃用的 `x/sys` 参数接口迁移到当前标准库 `core/env`，以解决当前 native 链接故障。
- 保持根包测试为黑盒测试，并显式通过 `@moonrules` 使用公开 API。
- 保持 CLI 测试为白盒测试；移除当前工具链识别出的无用导入。
- 让 CI 可手动触发，同时继续在 push 和 pull request 上安装官方 latest 并执行已支持目标矩阵。
- 在中英文 README 与任务状态中记录实际验证版本、日期、目标和命令。

## 非目标与禁区

- 不新增 v0.3 功能，不扩展 DSL，不改变预算、Trace 或三态求值语义。
- 不发布 Mooncakes 新版本，不创建 GitHub Release，不部署 Pages。
- 不声称远端 CI 通过，除非维护分支实际推送并由 GitHub Actions 运行成功。
- 不把 macOS 本机验证冒充 Linux CI 证据。
- 公开接口的 `Int` → `Int32` 与 `Json` → `@json.Json` 仅是当前工具链的显式接口表示迁移，不改变 v0.2 对外语义。
- 不修改全局 `~/.moon`；本轮使用隔离的官方 latest 工具链验证，避免影响其他项目。

## 方案

### 方案 A：仅关闭严格告警或固定旧工具链

改动小，但会隐藏真实迁移问题，也不能证明项目兼容官方当前版本，因此不采用。

### 方案 B：只执行格式迁移，不升级依赖

可以恢复严格检查，但 macOS arm64 当前 native 后端的 CLI 测试仍会链接失败，因此不完整。

### 方案 C：最小完整兼容迁移（采用）

使用当前格式器迁移语法，升级 `async`、把 `x/sys` 替换为当前标准库 `core/env`，显式化黑盒测试包边界，清理无用导入，并复跑全部 native、wasm-gc、CLI、Playground 与示例验证。对公开类型增加显式的弃用 trait 扩展，保持旧版隐式提升的 `Eq`/`Debug` 普通方法兼容，同时消除当前编译器的迁移告警。它保留 v0.2 行为，同时直接覆盖已复现的根因。

## 完成标准

在隔离的当前工具链下，以下命令均以退出码 0 完成：

- `moon fmt --check`
- `moon check --deny-warn`
- `moon test --target native`
- `moon build --target native`
- `moon test --target wasm-gc`
- `moon build --target wasm-gc`
- `scripts/test_cli.sh`
- `moon run --target native cmd/main check examples/coupon.rule.json`
- `cd playground && npm ci && npm test && npm run build && npm run test:e2e`
- `git diff --check`

远端 GitHub Actions 结果属于后续推送后的独立证据，不在本地完成标准内。
