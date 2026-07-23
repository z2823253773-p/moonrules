# MoonRules 设计说明

日期：2026-07-23
状态：待用户文件级审核

## 1. 项目定位

MoonRules 是一个使用 MoonBit 实现的、可解释且具有资源限制的 JSON 动态规则引擎。它面向 API 准入、业务资格判断、表单逻辑和配置策略等场景，接受 JSON 规则与 JSON 数据，输出确定性的判断结果、结构化诊断和可读的执行解释树。

申报标题为：

> MoonRules：MoonBit 原生的可解释 API 动态规则校验引擎

该定位直接对应 2026 MoonBit 国产基础软件生态开源大赛 8 月黑客松列出的“API 动态规则校验引擎”方向。

MoonRules 与 JSON Schema 的边界必须在 README 和申报书中明确：

- JSON Schema 主要验证数据结构是否合法。
- MoonRules 判断合法数据是否满足动态业务条件，并解释判断过程。

## 2. 目标与非目标

### 2.1 V1 目标

- 使用 MoonBit 作为核心功能的主要实现语言。
- 定义一套容易阅读、容易生成且适合静态检查的 JSON 规则 DSL。
- 提供 JSON 到规则 AST 的解析和结构检查。
- 实现 12 至 15 个边界清晰的核心操作符。
- 返回结构化的执行报告，而不只是 `true` 或 `false`。
- 输出带中间值、失败原因和短路信息的解释树。
- 使用深度、节点数和执行步骤预算限制规则执行。
- 提供薄 CLI、三个完整业务示例、持续集成和 60 至 100 个测试。
- 按活动要求发布至 mooncakes.io，并保留可追踪的开发记录。

### 2.2 V1 非目标

- 不实现完整 JSONLogic 兼容层。
- 不支持循环、用户函数、网络访问、文件访问或任意代码执行。
- 不实现 Web 服务、数据库或图形界面。
- 不支持数组索引路径，例如 `items[0].price`。
- 不实现完整的变量静态类型推导。
- 不在 V1 实现 `Off` 和 `Summary` Trace；只为未来模式保留 API 形状。
- 不在 V1 实现自定义操作符注册；只保留内部扩展边界。

## 3. 贯穿示例：优惠券资格判断

规则文件：

```json
{
  "id": "student-coupon",
  "description": "满 100 元的成年学生可以使用优惠券",
  "condition": {
    "and": [
      {">=": [{"var": "user.age"}, 18]},
      {"==": [{"var": "user.role"}, "student"]},
      {">=": [{"var": "order.total"}, 100]}
    ]
  }
}
```

输入数据：

```json
{
  "user": {
    "age": 20,
    "role": "guest"
  },
  "order": {
    "total": 128
  }
}
```

预期的人类可读结果：

```text
FAIL student-coupon
├─ PASS user.age >= 18
│  ├─ resolved user.age = 20
│  └─ result = true
├─ FAIL user.role == "student"
│  ├─ resolved user.role = "guest"
│  └─ result = false
└─ SKIPPED order.total >= 100
   └─ reason: and short-circuited
```

这个示例同时演示变量解析、比较、逻辑组合、短路求值和解释树，是 README、演示视频和申报书中的主线案例。

## 4. DSL 设计

### 4.1 顶层文档

一个规则文档包含：

- `id`：稳定的规则标识。
- `description`：面向人的规则说明。
- `condition`：需要求值为布尔结果的表达式。

V1 不引入动作、工作流或 `then/else` 副作用。引擎只负责判断和解释。

### 4.2 表达式格式

MoonRules 采用 JSONLogic 风格，但不声称完整兼容 JSONLogic：

- 每个操作节点是一个只有一个操作符键的 JSON 对象。
- 多参数操作符使用数组保存操作数。
- 数字、字符串、布尔值、`null` 和数组可以作为字面量。
- JSON 对象字面量必须使用 `{"literal": {...}}` 包装，以免与操作节点产生歧义。
- 规则对象存在多个操作符键时，解析失败而不是猜测含义。

### 4.3 变量路径

V1 只支持点号分隔路径：

