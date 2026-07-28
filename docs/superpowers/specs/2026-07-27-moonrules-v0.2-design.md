# MoonRules v0.2 设计说明

日期：2026-07-27  
状态：六部分设计已逐节获用户批准；本文件待用户书面终审  
目标完成时间：2026-07-31 晚间

## 1. 背景与版本目标

MoonRules v0.1.0 已经完成可解释 JSON 动态规则引擎的核心闭环：规则解析、运行前检查、三态求值、安全执行预算、完整 Trace、原生 CLI、测试、CI、示例、文档和 Mooncakes 发布。

v0.2.0 不重新设计 DSL，也不扩张为通用工作流系统。本版本集中解决三个影响评审体验和真实可用性的问题：

1. 缺少无需安装即可体验的在线入口。
2. `TraceMode::Summary` 与 `TraceMode::Off` 只有 API 形状，尚未实现。
3. CLI、仓库证据链和申报材料还不足以完整展示项目的工程质量。

v0.2.0 的产品目标是：

> 让评审者在浏览器中用一条规则和一份数据完成检查、求值和解释阅读，同时让命令行用户获得稳定的机器可读输出。

项目定位保持不变：

> MoonRules：MoonBit 原生的可解释 API 动态规则校验引擎。

MoonRules 与 JSON Schema 的边界也保持不变：JSON Schema 主要验证数据结构，MoonRules 判断符合结构的数据是否满足动态业务条件，并解释判断过程。

## 2. 成功标准

v0.2.0 完成时必须形成一个可公开验证的闭环：

- 评审者打开 GitHub Pages 后，不安装工具即可运行三个业务示例。
- Playground 能展示 `pass`、`fail` 和 `error/indeterminate`。
- 同一规则在 `Full`、`Summary` 和 `Off` 下产生相同的 `Decision`。
- CLI 同时支持人类可读输出和稳定的 JSON 输出。
- CLI 可以从文件或标准输入读取规则与数据。
- 文档能够从问题、方案、创新点、架构、测试、性能和限制七个方面解释项目。
- GitHub、CI、Release、Mooncakes 和演示材料组成可追踪的验收证据链。

## 3. 范围

### 3.1 v0.2.0 必须完成

#### 核心库

- 实现 `TraceMode::Summary`。
- 实现 `TraceMode::Off`。
- 增加 `diagnostics_to_json(Array[Diagnostic]) -> Json`。
- 保持现有 DSL、三态语义、预算语义和 `Full` Trace 行为兼容。

#### CLI

- `check` 和 `eval` 支持 `--json`。
- 规则文件和数据文件支持使用 `-` 从标准输入读取。
- 增加 `--help` 和 `--version`。
- 固定退出码：通过或检查成功为 `0`，业务判断失败为 `1`，输入、解析、检查、求值或内部错误为 `2`。
- 同时拒绝规则和数据都使用 `-`，因为一个标准输入流无法无歧义地承载两份 JSON。

#### Web Adapter

- 提供只接受和返回字符串的稳定边界。
- Web 层只负责适配，不重新实现规则语义。
- 优先使用 wasm-gc；若两小时技术验证不能稳定跑通，则只把 Adapter 后端降级为 MoonBit JavaScript target。

#### Playground

- 使用 Vite、Vanilla TypeScript 和 CodeMirror 6。
- 左侧编辑规则 JSON，右侧编辑数据 JSON。
- 提供优惠券、API 准入和会员资格三个示例，每个示例提供通过与不通过数据。
- 提供 `Check` 与 `Evaluate`。
- 展示状态卡、Trace、Diagnostics、JSON 和 Stats。
- 支持格式化、键盘快捷键、复制 JSON 和下载 JSON。
- 桌面双栏、移动端上下布局。
- 部署到 GitHub Pages。

#### 工程与申报

- 增加 Playground 构建、浏览器冒烟测试和包消费者冒烟测试。
- 增加可复现的基准测试及 `docs/BENCHMARKS.md`。
- 完善 README、架构文档、技术报告、路线图、贡献说明和安全说明。
- 完善 GitHub 元数据、Issue/PR 模板、milestone、Issues、阶段 PR 和 v0.2.0 Release。
- 重写一页申报书，并准备 GIF、截图、90 秒演示脚本和验收清单。

