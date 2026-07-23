# MoonRules

MoonBit 原生的可解释、受预算限制的 JSON 业务规则引擎。

MoonRules 把动态业务条件解析成类型明确的规则树，在执行前给出诊断，在执行后返回 `Pass`、`Fail` 或 `Indeterminate`，并保留每一步变量取值、比较结果、错误与短路原因。

## 为什么不是 JSON Schema

**JSON Schema validates structure; MoonRules evaluates business decisions and explains them.**

JSON Schema 适合回答“输入的字段和类型是否合法”；MoonRules 回答“这份合法输入是否满足当前业务条件，以及为什么”。例如，订单结构可以完全合法，但用户仍可能因为年龄、身份或金额不满足优惠券规则。

## 30 秒示例

规则：

```json
{
  "id": "adult-check",
  "description": "成年人准入",
  "condition": {
    ">=": [{ "var": "user.age" }, 18]
  }
}
```

数据：

```json
{
  "user": { "age": 20 }
}
```

结果不仅是 `Pass`，还包含独立的变量和字面量 Trace：

```text
PASS adult-check [>=]
├─ VALUE var(user.age)
│  └─ result = 20
├─ VALUE literal
│  └─ result = 18
└─ result = true
```

## 安装

先安装 MoonBit 工具链：

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
```

克隆项目后验证：

```bash
moon check --deny-warn
moon test
moon build --target native
```

## 库 API

公共入口只有四组：

- `parse(source)`：解析 JSON 字符串为 `RuleDocument`。
- `check(rule, budget?)`：返回 `Array[Diagnostic]`；空数组表示通过。
- `evaluate(rule, data, budget, trace_mode?)`：执行已解析规则。
- `evaluate_json(rule_source, data_source, budget?, trace_mode?)`：完成解析、检查与执行。

文本输出使用 `render_report`，结构化输出使用 `report_to_json`。完整契约见 [docs/API.md](docs/API.md)。

## CLI

检查规则：

```bash
moon run --target native cmd/main check examples/coupon.rule.json
```

执行规则：

```bash
moon run --target native cmd/main eval examples/coupon.rule.json --data examples/coupon.data.json
```

退出码：

- `0`：规则通过。
- `1`：规则执行成功，但结果不通过。
- `2`：参数、I/O、解析、检查或执行出现错误。

## 可解释 Trace

每个 `var`、字面量和操作符都有独立 Trace 节点。节点记录规则路径、状态、已解析输入、结果、消息和子节点。

`and` 遇到确定性 `false`、`or` 遇到确定性 `true` 后，未执行的同级节点会标记为 `SKIPPED`，不会假装已经计算。预算超限时保留已有 Trace，并在截断点写入 `ERROR` 节点。

## 运行前检查

`check` 在没有运行时数据的情况下检查：

- 操作符参数数量。
- V1 点号数据路径。
- 明显错误的字面量类型。
- 规则深度和节点数。
- 调用方预算是否突破库上限。

诊断包含稳定的错误码、规则路径、说明和修改建议。

## 安全预算

默认确定性预算：

| 预算 | 默认上限 |
|---|---:|
| 规则深度 | 64 |
| 规则节点 | 4096 |
| 执行步骤 | 10000 |
| Trace 节点 | 4096 |
| 文本预览字符 | 256 |

调用方可以调低限制，但不能突破默认上限。MoonRules 不使用墙钟超时改变规则结果。

## V1 操作符

- 数据：`var`、`literal`
- 逻辑：`and`、`or`、`not`
- 比较：`==`、`!=`、`>`、`>=`、`<`、`<=`
- 集合与字符串：`in`、`contains`、`starts_with`、`ends_with`

完整参数数量、类型和示例见 [docs/DSL.md](docs/DSL.md)。

## 示例

- 优惠券资格：`examples/coupon.*`
- API 请求准入：`examples/api-access.*`
- 会员资格：`examples/membership.*`

每个场景都提供通过和不通过的数据。`examples/coupon.data.json` 是主演示中的不通过输入。

## 限制与非目标

V1 不提供完整 JSONLogic 兼容、数组下标数据路径、循环、用户函数、自定义操作符、网络访问、数据库、Web 服务或 GUI。`TraceMode::Off` 和 `Summary` 只保留 API 形状，调用时会明确返回 `UnsupportedTraceMode`。

## 开发与测试

```bash
moon fmt --check
moon check --deny-warn
moon test --target native
moon test --target wasm-gc
moon build --target native
moon build --target wasm-gc
```

核心库保持跨目标；CLI 因文件和终端 I/O 明确限定为 native。

## 许可证

Apache License 2.0。详见 [LICENSE](LICENSE)。
