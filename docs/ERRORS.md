# MoonRules 错误、三态逻辑与预算

## 三态结果

- `Pass`：规则可靠地求值为 `true`。
- `Fail`：规则可靠地求值为 `false`。
- `Indeterminate(EvalError)`：缺失变量、类型不匹配、预算超限或不支持的 Trace 模式使结果无法可靠确定。

CLI 不把 `Indeterminate` 当成通过。

## 错误传播

### `and`

按顺序执行。`false` 是决定性结果，因此优先级为 `false > error > true`。遇到错误后仍可继续寻找 `false`；一旦找到 `false`，剩余节点标记为 `Skipped`。

### `or`

按顺序执行。`true` 是决定性结果，因此优先级为 `true > error > false`。遇到错误后仍可继续寻找 `true`；一旦找到 `true`，剩余节点标记为 `Skipped`。

### 其他操作符

`not(error)` 保持错误。比较、集合和文本操作任一已执行输入出错时，父节点返回错误。缺失字段产生 `MissingVariable`，不会静默变成 `null`。

## 运行前诊断

常见代码：

- `E_ARITY`：操作符参数数量错误。
- `E_DATA_PATH`：数据路径使用了 V1 不支持的语法。
- `E_LITERAL_TYPE`：可静态证明的字面量类型错误。
- `E_MAX_DEPTH`：规则深度超过调用方配置。
- `E_MAX_RULE_NODES`：规则节点数超过调用方配置。
- `E_BUDGET_LIMIT`：调用方试图突破库上限。

## 执行预算

执行器分别检查规则深度、规则节点、执行步骤和 Trace 节点。Trace 预算预留最后一个节点：达到截断点时，该节点被写成 `Error`，说明预算名称、当前计数和上限，未开始的后代不再展开。

已产生的 Trace 永远保留。这让调用方既能安全失败，也能看到执行停止的位置。

## Trace 状态

- `Value`：变量或字面量成功产生值。
- `Pass` / `Fail`：布尔操作成功完成。
- `Error`：当前节点无法可靠完成。
- `Skipped`：父逻辑操作已经得到决定性结果。

文本预览可能截断长值；结构化 JSON 报告仍受 Trace 节点预算约束。