### 3.2 明确不做

- 不实现完整 JSONLogic 兼容。
- 不增加数组索引路径，例如 `items[0].price`。
- 不增加用户自定义操作符。
- 不增加循环、动作、工作流或任意代码执行。
- 不增加 Web 后端、数据库、账号、云端保存或历史记录。
- 不增加原生桌面 GUI。
- 不增加 Monaco 或完整在线 IDE。
- 不增加批量 JSONL 处理。
- 不进行大规模 evaluator 重写。
- 不为了达到参考代码量而填充无意义代码。

Schema-aware 类型环境与更深入的静态类型诊断推迟到路线图 v0.3。

## 4. 总体架构

v0.2.0 采用“一套核心、三个入口”：

```text
                         ┌──────────────────────┐
                         │  MoonRules Core      │
                         │ parser / checker     │
                         │ evaluator / render   │
                         └──────────┬───────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
      ┌───────▼────────┐    ┌───────▼────────┐    ┌──────▼──────────┐
      │ Library API    │    │ Native CLI     │    │ Web Adapter     │
      │ Mooncakes      │    │ cmd/main       │    │ cmd/playground  │
      └────────────────┘    └────────────────┘    └──────┬──────────┘
                                                         │ String/JSON
                                                 ┌───────▼──────────┐
                                                 │ Static Playground │
                                                 │ Vite + TypeScript │
                                                 └───────────────────┘
```

### 4.1 核心边界

可复用核心继续禁止文件系统、网络、环境变量和进程 API。原生副作用只属于 `cmd/main`；浏览器 DOM、下载和剪贴板副作用只属于 `playground/`。

Web Adapter 是核心与浏览器之间的翻译层，不包含第二套解析器、检查器或求值器。

### 4.2 计划目录

```text
cmd/
├─ main/                  # 原生 CLI
└─ playground/            # MoonBit Web Adapter

playground/
├─ src/                   # TypeScript UI
├─ public/                # 静态资源与示例
└─ tests/                 # 前端与浏览器测试

docs/
├─ ARCHITECTURE.md
├─ BENCHMARKS.md
├─ technical-report.md
└─ submission/

CONTRIBUTING.md
ROADMAP.md
SECURITY.md
THIRD_PARTY_NOTICES.md
```

最终文件名允许根据实际模板和工具链做机械调整，但职责边界不能改变。

### 4.3 旧仓库约定的澄清

仓库原约定中的“不增加 GUI”在 v0.1 指不建设图形入口。v0.2 已明确批准一个纯静态 Web Playground 作为唯一例外。以下限制继续有效：

- 不建设原生桌面 GUI。
- 不建设服务端应用。
- 不让可复用核心依赖浏览器或操作系统副作用。

实施计划开始前应同步更新 `AGENTS.md`，避免静态 Playground 与旧约定产生冲突。

## 5. Web Adapter 契约

### 5.1 稳定入口

逻辑 API 为：

```text
check_json(rule_source, options_source) -> String
evaluate_json(rule_source, data_source, options_source) -> String
```

实际 wasm-gc 或 JavaScript 导出装饰器由工具链验证决定，但 TypeScript 看到的函数名、输入和返回 JSON 结构保持一致。

`options_source` 是 JSON 对象字符串，v0.2 支持：

```json
{
  "trace_mode": "full",
  "budget": {
    "max_depth": 64,
    "max_nodes": 4096,
    "max_steps": 10000,
    "max_trace_nodes": 4096,
    "max_value_preview": 256
  }
}
```

- `trace_mode` 接受 `full`、`summary` 或 `off`。
- `budget` 及其字段均可省略；省略时使用核心库默认值。
- 调用方仍只能调低预算，不能突破核心库上限。
- 非法 JSON、未知模式、未知选项或非法预算返回 `input_error`，不由 TypeScript 猜测或修正。

### 5.2 统一响应

Adapter 返回 UTF-8 JSON 字符串，顶层固定包含：

```json
{
  "ok": true,
  "kind": "evaluation",
  "report": {},
  "diagnostics": []
}
```

字段语义：

- `ok` 表示请求是否完成到预期阶段，不表示业务规则是否通过；规则 `Fail` 仍然是 `ok: true`。
- `kind` 为 `check`、`evaluation`、`input_error` 或 `internal_error`。
- `report` 在成功求值时为 `EvaluationReport` JSON，其他情况为 `null`。
- `diagnostics` 始终为数组。解析、检查和适配错误也转换为可展示的结构化诊断。

