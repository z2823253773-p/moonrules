# MoonRules 项目申报书

## 项目定位与生态价值

MoonRules 是 MoonBit 原生的可解释、受预算限制的 JSON 业务规则引擎，面向 API 准入、资格判断、表单逻辑和配置策略。JSON Schema 验证数据结构；MoonRules 判断合法数据是否满足动态业务条件，并解释每一步原因。

公开仓库：[github.com/z2823253773-p/moonrules](https://github.com/z2823253773-p/moonrules)。GitHub Actions [CI 工作流](https://github.com/z2823253773-p/moonrules/actions/workflows/ci.yml) 已通过完整验证矩阵。版本 `0.1.0` 已发布至 [mooncakes.io](https://mooncakes.io/docs/z2823253773-p/moonrules)。

## 已有基础

V1 核心代码、原生 CLI、三个业务示例、中英文文档和 Apache-2.0 许可证已完成。本地测试矩阵为 native 63/63、wasm-gc 60/60，格式检查、零警告检查和双目标构建全部通过。

## 本次新增范围

交付 15 种节点/操作符形式、JSON DSL 解析、运行前检查、三态求值、结构化 Trace、确定性预算、`check/eval` CLI、QuickCheck 性质测试、GitHub Actions 和 mooncakes.io 发布包。

## 核心创新

1. **可解释执行**：变量、字面量和操作符都是独立 Trace 节点，展示中间值、失败原因与短路分支。
2. **运行前诊断**：利用 MoonBit ADT 与模式匹配，在执行前发现参数数量、路径、字面量类型和静态预算问题。
3. **确定性安全预算**：限制深度、规则节点、步骤和 Trace 节点；超限时保留部分 Trace，并在截断点插入结构化错误。

## 技术路线

JSON 规则依次经过 Parser、Checker、Evaluator 和 Renderer。可移植核心库不依赖文件、环境、进程或网络 API；原生文件 I/O 仅存在于薄 CLI。`and` 使用 `false > error > true`，`or` 使用 `true > error > false`。

## 交付、测试与文档

三组可运行示例覆盖优惠券、API 准入和会员资格。60 个跨目标核心测试加 3 个 native CLI 测试，包含 16 个固定种子性质测试。文档包括中文主 README、英文快速入口以及 DSL、API、错误与预算参考。

## 开源与许可证

项目采用 Apache-2.0。提交作者已统一为 GitHub noreply 身份，包名为 `z2823253773-p/moonrules@0.1.0`。GitHub 仓库、绿色 CI 和 mooncakes.io 包页面均已公开。

## 时间安排

核心实现、GitHub 公开、CI、mooncakes.io 发布和证据回填均已完成；下一阶段完成演示录制与正式申报。工作日按每天 1 至 2 小时维护，小步提交并持续运行完整矩阵。
