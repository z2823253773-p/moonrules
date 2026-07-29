from pathlib import Path
import re

from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "moonrules-application.pdf"
FONT_PATH = Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf")

INK = HexColor("#15233B")
MUTED = HexColor("#58677D")
ACCENT = HexColor("#6254E7")
ACCENT_2 = HexColor("#00A7A5")
PALE = HexColor("#F5F6FF")
PALE_2 = HexColor("#EEF9F8")
LINE = HexColor("#DCE1EA")


def wrap_text(text: str, width: float, font: str, size: float) -> list[str]:
    lines: list[str] = []
    current = ""
    tokens = re.findall(
        r"\n|[A-Za-z0-9_.@/:+-]+(?:\s+)?|[^\x00-\x7F]|\s+|.",
        text,
    )
    for token in tokens:
        if token == "\n":
            lines.append(current.rstrip())
            current = ""
            continue
        candidate = current + token
        if current and pdfmetrics.stringWidth(candidate, font, size) > width:
            lines.append(current.rstrip())
            current = token.lstrip()
        else:
            current = candidate.lstrip() if not current else candidate
        if pdfmetrics.stringWidth(current, font, size) > width:
            oversized = current
            current = ""
            for char in oversized:
                candidate = current + char
                if current and pdfmetrics.stringWidth(candidate, font, size) > width:
                    lines.append(current.rstrip())
                    current = char
                else:
                    current = candidate
    if current:
        lines.append(current.rstrip())
    return lines


def draw_wrapped(
    c: canvas.Canvas,
    text: str,
    x: float,
    y: float,
    width: float,
    *,
    font: str = "CJK",
    size: float = 8.2,
    leading: float = 11.2,
    color=INK,
    max_lines: int | None = None,
) -> float:
    lines = wrap_text(text, width, font, size)
    if max_lines is not None and len(lines) > max_lines:
        lines = lines[:max_lines]
        tail = lines[-1]
        while tail and pdfmetrics.stringWidth(tail + "…", font, size) > width:
            tail = tail[:-1]
        lines[-1] = tail + "…"
    c.setFillColor(color)
    c.setFont(font, size)
    for line in lines:
        c.drawString(x, y, line)
        y -= leading
    return y


def draw_card(
    c: canvas.Canvas,
    x: float,
    top: float,
    width: float,
    height: float,
    title: str,
    body: str,
    *,
    fill=white,
    accent=ACCENT,
    body_size: float = 8.1,
) -> None:
    bottom = top - height
    c.setFillColor(fill)
    c.setStrokeColor(LINE)
    c.roundRect(x, bottom, width, height, 9, fill=1, stroke=1)
    c.setFillColor(accent)
    c.roundRect(x + 10, top - 24, 4, 14, 2, fill=1, stroke=0)
    c.setFillColor(INK)
    c.setFont("CJK", 10.2)
    c.drawString(x + 21, top - 21, title)
    draw_wrapped(
        c,
        body,
        x + 13,
        top - 38,
        width - 26,
        size=body_size,
        leading=10.9,
        color=MUTED,
        max_lines=max(1, int((height - 45) / 10.9)),
    )