运行时 `Indeterminate` 是一个成功产生的求值报告，因此使用 `ok: true`、`kind: "evaluation"`，具体错误由 `report.decision` 和 Trace 表达。

关键组合固定为：

| 场景 | `ok` | `kind` | `report` |
| --- | --- | --- | --- |
| Check 通过或得到诊断 | `true` | `check` | `null` |
| 得到 Pass、Fail 或 Indeterminate | `true` | `evaluation` | 报告对象 |
| 输入、JSON 或 DSL 解析失败 | `false` | `input_error` | `null` |
| Adapter 未预期失败 | `false` | `internal_error` | `null` |

### 5.3 后端选择闸门

实施 Web Adapter 时先建立最小纵向实验：

1. MoonBit 接收规则字符串。
2. 调用现有 `parse/check/evaluate`。
3. 返回报告 JSON 字符串。
4. 浏览器加载并显示一个字段。

该实验最多投入两小时：

- 稳定通过则使用 wasm-gc。
- 若导出、加载、异常边界或构建集成仍不稳定，则切换到 MoonBit JavaScript target。

降级只改变 Adapter 编译目标，不改变核心、接口、UI、测试意图和项目对外描述。文档必须如实说明实际采用的后端。

## 6. TraceMode v0.2 语义

### 6.1 共同原则

v0.2 中 `TraceMode` 控制返回报告的 Trace 形状，不控制求值工作量：

1. 先按 v0.1 的确定性语义完成一次完整求值。
2. 得到完整 `EvaluationReport`。
3. 对 Trace 做确定性压缩。

因此，本版本不承诺 `Summary` 或 `Off` 能减少执行步骤或运行时间。这样可以把行为变化限制在输出层，降低核心回归风险。

三个模式必须满足：

- `Decision` 完全一致。
- 执行预算和错误传播完全一致。
- `ExecutionStats` 保留完整求值阶段的结构计数。
- 相同输入重复运行得到相同 JSON。

### 6.2 Full

`Full` 保持 v0.1 行为：

- 保留所有已产生的操作符、变量、字面量、错误和跳过节点。
- 保留 `resolved_inputs`、结果、消息和子节点。
- 现有黄金测试不得发生无意变化。

### 6.3 Summary

`Summary` 从 Full Trace 确定性生成：

- 保留根节点。
- 保留所有操作符节点。
- 所有 `error` 和 `skipped` 节点无条件保留。
- 删除状态为 `value` 的普通 `var` 和 `literal` 叶节点。
- 操作符节点保留用于解释判断的紧凑 `resolved_inputs`。
- 继续应用现有值预览限制。
- 保持原始子节点顺序和 `rule_path`。

如果一个 `var` 节点本身为 `error`，它不能因为节点类型是 `var` 而被删除。

### 6.4 Off

`Off` 返回单一根 Trace 节点：

- 保留根节点的 `rule_path`、操作符、状态、结果和根消息。
- 删除 `children`。
- 删除 `resolved_inputs`。
- `Decision` 和 `ExecutionStats` 保留。
- 顶层错误仍可从 `Decision::Indeterminate` 和根消息识别。

`Off` 的含义是关闭详细解释输出，不是关闭求值或安全预算。

### 6.5 Stats 展示

因为压缩发生在完整求值之后，现有 `trace_nodes_emitted` 表示完整求值阶段产生的节点数。Playground 可以从最终 Trace 计算“返回节点数”，但必须使用不同标签，不能把两个指标混为一谈。

## 7. CLI 设计

### 7.1 命令

目标命令形状：

```text
moonrules check <rule.json|-> [--json]
moonrules eval <rule.json|-> --data <data.json|-> [--json]
moonrules --help
moonrules --version
```

参数顺序是否允许完全自由由实现复杂度决定，但以上形式必须可用。

### 7.2 输入

- 普通路径从文件读取。
- `-` 从标准输入读取。
- `eval - --data -` 明确拒绝并返回退出码 `2`。
- v0.2 不设计分隔符把两份 JSON 塞入同一标准输入。

### 7.3 输出