```json
{"var": "user.age"}
```

路径段必须非空。V1 不支持数组索引、转义点号或通配符。无法找到路径时返回 `MissingVariable` 执行错误，不静默转换为 `null`。

### 4.4 V1 操作符集合

数据与字面量：

- `var`
- `literal`

逻辑：

- `and`
- `or`
- `not`

比较：

- `==`
- `!=`
- `>`
- `>=`
- `<`
- `<=`

集合与字符串：

- `in`：判断一个值是否存在于数组中。
- `contains`：判断字符串是否包含子串。
- `starts_with`
- `ends_with`

V1 中大小比较只接受数值；`contains`、`starts_with` 和 `ends_with` 只接受字符串。引擎不执行隐式字符串与数值转换。

操作符参数约束如下：

- `var` 接受一个字符串路径；`literal` 接受一个 JSON 对象。
- `not` 接受一个参数；`and` 和 `or` 接受至少一个参数。
- 所有比较、集合和字符串操作符均接受两个参数。
- `==` 使用 JSON 深度相等语义，`!=` 是它的否定。
- `in` 使用相同的 JSON 深度相等语义检查数组成员。

## 5. 核心数据模型

概念模型如下，具体 MoonBit 类型名可在不改变语义的前提下调整：

```text
RuleDocument
├─ id: String
├─ description: String
└─ condition: Expr

Expr
├─ Literal(Json)
├─ Variable(Path)
└─ Operation(Operator, Array[Expr])

EvaluationReport
├─ decision: Decision
├─ trace: TraceNode
└─ stats: ExecutionStats

Decision
├─ Pass
├─ Fail
└─ Indeterminate(EvalError)
```

顶层结果使用三态而不是把错误强行转换成 `false`。调用方可以明确区分“不满足规则”和“规则无法可靠求值”。CLI 在最终输出层采取安全默认：`Indeterminate` 不视为通过。

## 6. Trace 设计

### 6.1 TraceNode

每个 Trace 节点包含：

- `rule_path`：节点在规则中的稳定位置。
- `operator`：操作符或节点类型。
- `status`：`value`、`pass`、`fail`、`error` 或 `skipped`。
- `resolved_inputs`：已经解析的输入值快照及其来源。
- `result`：当前节点的求值结果（如存在）。
- `message`：面向人的解释。
- `children`：子节点 Trace。

`var` 等取值节点使用 `value` 状态；布尔判断节点使用 `pass` 或 `fail`。这样不会错误地把数值 `20` 描述成“通过”。

### 6.2 路径格式

所有诊断和 Trace 统一使用可读的点号加索引格式：

```text
condition.and[1].==[0].var
```

V1 不混用 JSON Pointer。解析错误、检查诊断和执行错误都使用同一套路径构造器。

### 6.3 已解析输入

`resolved_inputs` 保存逻辑上的值快照，而不是只保存变量引用。例如：

```json
{
  "source": {"var": "user.age"},
  "value": 20
}
```

大型字符串、数组和对象在文本渲染时受到预览长度限制；完整 JSON Trace 也受 Trace 节点数和捕获值预算约束。具体内存表示由依赖验证后确定，但外部行为不能依赖可变引用。

### 6.4 Trace 模式

公共配置保留以下枚举形状：

```text
TraceMode = Off | Summary | Full
```

V1 只接受并实现 `Full`。其他模式返回明确的 `UnsupportedTraceMode`，而不是悄悄改变行为。

## 7. 求值和错误传播语义

普通操作符遇到缺失变量、类型错误或预算超限时返回结构化 `EvalError`，对应 Trace 节点标记为 `error`。

逻辑操作符使用确定性的三态传播：

### 7.1 `and`

- 按顺序执行子节点。
- 遇到 `false` 时，父节点结果为 `fail`，剩余节点标记为 `skipped`。
- 遇到 `error` 时暂不停止，继续寻找可以确定结果的 `false`。
- 如果没有 `false`，但至少有一个 `error`，父节点结果为 `error`。
- 所有子节点均为 `true` 时，父节点结果为 `pass`。

