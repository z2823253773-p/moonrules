# MoonRules

[![CI](https://github.com/z2823253773-p/moonrules/actions/workflows/ci.yml/badge.svg)](https://github.com/z2823253773-p/moonrules/actions/workflows/ci.yml)

MoonBit 原生的可解释、受预算限制的 JSON 业务规则引擎。

MoonRules 把动态业务条件解析成类型明确的规则树，在执行前给出诊断，在执行后返回 `Pass`、`Fail` 或 `Indeterminate`，并保留每一步变量取值、比较结果、错误与短路原因。v0.2 新增**三种 Trace 输出模式**和 **CLI JSON/stdin 支持**。

在线 Playground 和完整文档见 [GitHub 仓库](https://github.com/z2823253773-p/moonrules)。

## 为什么不是 JSON Schema

**JSON Schema validates structure; MoonRules evaluates business decisions and explains them.**

JSON Schema 适合回答”输入的字段和类型是否合法”；MoonRules 回答”这份合法输入是否满足当前业务条件，以及为什么”。例如，订单结构可以完全合法，但用户仍可能因为年龄、身份或金额不满足优惠券规则。

## 30 秒示例

规则：

```json
{
  “id”: “student-coupon”,
  “description”: “满 100 元的成年学生可以使用优惠券”,
  “condition”: {
    “and”: [
      {“>=”: [{“var”: “user.age”}, 18]},
      {“==”: [{“var”: “user.role”}, “student”]},
      {“>=”: [{“var”: “order.total”}, 100]}
    ]
  }
}
```

数据（学生但角色为 guest，不通过）：

```json
{
  “user”: { “age”: 20, “role”: “guest” },
  “order”: { “total”: 128 }
}
```

结果：

```text
FAIL student-coupon
├─ PASS user.age >= 18
│  ├─ VALUE var(user.age) = 20
│  └─ VALUE literal = 18
├─ FAIL user.role == “student”
│  ├─ VALUE var(user.role) = “guest”
│  └─ VALUE literal = “student”
└─ SKIPPED order.total >= 100
   └─ reason: and short-circuited
```

不仅返回 `Fail`，还告诉你**哪个条件失败了、实际值是什么、哪些分支被短路跳过**。

## 安装

```bash
moon add z2823253773-p/moonrules@0.2.0
```

## 库 API

- `parse(source)`：解析 JSON 字符串为 `RuleDocument`。
- `check(rule, budget?)`：返回 `Array[Diagnostic]`；空数组表示通过。
- `evaluate(rule, data, budget, trace_mode?)`：执行已解析规则，支持 `Full`、`Summary`、`Off` 三种 Trace 模式。
- `evaluate_json(rule_source, data_source, budget?, trace_mode?)`：完成解析、检查与执行。

结构化输出：`report_to_json`、`diagnostics_to_json`、`render_report`。完整契约见 [docs/API.md](docs/API.md)。

## Trace 模式

v0.2 支持三种输出模式，先执行相同的完整求值再做成形，因此 **Decision 和 Stats 始终一致**：

- **Full**：完整 Trace，包含所有变量、字面量、操作符节点。
- **Summary**：去掉普通取值叶节点，保留操作符、错误和短路节点。
- **Off**：仅返回根节点，保留 Decision 和 Stats。

## CLI

文件输入、stdin（`-`）、`--json`、`--help`、`--version`：

```bash
moon run --target native cmd/main check examples/coupon.rule.json --json
moon run --target native cmd/main eval examples/coupon.rule.json --data examples/coupon.data.json --json
cat rule.json | moon run --target native cmd/main check - --json
```

退出码 `0`（Pass/检查通过）、`1`（Fail）、`2`（错误/Indeterminate）。

## 运行前检查与安全预算

`check` 在无数据时检查操作符存在性、参数数量、数据路径格式和预算限制。执行时用深度（64）、节点数（4096）、步骤（10000）、Trace 节点（4096）和预览字符（256）五个确定性预算保护，超限安全失败并保留部分 Trace。

## 操作符（V1）

`var`、`literal`、`and`、`or`、`not`、`==`、`!=`、`>`、`>=`、`<`、`<=`、`in`、`contains`、`starts_with`、`ends_with`。详见 [docs/DSL.md](docs/DSL.md)。

## 限制

不提供完整 JSONLogic 兼容、数组下标数据路径、循环、用户函数、自定义操作符、网络访问、数据库、Web 服务或原生桌面 GUI。

## 许可证

Apache License 2.0。详见 [LICENSE](LICENSE)。