默认模式保持适合人的文本输出，并尽量保持现有调用方式兼容。

`--json` 模式：

- 检查、解析、诊断、业务 Fail 和 Indeterminate 都以 JSON 写到 stdout。
- JSON 使用稳定字段名和确定性顺序。
- 文件无法读取、标准输入失败或不可恢复的内部错误写到 stderr。
- stdout 不混入说明文字，便于脚本消费。

### 7.4 退出码

- `0`：`check` 无诊断，或 `eval` 得到 `Pass`。
- `1`：`eval` 得到 `Fail`。
- `2`：参数、读取、解析、检查、执行 `Indeterminate` 或内部错误。

退出码与 JSON 内容同时测试，避免只验证文本。

## 8. Playground 产品设计

### 8.1 页面结构

桌面端：

```text
┌──────────────── Header / Example selector ────────────────┐
│ Rule editor                    │ Data editor                │
│                                │                            │
├──── Action bar: Check / Evaluate / TraceMode / Format ────┤
│ Status card + budgets + execution stats                    │
├──────────────── Result tabs ───────────────────────────────┤
│ Trace | Diagnostics | JSON | Stats                         │
└─────────────────────────────────────────────────────────────┘
```

移动端按相同信息顺序改为上下排列，不增加另一套交互逻辑。

### 8.2 编辑体验

两个 CodeMirror 6 编辑器提供：

- JSON 高亮。
- 行号。
- 括号匹配。
- 格式化。
- `Cmd/Ctrl + Enter` 执行。
- 明确的规则与数据标签。
- `Full`、`Summary`、`Off` 模式选择。

不实现自动补全、调试器、文件树、终端或多人协作。

### 8.3 示例

内置三个贯穿场景：

1. 电商优惠券资格。
2. API 请求准入。
3. 会员资格判断。

每个场景至少包含一份通过数据和一份不通过数据。默认打开优惠券失败案例，因为它能够同时展示已解析值、失败原因和短路节点。

另提供一个可快速触发错误的编辑方式，用于展示 Diagnostics 或 `Indeterminate`。

### 8.4 操作流程

- `Check`：只解析并运行静态检查，不需要数据。
- `Evaluate`：始终先 Check；存在阻断诊断时不进入求值。
- 成功求值后状态卡显示 `PASS`、`FAIL` 或 `INDETERMINATE`。
- 结果区域默认打开最有信息量的标签页。
- Trace 节点可折叠，默认展开根节点和失败/错误路径。

### 8.5 错误层级

页面明确区分：

1. JSON 语法错误。
2. DSL 结构诊断。
3. 运行时 `Indeterminate` 与部分 Trace。
4. Adapter 内部错误。

任何错误都不能只显示“执行失败”。必须尽可能展示阶段、路径、错误码和建议。

### 8.6 可访问性与隐私

- 状态同时使用文字、图标和颜色，不只依赖红绿。
- 键盘可以到达主要操作和结果标签。
- 保持足够的文本对比度和可见焦点。
- 页面明确说明：规则和数据仅在本地浏览器处理，不上传服务器。

## 9. 测试策略

### 9.1 核心回归

保留 v0.1 全部测试，新增：

- Summary 黄金测试。
- Off 黄金测试。
- 三种模式的 Decision 一致性测试。
- 错误、预算超限、skipped 节点在压缩后的保留测试。
- diagnostics JSON 稳定性测试。
- Adapter 各类响应测试。

### 9.2 性质测试

在具体测试通过后增加或扩充以下性质：

- 三种 TraceMode 的 Decision 不变。
- Summary 返回节点数不大于 Full。
- Off 始终只有一个根节点。
- 相同输入得到确定性 JSON。
- 报告与诊断 JSON 在 stringify 后可以重新 parse，并保留 Decision 或诊断代码。

性质测试不能替代具体业务例子和黄金测试。

### 9.3 CLI 测试

覆盖：

- 新旧命令形状。
- 文件输入。
- 规则 stdin。
- 数据 stdin。
- 双 stdin 冲突。
- `--json` stdout 纯净性。
- `0/1/2` 退出码。
- `--help` 和 `--version`。

### 9.4 Playground 测试

至少包含：