因此，`false` 对 `and` 具有决定性；错误不会被丢失，仍保留在 Trace 中。

### 7.2 `or`

- 按顺序执行子节点。
- 遇到 `true` 时，父节点结果为 `pass`，剩余节点标记为 `skipped`。
- 遇到 `error` 时暂不停止，继续寻找可以确定结果的 `true`。
- 如果没有 `true`，但至少有一个 `error`，父节点结果为 `error`。
- 所有子节点均为 `false` 时，父节点结果为 `fail`。

### 7.3 其他传播

- `not(error)` 返回 `error`。
- 比较或字符串操作的任一输入为 `error` 时，当前节点返回 `error`。
- 顶层 `error` 产生 `Decision::Indeterminate`。
- CLI 建议退出码：通过为 `0`，规则不通过为 `1`，解析、检查或执行错误为 `2`。实际跨平台可行性在依赖验证中确认。

## 8. 运行前检查

`check` 在执行前完成不依赖运行时数据的验证：

- 顶层字段和规则节点结构是否合法。
- 操作符是否存在。
- 参数数量是否正确。
- 字面量类型是否明显错误。
- 变量路径格式是否合法。
- 规则深度和节点数是否超限。
- 对象字面量是否正确使用 `literal` 包装。

诊断包含：

```text
Diagnostic
├─ code
├─ severity
├─ rule_path
├─ message
└─ suggestion
```

没有输入数据类型声明时，`check` 不声称能推断变量的运行时类型。相关问题由执行器产生带路径的类型错误。

## 9. 安全执行预算

V1 提供以下确定性预算：

- 最大规则深度。
- 最大规则节点数。
- 最大执行步骤数。
- 最大 Trace 节点数。
- 单个 Trace 值的预览限制。

初始默认值为：最大深度 `64`、最大规则节点数 `4096`、最大执行步骤数 `10000`、最大 Trace 节点数 `4096`、文本预览最多 `256` 个字符。V1 调用方只能调低这些值，不能超过库设定的默认上限。

预算在解析、检查和执行阶段共享同一配置来源。V1 不承诺基于墙钟时间的超时，因为墙钟超时会降低跨平台确定性；宿主可以在引擎外层增加时间限制。

## 10. 模块边界

- `model`：规则、表达式、诊断、报告和预算类型。
- `parser`：JSON 到 `RuleDocument`/`Expr` 的转换，不执行规则。
- `path`：V1 点号路径的解析与读取。
- `checker`：结构、操作符、参数和预算的运行前检查。
- `operators`：无副作用的内置操作符实现。
- `evaluator`：求值顺序、错误传播、短路与执行步数。
- `trace`：Trace 构造和结构化输出。
- `render`：文本解释树与 JSON 报告渲染。
- `cli`：文件读取、参数处理、退出码和输出；不承载业务逻辑。

未来的 `CustomOperator` 扩展点只作为内部边界记录在设计中。V1 不公开不稳定的插件 API。

## 11. CLI

CLI 是核心库的薄包装，优先级低于引擎、测试和文档。预期能力：

```text
moonrules check <rule.json>
moonrules eval <rule.json> --data <data.json>
```

`check` 输出诊断；`eval` 输出判断和完整 Trace。参数格式可根据 MoonBit 原生文件 I/O 与命令行支持的依赖验证结果做小幅调整。

## 12. 测试策略

测试按以下顺序实施：

1. 具体单元测试和端到端示例，先保证功能跑通。
2. 错误与边界测试，包括缺失变量、类型错误、非法结构和预算超限。
3. Trace 黄金测试，固定关键示例的结构化输出和文本树。
4. QuickCheck 性质测试，在核心语义稳定后补充。

计划覆盖的性质包括：

- `not(not(x)) == x`。
- 同一规则和数据重复执行产生相同结果与 Trace。
- `and` 遇到决定性 `false` 后不再执行后续节点。
- `or` 遇到决定性 `true` 后不再执行后续节点。
- 超过任何预算均返回结构化错误而不是崩溃。

最终目标为 60 至 100 个测试，但不以无意义堆砌数量代替覆盖关键语义。

