# MoonRules 项目申报书

## 项目定位与生态价值

MoonRules 是 MoonBit 原生的可解释、受预算限制的 JSON 业务规则引擎，面向 API 准入、资格判断、表单逻辑和配置策略。JSON Schema 验证数据结构是否合法；MoonRules 判断合法数据是否满足动态业务条件，并解释每一步原因。

v0.1.0 已发布至 mooncakes.io，具备完整核心闭环。v0.2.0 新增在线 Playground、三种 Trace 输出模式和 CLI JSON/stdin 支持，目前处于 release-candidate 状态，待用户确认后正式发布。

公开仓库：[github.com/z2823253773-p/moonrules](https://github.com/z2823253773-p/moonrules)

## 已有基础

v0.1.0 核心引擎通过 GitHub Actions CI 的完整验证矩阵（原生 71 测试、wasm-gc 66 测试），格式检查、零警告检查和双目标构建全部通过。包 `z2823253773-p/moonrules@0.1.0` 已发布至 mooncakes.io。

v0.2.0 在此基础上完成：三种 Trace 模式、诊断 JSON 序列化、CLI JSON/stdin/help/version、Web Adapter（JS 目标）、静态 Playground、浏览器冒烟测试、可复现基准测试、架构文档和技术报告。

## 本次新增范围（v0.2）

- 可解释执行：变量、字面量和操作符均为独立 Trace 节点，支持 Full/Summary/Off 三种输出模式。
- 运行前诊断：在执行前发现参数数量、路径、字面量类型和静态预算问题。
- 确定性安全预算：深度（64）、节点数（4096）、步骤（10000）、Trace 节点（4096），超限安全失败并保留部分 Trace。
- 静态 Playground：Vite + TypeScript + CodeMirror 6，三个业务示例，本地浏览器处理，不依赖服务器。
- 完整 CLI：文件/stdin 输入，`--json` 输出，固定退出码 0/1/2。
- 工程证据：71 个 MoonBit 测试 + 18 个 QuickCheck 性质测试 + 11 个 Playwright 浏览器测试 + 6 个 Vitest 单元测试，可复现基准测试。

## 核心创新

1. **可解释执行**：不只是 true/false，返回每一步变量取值、中间结果、错误和短路原因的独立 Trace 节点。三种输出模式：Full（完整）、Summary（精简）、Off（仅 Decision + Stats）。
2. **运行前诊断**：利用 MoonBit ADT 与模式匹配，在执行前检查操作符存在性、参数数量、数据路径格式、字面量类型和预算超限。所有诊断包含稳定错误码、规则路径和修改建议。
3. **确定性安全预算**：五种硬限制在解析、检查和执行阶段统一生效。预算超限时保留已产生的部分 Trace，并在截断点写入结构化错误，便于诊断。

## 技术路线

JSON 规则依次经过 Parser → Checker → Evaluator → Full Report → TraceMode 压缩 → Renderer / CLI / Web Adapter。可移植核心库不依赖文件、环境、进程或网络 API。原生 I/O 仅存在于 `cmd/main`，浏览器 DOM 副作用仅存在于 `playground/`。

Web Adapter 经两小时技术闸门评估，wasm-gc 字符串互操作在当前工具链（moonc 0.10.4）下不稳定，因此采用 MoonBit JavaScript 目标作为计划内降级方案。TypeScript 客户端通过稳定字符串/JSON 契约调用，不感知后端选择。

三态逻辑：`and` 使用 `false > error > true`，`or` 使用 `true > error > false`，`not(error) = error`。

## 交付、测试与文档

| 类别 | 数量 | 说明 |
|---|---|---|
| MoonBit 测试（native） | 71 | Parser、checker、evaluator、trace mode、renderer、CLI、adapter |
| MoonBit 测试（wasm-gc） | 66 | 跨目标核心测试 |
| QuickCheck 性质测试 | 18 | 双否定、确定性、短路、预算安全、模式不变性、JSON 往返 |
| Playwright e2e 测试 | 11 | Playground：页面外壳、Check/Evaluate、pass/fail、Tab、Copy、Download、错误输入、Trace 模式 |
| Vitest 单元测试 | 6 | Engine 客户端、示例加载、渲染器 helper |
| CLI 黑盒测试 | Shell 脚本 | 文件/stdin 输入、JSON/文本输出、退出码 0/1/2、--help、--version |
| 基准测试 | 6 文件 × 4 规模 | Parse、check、evaluate、render Full/Summary/Off |
| 业务示例 | 3 组 | 优惠券资格、API 请求准入、会员资格（各含 pass/fail 数据） |

文档：中文主 README、英文 README、DSL 语法参考、API 参考、错误与预算说明、架构文档、技术报告、基准测试报告、贡献指南、安全策略、路线图、第三方声明。

## 开源与许可证

Apache-2.0。提交作者已统一为 GitHub noreply 身份。GitHub 仓库公开，CI 绿色，包 `z2823253773-p/moonrules@0.1.0` 已发布至 mooncakes.io。v0.2.0 发布待用户确认。

## AI 辅助开发声明

AI 编程助手（Codex 和 Claude Code）参与了本项目的规划、实现、测试和文档编写。参赛者（Hengrui Zhang）负责：项目范围和 DSL 设计、所有 AI 生成变更的人工审核、全部测试和构建验证、安全与许可证合规、申报材料的最终审核和表述。无 AI 生成代码在未经人工审核的情况下提交。

## 时间安排

v0.1 核心实现（7 月 23-25 日）→ GitHub 公开和 CI（7 月 25 日）→ mooncakes.io 发布（7 月 26 日）→ v0.2 设计定稿（7 月 27 日）→ TraceMode/CLI（7 月 28 日）→ Web Adapter/Playground（7 月 29 日）→ 基准测试/文档/治理（7 月 30 日）→ 申报材料/预发布（7 月 31 日）。