- TypeScript 类型检查和生产构建。
- 三个示例资源可加载。
- Trace 树渲染。
- JSON 复制和下载逻辑。
- 浏览器冒烟测试：打开页面、加载默认优惠券案例、执行并看到 `FAIL`。

### 9.5 消费者测试

在干净临时项目中安装 `z2823253773-p/moonrules@0.2.0`，运行 `moon check`，并调用最小公共 API。该测试用于验证发布包，而不只是当前工作区。

## 10. Benchmark 设计

基准覆盖：

- 单个比较规则。
- 约 10、100、1000 个节点的组合规则。
- `Full`、`Summary`、`Off` 三种报告形状。
- parse、check、evaluate、render 阶段。
- native 与实际采用的浏览器构建产物大小。

`docs/BENCHMARKS.md` 必须记录：

- 机器和架构。
- MoonBit 工具链版本。
- 构建目标。
- 预热和运行次数。
- 测量方法。
- 原始或可复算数据。
- 明确的限制。

报告强调规模趋势和模式之间的报告大小差异，不把单台机器的绝对耗时宣传成通用性能承诺。因为 v0.2 的 Trace 压缩发生在求值后，也不宣传 Summary/Off 能降低求值成本。

## 11. CI、GitHub 与发布证据

### 11.1 CI

计划拆分为三个可诊断的任务：

1. `core`：格式、检查、测试、native 构建及现有目标验证。
2. `playground`：依赖安装、类型检查、生产构建和浏览器冒烟。
3. `package-smoke`：打包内容检查，以及使用工具链实际支持的
   workspace/path 机制进行临时消费者公共 API 构建；若本版工具链不支持本地消费，
   则在 CI 中保留打包检查，把注册表安装冒烟放到发布后闸门。

GitHub Pages 只从绿色的主分支产物部署。

### 11.2 GitHub 工程记录

- 建立 v0.2.0 milestone。
- 为 TraceMode、CLI、Adapter、Playground、文档和发布分别建立 Issue。
- 使用 `codex/...` 分支。
- 每个阶段通过独立 PR 合并。
- PR 描述包含目标、实现、测试、截图或输出证据。
- 设置仓库 description、topics 和 Pages homepage。
- 增加 Issue 模板、PR 模板、`CONTRIBUTING.md`、`SECURITY.md`、`ROADMAP.md` 和 `THIRD_PARTY_NOTICES.md`。

### 11.3 发布

发布顺序：

1. 所有测试和构建通过。
2. 检查发布包内容。
3. 临时消费者安装候选包。
4. 更新版本和 CHANGELOG。
5. 用户确认公开发布。
6. 发布 Mooncakes 0.2.0。
7. 创建 GitHub v0.2.0 Release。
8. 复验 Pages、安装命令和文档链接。

公开发布前不得包含凭据、`.env`、内部任务状态、临时构建目录或与项目无关的本地文件。

## 12. 文档与申报材料

### 12.1 README

README 第一屏应回答：

- MoonRules 是什么。
- 它解决什么问题。
- 与 JSON Schema/普通 JSON 规则引擎有什么差异。
- 如何立即打开在线 Playground。
- 一个最短安装与使用例子。

后续包含：

- GIF。
- 三个创新点。
- 架构图。
- DSL 支持矩阵。
- CLI 与库 API。
- 测试、Benchmark 和兼容性证据。
- 已知限制与路线图。

中文 README 为主，英文 README 保持关键信息等价。

### 12.2 技术报告

详细报告覆盖：

- 问题与设计原则。
- DSL 与数据模型。
- 三态错误传播。
- 预算安全。
- TraceMode 设计。
- Web Adapter 与 Playground。
- 测试策略与结果。
- Benchmark 方法与结果。
- AI 辅助开发的边界。
- 第三方依赖和许可证。
- 已知限制与 v0.3 路线图。

### 12.3 一页申报书

申报书不是状态海报，而是一页高密度项目论证，应包含：

1. 问题与目标用户。
2. 解决方案与 JSON Schema 边界。
3. 已有 v0.1 基础。
4. v0.2 新开发内容。
5. 三个创新点：可解释 Trace、运行前检查、确定性预算。
6. 核心架构。
7. 可量化的测试、示例、发布和演示结果。
8. 计划、风险和公开证据链接。

所有数字必须在最终构建后更新，不预填无法验证的结果。

### 12.4 演示材料