## 13. 示例、文档和开源合规

V1 提供三个完整示例：

1. 电商优惠券资格判断（主线示例）。
2. API 请求准入策略。
3. 表单或会员资格判断。

仓库交付物包括：

- 中英文至少一种完整 README，优先先完成中文。
- DSL 语法与操作符参考。
- 错误传播和安全预算说明。
- API 使用示例。
- `CHANGELOG.md`。
- Apache-2.0 许可证。
- GitHub Actions CI。
- 可追踪的 Issue、提交、测试和版本记录。
- mooncakes.io 发布记录。

第三方参考代码或测试数据必须保留来源和许可证说明。项目不直接复制 JSONLogic 实现代码；若参考其语义或测试案例，实施前单独确认许可证和归属要求。

## 14. 实施前依赖验证

第一个实施里程碑是一个有时间盒的环境验证：

- 从 MoonBit 官方来源确认并安装适用于当前 Apple Silicon macOS 的工具链。
- 运行 `moon version --all`、`moon check`、`moon test` 和 `moon build`。
- 验证标准 JSON 解析接口。
- 验证基础测试框架。
- 确认 QuickCheck 的当前包名、版本和最小示例，但暂不大量编写性质测试。
- 验证 CLI 所需的文件读取和退出码能力。
- 确认 mooncakes.io 发布流程与账号前提。

如果其中任一能力与设计假设不符，应先调整实施计划，不直接扩张依赖或更换项目方向。

## 15. 实施里程碑

以下按工作会话而不是强制日历日安排，以适配每天约 1 至 2 小时的投入：

1. 工具链验证、项目骨架、README 大纲。
2. 核心 ADT、Trace 数据结构与 JSON 解析。
3. `var + >= + and` 最小纵向原型与优惠券解释树。
4. `check` 与剩余核心操作符。
5. 安全预算、错误传播和边界测试。
6. 普通测试稳定后增加 QuickCheck 性质测试。
7. 三个业务示例、API 文档和薄 CLI。
8. CI、许可证、更新日志和 mooncakes.io 发布准备。
9. 演示录制与一页项目申报书。

## 16. 验收标准

项目完成需同时满足：

- `moon check`、`moon test` 和 `moon build` 成功。
- 支持本设计列出的 V1 操作符。
- 非法规则能在解析或检查阶段得到带路径诊断。
- 优惠券示例能输出正确判断、已解析值、短路和 `skipped` 节点。
- `and`、`or` 和错误传播符合第 7 节定义。
- 所有预算限制均有可重复测试。
- 至少三个业务示例可以实际运行。
- README 能清楚说明用途、安装、使用方法、JSON Schema 边界和 V1 限制。
- CI 运行检查、测试和构建。
- 仓库公开、提交历史可追踪、许可证合规。
- 按活动要求发布至 mooncakes.io。

## 17. 主要风险与控制

- **MoonBit 生态变化**：先做依赖验证，版本写入仓库，避免依赖未验证的第三方包。
- **Trace 重构风险**：先确定 `TraceNode` 契约，并以黄金测试锁定外部行为。
- **DSL 范围膨胀**：V1 明确不追求 JSONLogic 完整兼容。
- **动态类型歧义**：运行前检查只承诺可证明的问题，运行时类型错误保持结构化。
- **新手解释困难**：模块保持单一职责，主线示例贯穿 README、测试和演示。
- **时间不足**：核心引擎、测试和文档优先；CLI 保持薄，Playground 不进入 V1。

## 18. 参考链接

- [2026 MoonBit 国产基础软件生态开源大赛—8 月黑客松活动说明](https://bxup9uklfcb.feishu.cn/wiki/KNrVwEVFziPHiGkQtwhc6w3gndd)
- [MoonBit Core JSON 文档](https://mooncakes.io/docs/moonbitlang/core/json)
- [MoonBit QuickCheck 文档](https://mooncakes.io/docs/moonbitlang/core/quickcheck)
- [现有 MoonBit JSON Schema 包](https://mooncakes.io/docs/mizchi/jsonschema)
