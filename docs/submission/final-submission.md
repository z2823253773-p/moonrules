# MoonRules 最终提交总控台

这份文件用于黑客松平台最终提交、答辩准备和人工复核。所有链接、数字和声明都应与仓库当前公开状态保持一致。

## 平台填写建议

### 项目名称

MoonRules

### 申报方向

API 动态规则校验引擎

### 一句话简介

MoonRules 是 MoonBit 原生的可解释 JSON 业务规则引擎。它不只返回 `true/false`，还告诉开发者哪一步失败、变量取到了什么值、哪些分支因为短路被跳过。

### 项目简介

业务系统经常把 API 准入、优惠券资格、会员权益和配置策略写成 JSON 规则，但执行结果通常只有 `true` 或 `false`。当结果不符合预期时，开发者还要翻日志、补埋点、复现输入，才能定位是哪一步失败。JSON Schema 可以验证字段结构，却无法表达“成年学生且订单满 100 元”这类跨字段业务条件，更解释不了失败路径。

MoonRules 使用 MoonBit 实现一套小而明确的 JSON DSL。规则会被解析成类型化规则树，执行前由 Checker 给出诊断，执行后生成结构化 Trace。Trace 记录变量取值、比较结果、错误传播和短路原因。项目已经提供核心库、CLI、在线 Playground、Mooncakes 包、GitHub Release、技术文档、测试矩阵和基准报告。

### 项目亮点

1. 可解释执行树：变量、字面量和操作符都是独立 Trace 节点，失败原因可以直接展开查看。
2. 运行前诊断：操作符、参数数量、数据路径、字面量类型和预算问题在执行前暴露，并返回稳定错误码、规则路径和修改建议。
3. 确定性安全预算：规则深度、节点数、执行步骤和 Trace 节点数都有硬限制。超限时返回结构化错误，而不是崩溃或静默失败。
4. 公开可复现闭环：GitHub 代码、Mooncakes 包、公网 Playground、GitHub Release、测试矩阵和 1-1000 节点基准全部公开可查。

### 技术栈

- MoonBit core library
- MoonBit native CLI
- MoonBit JavaScript target Web Adapter
- Vite + TypeScript + CodeMirror 6 Playground
- GitHub Actions CI
- Mooncakes package registry

### 不做什么

MoonRules 不是完整 JSONLogic 兼容实现，也不替代 JSON Schema。当前版本不支持数组下标路径、循环、用户自定义函数、自定义操作符、数据库、服务器、登录系统或原生桌面 GUI。Playground 是唯一 GUI 入口，并且是纯静态、本地浏览器执行。

## 公开链接

| 用途 | 链接 |
|---|---|
| GitHub 仓库 | https://github.com/z2823253773-p/moonrules |
| 在线 Playground | https://z2823253773-p.github.io/moonrules/ |
| Mooncakes 包 | https://mooncakes.io/docs/z2823253773-p/moonrules |
| GitHub Release | https://github.com/z2823253773-p/moonrules/releases/tag/v0.2.0 |
| 最新 main CI | https://github.com/z2823253773-p/moonrules/actions |
| 技术报告 | https://github.com/z2823253773-p/moonrules/blob/main/docs/technical-report.md |
| 基准报告 | https://github.com/z2823253773-p/moonrules/blob/main/docs/BENCHMARKS.md |
| 一页申报书 PDF | https://github.com/z2823253773-p/moonrules/blob/main/output/pdf/moonrules-application.pdf |
| Demo GIF | https://github.com/z2823253773-p/moonrules/blob/main/docs/assets/moonrules-playground.gif |

## 本地交付物位置

| 交付物 | 路径 |
|---|---|
| README 首屏 | `README.md` |
| 申报书 Markdown | `docs/submission/moonrules-application.md` |
| 一页申报书 PDF | `output/pdf/moonrules-application.pdf` |
| PDF 生成脚本 | `scripts/build_application_pdf.py` |
| Demo GIF | `docs/assets/moonrules-playground.gif` |
| Demo 脚本 | `docs/demo-script.md` |
| 验收清单 | `docs/acceptance-checklist.md` |
| 技术报告 | `docs/technical-report.md` |
| 架构说明 | `docs/ARCHITECTURE.md` |
| 基准测试报告 | `docs/BENCHMARKS.md` |

注意：一页申报书 PDF 的内容硬编码在 `scripts/build_application_pdf.py` 中。修改 PDF 文案时必须同步修改脚本并重新运行：

```bash
python3 scripts/build_application_pdf.py
```

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

## 90 秒演示主线

1. 打开 Playground。
2. 选择默认“优惠券资格”规则和 guest 数据，点击 Evaluate。
3. 展示结果 `FAIL`，指出 `user.age` 和 `order.total` 满足条件，但 `user.role = "guest"` 不等于 `"student"`。
4. 切换 pass 数据，重新执行，展示 `PASS`。
5. 切换 Full、Summary、Off 三种 Trace 模式，说明它们只改变输出形状，不改变 Decision 和 Stats。
6. 展示 CLI JSON 输出、测试矩阵、Mooncakes 安装、GitHub Release 和基准报告。

完整口播脚本见 `docs/demo-script.md`。

## AI 辅助开发声明

AI 编程助手 Codex 和 Claude Code 参与了本项目的规划、实现、测试和文档编写。参赛者 Hengrui Zhang 负责项目范围和 DSL 设计、公开发布确认、所有 AI 生成变更的人工审核、测试和构建验证、安全与许可证合规、申报材料最终审核。项目不隐瞒 AI 辅助，也不把未经验证的 AI 输出包装成手工完成的结果。

## 提交前人工复核清单

- [ ] 比赛平台标题使用“MoonRules”。
- [ ] 项目方向填写“API 动态规则校验引擎”。
- [ ] GitHub 仓库链接可打开。
- [ ] Playground 链接可打开，并能完成 FAIL 到 PASS 演示。
- [ ] Mooncakes 包链接可打开，版本为 `0.2.0`。
- [ ] GitHub Release 链接可打开，版本为 `v0.2.0`。
- [ ] PDF 能正常预览或下载。
- [ ] README 首屏截图或链接可用于评审快速扫读。
- [ ] AI 辅助声明没有被删除或弱化。
- [ ] 如平台要求视频，按 `docs/demo-script.md` 录制 90 秒演示。

## 推荐提交顺序

1. 先填项目名称、方向、一句话简介和项目简介。
2. 填 GitHub 仓库、Playground、Mooncakes 和 Release 链接。
3. 上传或附上一页申报书 PDF。
4. 如平台支持补充材料，附 Demo GIF、技术报告和基准报告。
5. 最后粘贴 AI 辅助开发声明，并人工检查所有链接。