- 90 秒演示脚本。
- 主线 GIF。
- PASS、FAIL、INDETERMINATE 截图。
- CLI JSON 输出截图或录屏。
- 最终验收清单。

## 13. 实施顺序与时间安排

### 13.1 阶段顺序

1. 基线复验、milestone、Issues 和任务拆分。
2. TraceMode 与 diagnostics JSON。
3. CLI 完整化。
4. Web Adapter 两小时技术闸门。
5. Playground 主流程。
6. Playground 体验与浏览器测试。
7. Benchmark、文档和仓库治理。
8. 申报书、演示、预发布与正式发布。

### 13.2 日历

| 日期 | 必须完成 |
| --- | --- |
| 7 月 27 日 | 设计定稿、实施计划、Issues、基线确认 |
| 7 月 28 日 | TraceMode、JSON 输出、CLI |
| 7 月 29 日 | Web Adapter、Playground 主流程 |
| 7 月 30 日 | UI 完整化、Pages、测试、Benchmark |
| 7 月 31 日白天 | README、技术报告、申报书、演示材料 |
| 7 月 31 日晚上 | 全量验收、发布 0.2.0、冻结项目 |

每天结束时要求：

- 已完成代码有测试。
- 当前 PR 可以构建。
- `.ai/TASK_STATE.md` 已更新。
- 不留下无法解释的大规模半成品。

## 14. 降级规则

如果进度落后，按以下顺序裁剪：

1. 编辑器高级快捷键和次要交互。
2. Trace 动画和复杂视觉效果。
3. Benchmark 的额外规模与图表。
4. JSON 下载；保留复制。
5. wasm-gc Adapter；切换到 MoonBit JavaScript target。

不得降级：

- Check/Evaluate 主流程。
- Full/Summary/Off。
- 三态语义和预算安全。
- PASS、FAIL、INDETERMINATE/ERROR 示例。
- 测试、CI、README 和在线演示。
- 申报材料的真实性和可复现性。

## 15. 风险控制

- **MoonBit Web 互操作风险**：使用两小时技术闸门和稳定字符串接口。
- **前端范围膨胀**：使用 Vanilla TypeScript，不引入应用框架和 IDE 功能。
- **核心回归**：先锁定 v0.1 测试，要求三种 TraceMode 的 Decision 一致。
- **输出契约漂移**：对 diagnostics、report 和 Adapter 响应使用黄金测试。
- **文档失真**：只从最终测试、构建、截图和 Benchmark 结果填写数字。
- **最后一天发布失败**：7 月 30 日完成一次预发布检查，7 月 31 日只修复和正式发布。
- **多代理修改冲突**：Claude Code 只接收文件边界、测试和禁区明确且与当前工作不重叠的任务。
- **初学者维护困难**：保持模块单一职责，并在技术报告中说明每个模块的输入、输出和错误契约。

## 16. 完成定义

7 月 31 日晚间只有同时满足以下条件，v0.2.0 才算完成：

- 工作区干净，版本号和 CHANGELOG 一致。
- `moon fmt --check`、`moon check`、`moon test` 和 native build 通过。
- 现有目标回归测试通过。
- Playground 类型检查、构建和浏览器冒烟通过。
- GitHub Pages 可以公开访问。
- 三个示例能够展示通过、不通过和错误路径。
- Full/Summary/Off 的 Decision 一致性有自动测试。
- CLI 文件输入、stdin、JSON 输出和退出码有自动测试。
- Mooncakes 0.2.0 能被干净消费者安装和调用。
- GitHub Release、README、技术报告和路线图完成。
- 一页 PDF 视觉检查通过，所有数据真实。
- 90 秒演示可以按脚本完成。

## 17. 实施前置条件

本设计文件通过书面终审后，必须先使用 `writing-plans` 生成逐任务实施计划。实施计划需要：

- 按 TDD 拆分为小任务。
- 为每个任务写明文件边界、失败测试、实现步骤、验证命令和完成标准。
- 在最早阶段验证 MoonBit Web 导出、实际 CLI API 和前端构建工具。
- 不把本文中的逻辑接口名称误当成未经验证的 MoonBit 语法。
- 任何公开发布动作在执行前再次向用户展示验收结果并获得确认。

在用户批准实施计划之前，不开始 v0.2 功能代码。
