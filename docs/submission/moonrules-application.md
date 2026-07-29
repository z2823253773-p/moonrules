# MoonRules 项目申报书

## 基本信息

项目名称：MoonRules

申报方向：API 动态规则校验引擎

项目定位：MoonBit 原生的可解释 JSON 业务规则引擎

开源协议：Apache-2.0

公开仓库：[github.com/z2823253773-p/moonrules](https://github.com/z2823253773-p/moonrules)

在线 Playground：[z2823253773-p.github.io/moonrules](https://z2823253773-p.github.io/moonrules/)

Mooncakes 包：[z2823253773-p/moonrules@0.2.0](https://mooncakes.io/docs/z2823253773-p/moonrules)

GitHub Release：[v0.2.0](https://github.com/z2823253773-p/moonrules/releases/tag/v0.2.0)

## 一句话说明

MoonRules 让 API 准入、优惠券资格、会员权益和配置策略这类动态业务规则变得可解释：它不仅告诉开发者规则是否通过，还说明每个变量取到了什么值、哪一步失败、哪些分支因为短路没有执行。

## 评审速览

- **解决什么**：业务规则（API 准入、优惠券资格、会员权益）判定为不通过时，开发者无法快速定位是哪一步失败，只能翻日志、补埋点、复现输入。
- **怎么做**：MoonBit 原生引擎把 JSON 规则解析成类型化规则树，执行前做诊断，执行后返回结构化、可解释的 Trace，而不是一个裸 `true/false`。
- **凭什么信**：71 native + 71 wasm-gc + 18 QuickCheck + 11 Playwright + 6 Vitest 全绿；1-1000 节点基准可复现；GitHub 代码、Mooncakes 包、公网 Playground、Release 全部公开可查。
- **怎么看**：打开 Playground，90 秒从 FAIL 看到 PASS、切换三种 Trace 模式、查看 CLI JSON 输出与退出码（详见“演示路径”）。

## 要解决的问题

优惠券、会员权益、API 准入、风控策略经常用 JSON 配置表达，但引擎只返回 `true` 或 `false`。一旦不通过，开发者要翻日志、手动复现输入、临时加调试代码，才能知道是哪一步失败。

常见场景：

- API 请求是否允许进入。
- 用户是否符合优惠券或会员权益条件。
- 表单或配置项是否满足一组动态约束。

JSON Schema 验证字段结构，却表达不了“成年学生且订单满 100 元”这类跨字段业务判断，更解释不了失败路径。MoonRules 针对的正是这层业务规则判断。

## 方案概述

MoonRules 使用一套小而明确的 JSON DSL。规则先经过 Parser 转成 MoonBit 中的类型化规则树，再经过 Checker 做运行前诊断，最后由 Evaluator 执行并生成结构化报告。报告可以输出成人类可读 Trace、稳定 JSON、CLI 结果或 Playground 可视化结果。

核心数据流：

```text
JSON rule -> Parser -> Checker -> Evaluator -> Report
                                      -> Trace mode
                                      -> CLI / JSON / Playground
```

核心库保持可移植，不读取文件、不访问网络、不依赖环境变量，也不调用进程 API。原生 I/O 只放在 `cmd/main` 的 CLI 中，浏览器 DOM 副作用只放在 `playground/` 中。

## 为什么适合 MoonBit

这个项目选择 MoonBit 不是为了“换一种语言重写规则引擎”，而是因为规则引擎本身很适合 MoonBit 的表达方式：

- 规则 AST、诊断、决策状态和 Trace 节点都可以用 ADT 表达，边界清楚。
- 模式匹配适合实现操作符分派、错误传播和短路逻辑。
- native、wasm-gc 和 JS 目标让同一套核心逻辑可以服务 CLI 和浏览器 Playground。
- 确定性预算比墙钟超时更适合跨平台执行，评审和用户都能复现结果。

## 核心创新

1. 可解释执行树

普通 JSON 规则引擎通常只返回布尔值。MoonRules 为变量、字面量和操作符生成独立 Trace 节点，记录规则路径、解析出的输入值、中间结果、错误和短路原因。评委打开 Playground 后，可以直接看到一条规则为什么失败。

2. 运行前诊断

MoonRules 在执行前检查操作符是否存在、参数数量是否正确、数据路径是否合法、字面量类型是否明显错误、规则深度和节点数是否超过预算。每条诊断都有稳定错误码、规则路径、说明和修改建议。

3. 确定性安全预算

动态规则不能无限执行。MoonRules 对规则深度、规则节点数、执行步骤和 Trace 节点数设置硬限制。超限时不会崩溃或静默失败，而是返回 `Indeterminate`，保留已产生的部分 Trace，并在截断点写入结构化错误。

## 已交付内容

| 类别 | 当前状态 |
|---|---|
| 核心库 | Parser、Checker、Evaluator、TraceMode、Renderer 已完成 |
| DSL | 支持 `var`、`literal`、逻辑、比较、集合和字符串操作符 |
| CLI | 支持文件输入、stdin、`--json`、`--help`、`--version` 和固定退出码 |
| Playground | 已部署到 GitHub Pages，包含 3 个业务示例和 pass/fail 数据 |
| 发布 | Mooncakes `z2823253773-p/moonrules@0.2.0` 已发布 |
| Release | GitHub Release `v0.2.0` 已创建 |
| 文档 | README、API、DSL、ERRORS、ARCHITECTURE、技术报告、基准报告、路线图 |

## 验证矩阵

| 验证项 | 结果 |
|---|---:|
| MoonBit native tests | 71 passed |
| MoonBit wasm-gc tests | 71 passed |
| QuickCheck property tests | 18 passed |
| Playwright browser tests | 11 passed |
| Vitest unit tests | 6 passed |
| GitHub Actions | core 和 playground jobs 通过 |
| 干净消费者安装 | `moon add z2823253773-p/moonrules@0.2.0 && moon check` 通过 |
| 公网 Playground smoke | 默认 FAIL，切换数据后 PASS |

基准测试使用确定性规则规模，覆盖 1、10、100、1000 个比较节点。1000 节点规则在 Apple Silicon native release 下求值约 1 ms，Full Trace JSON 渲染约 5 ms。项目不把单机耗时宣传成通用性能承诺，完整数据见 `docs/BENCHMARKS.md`。

## 演示路径

90 秒演示可以按以下顺序完成：

1. 打开 Playground。
2. 选择默认优惠券规则和 guest 数据，点击 Evaluate。
3. 展示结果 `FAIL`，指出 `user.age` 和 `order.total` 满足条件，但 `user.role = "guest"` 不等于 `"student"`。
4. 切换 pass 数据，重新执行，展示 `PASS`。
5. 切换 Full、Summary、Off 三种 Trace 模式，说明它们只改变输出形状，不改变 Decision 和 Stats。
6. 展示 CLI JSON 输出、测试矩阵、Mooncakes 安装和 GitHub Release。

## 边界和非目标

MoonRules 不是完整 JSONLogic 兼容实现，也不做 JSON Schema 的替代品。当前版本不支持数组下标路径、循环、用户自定义函数、自定义操作符、数据库、服务器、登录系统或原生桌面 GUI。Playground 是唯一 GUI 入口，并且是纯静态、本地浏览器执行。

这些边界是主动选择。它们让 v0.2.0 可以把“可解释、可检查、可预算、可复现”做完整，而不是在黑客松周期里扩张成一个难以验证的平台。

## AI 辅助开发声明

AI 编程助手 Codex 和 Claude Code 参与了规划、实现、测试和文档编写。参赛者 Hengrui Zhang 负责项目范围和 DSL 设计、公开发布确认、所有 AI 生成变更的人工审核、测试和构建验证、安全与许可证合规、申报材料最终审核。项目不隐瞒 AI 辅助，也不把未经验证的 AI 输出包装成手工完成的结果。

## 当前结论

MoonRules v0.2.0 已完成公开闭环：代码在 GitHub，包在 Mooncakes，Playground 可直接访问，Release 可追踪，测试和基准可以复现。对于黑客松评审，它的价值不在功能数量，而在一个很具体的问题上做到了清楚、可运行、可解释和可验证。