def build() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdfmetrics.registerFont(TTFont("CJK", str(FONT_PATH)))

    page_w, page_h = A4
    c = canvas.Canvas(str(OUTPUT), pagesize=A4)
    c.setTitle("MoonRules 项目申报书")
    c.setAuthor("z2823253773-p")

    c.setFillColor(INK)
    c.rect(0, page_h - 118, page_w, 118, fill=1, stroke=0)
    c.setFillColor(ACCENT)
    c.circle(page_w - 46, page_h - 30, 52, fill=1, stroke=0)
    c.setFillColor(ACCENT_2)
    c.circle(page_w - 8, page_h - 94, 42, fill=1, stroke=0)

    c.setFillColor(white)
    c.setFont("CJK", 23)
    c.drawString(32, page_h - 47, "MoonRules 项目申报书")
    c.setFont("CJK", 10.5)
    c.drawString(33, page_h - 70, "MoonBit 原生的可解释 API 动态规则校验引擎")
    c.setFillColor(HexColor("#D8DDF6"))
    c.setFont("CJK", 8.4)
    c.drawString(33, page_h - 91, "V2 · 0.2.0   |   Apache-2.0   |   71 native / 71 wasm-gc tests   |   11 browser e2e")

    margin = 32
    gutter = 14
    col_w = (page_w - margin * 2 - gutter) / 2
    left = margin
    right = margin + col_w + gutter
    top = page_h - 132
    gap = 8

    draw_card(
        c,
        left,
        top,
        col_w,
        86,
        "项目定位与生态价值",
        "面向 API 准入、资格判断和配置策略。JSON Schema 验证结构；MoonRules 判断合法数据是否满足动态业务条件，并解释每一步原因。",
        fill=PALE,
    )
    top_l = top - 86 - gap
    draw_card(
        c,
        left,
        top_l,
        col_w,
        78,
        "已有基础",
        "核心引擎、原生 CLI、Web Adapter、静态 Playground、三个业务示例、中英文文档、Issue/PR 模板和贡献指南均已完成。格式、零警告检查、native/wasm-gc 构建全部通过。",
    )
    top_l -= 78 + gap
    draw_card(
        c,
        left,
        top_l,
        col_w,
        98,
        "本次新增范围（v0.2）",
        "三种 Trace 输出模式；诊断 JSON 序列化；CLI JSON/stdin/help/version；Web Adapter（JS 目标）；静态 Playground（Vite + CodeMirror 6 + Playwright 测试）；可复现基准测试；架构文档和技术报告。",
        fill=PALE_2,
        accent=ACCENT_2,
    )
    top_l -= 98 + gap
    draw_card(
        c,
        left,
        top_l,
        col_w,
        126,
        "技术路线",
        "JSON 规则依次通过 Parser → Checker → Evaluator → Full Report → TraceMode 压缩。可移植核心不依赖文件/环境/进程/网络 API；原生 I/O 仅存在于 CLI，DOM 副作用仅存在于 Playground。",
    )
    top_l -= 126 + gap
    draw_card(
        c,
        left,
        top_l,
        col_w,
        82,
        "开源与许可证",
        "Apache-2.0；GitHub、CI、Pages 与 Mooncakes 均已公开；z2823253773-p/moonrules@0.2.0 已发布。AI 辅助开发：规划/实现/测试/文档经人工逐项审核。",
        fill=PALE,
    )

    draw_card(
        c,
        right,
        top,
        col_w,
        166,
        "核心创新",
        "1. 可解释执行：独立变量/字面量/操作符 Trace 节点，Full/Summary/Off 三种输出模式。\n2. 运行前诊断：操作符存在性、参数数量、路径格式、字面量类型、预算超限。\n3. 确定性预算：深度/节点/步骤/Trace 五重限制，超限安全失败并保留部分 Trace。",
        fill=PALE,
        body_size=8.25,
    )
    top_r = top - 166 - gap
    draw_card(
        c,
        right,
        top_r,
        col_w,
        136,
        "交付、测试与文档",
        "71 原生 + 71 wasm-gc + 18 QuickCheck + 11 Playwright + 6 Vitest 测试。3 组业务示例（含 pass/fail 数据）。CLI 黑盒脚本。可复现基准（1-1000 节点）。中文主 README、英文入口、5 份参考文档。",
        fill=PALE_2,
        accent=ACCENT_2,
    )
    top_r -= 136 + gap
    draw_card(
        c,
        right,
        top_r,
        col_w,
        94,
        "时间安排",
        "7/27 设计定稿 → 7/28 TraceMode/CLI → 7/29 Playground → 7/30 基准/文档/CI → 7/31 申报材料/预发布。工作日每天持续提交、持续跑全量矩阵。",
    )
    top_r -= 94 + gap
    draw_card(
        c,
        right,
        top_r,
        col_w,
        116,
        "评审演示主线",
        "打开优惠券规则与 guest 数据 → FAIL → user.age 满足但 user.role 不匹配 → order.total 短路跳过 → 切换 Summary/Off → 展示 CLI JSON 输出和退出码 → 测试/Benchmark/仓库链接。",
        fill=PALE,
    )

    evidence_y = 38
    c.setFillColor(INK)
    c.roundRect(margin, evidence_y, page_w - margin * 2, 48, 10, fill=1, stroke=0)
    c.setFillColor(white)
    c.setFont("CJK", 9.2)
    c.drawString(margin + 14, evidence_y + 29, "发布证据")
    c.setFillColor(HexColor("#D8DDF6"))
    c.setFont("CJK", 7.5)
    c.drawString(
        margin + 14,
        evidence_y + 14,
        "GitHub: z2823253773-p/moonrules   ·   Pages: public   ·   Mooncakes: v0.2.0 published   ·   Release: v0.2.0",
    )

    c.setFillColor(MUTED)
    c.setFont("CJK", 7.2)
    c.drawRightString(page_w - margin, 20, "MoonRules · 2026-07-29 · z2823253773-p")
    c.showPage()
    c.save()


if __name__ == "__main__":
    build()
