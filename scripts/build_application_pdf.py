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
    c.drawString(33, page_h - 91, "V1 · 0.1.0   |   Apache-2.0   |   63 native / 60 wasm-gc tests")

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
        "面向 API 准入、资格判断、表单逻辑和配置策略。JSON Schema 验证结构；MoonRules 判断合法数据是否满足动态业务条件，并解释每一步原因。",
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
        "核心库、原生 CLI、三个业务示例、中英文文档和许可证已完成。格式、零警告检查、native 与 wasm-gc 构建全部通过。",
    )
    top_l -= 78 + gap
    draw_card(
        c,
        left,
        top_l,
        col_w,
        98,
        "本次新增范围",
        "15 种节点/操作符形式；JSON DSL 解析；运行前检查；三态求值；结构化 Trace；确定性预算；check/eval CLI；QuickCheck；CI 与发布包。",
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
        "JSON 规则依次通过 Parser → Checker → Evaluator → Renderer。可移植核心不依赖文件、环境、进程或网络 API，副作用仅位于 native CLI。and: false > error > true；or: true > error > false。",
    )
    top_l -= 126 + gap
    draw_card(
        c,
        left,
        top_l,
        col_w,
        82,
        "开源与许可证",
        "Apache-2.0；GitHub: z2823253773-p/moonrules；CI 已通过。包名 z2823253773-p/moonrules@0.1.0。",
        fill=PALE,
    )

    draw_card(
        c,
        right,
        top,
        col_w,
        166,
        "核心创新",
        "1. 可解释执行：变量、字面量和操作符均为独立 Trace 节点。\n2. 运行前诊断：提前发现参数、路径、字面量类型和静态预算问题。\n3. 确定性预算：限制深度、节点、步骤和 Trace；超限保留部分 Trace，并在截断点写入结构化错误。",
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
        "优惠券、API 准入、会员资格三组可运行示例。60 个跨目标核心测试 + 3 个 native CLI 测试，其中含 16 个固定种子性质测试。中文主 README、英文入口及 DSL/API/错误参考齐备。",
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
        "核心实现、GitHub 公开与 CI 已完成。下一步：mooncakes.io 发布 → 最终链接回填 → 演示录制。工作日每天 1-2 小时，小步提交。",
    )
    top_r -= 94 + gap
    draw_card(
        c,
        right,
        top_r,
        col_w,
        116,
        "评审演示主线",
        "输入优惠券规则与 guest 数据 → 运行前检查通过 → 输出 FAIL → 展示 user.age 与字面量 18 的独立节点 → user.role 比较失败 → order.total 分支明确标记 SKIPPED。",
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
        "GitHub: z2823253773-p/moonrules   ·   CI: PASS #29985024289   ·   mooncakes.io: 待确认",
    )

    c.setFillColor(MUTED)
    c.setFont("CJK", 7.2)
    c.drawRightString(page_w - margin, 20, "MoonRules · 2026-07-23 · z2823253773-p")
    c.showPage()
    c.save()


if __name__ == "__main__":
    build()
