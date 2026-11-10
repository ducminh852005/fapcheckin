from __future__ import annotations

import html
import re
from pathlib import Path

from reportlab.graphics.shapes import Drawing, Line, Polygon, Rect, String
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate,
    Flowable,
    Frame,
    KeepTogether,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "course" / "final-report-source.md"
OUTPUT = ROOT / "docs" / "course" / "final-report.pdf"

NAVY = colors.HexColor("#17324D")
BLUE = colors.HexColor("#2563A6")
LIGHT_BLUE = colors.HexColor("#EAF2FA")
ORANGE = colors.HexColor("#F28C28")
GREEN = colors.HexColor("#2E8B57")
RED = colors.HexColor("#C44536")
GRAY = colors.HexColor("#667085")
LIGHT_GRAY = colors.HexColor("#F3F5F7")
INK = colors.HexColor("#182230")


def register_fonts() -> None:
    font_dir = Path(r"C:\Windows\Fonts")
    pdfmetrics.registerFont(TTFont("Arial", str(font_dir / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("ArialBold", str(font_dir / "arialbd.ttf")))
    pdfmetrics.registerFont(TTFont("ArialItalic", str(font_dir / "ariali.ttf")))


def inline_markup(value: str) -> str:
    escaped = html.escape(value, quote=False)
    escaped = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", escaped)
    escaped = re.sub(
        r"`(.+?)`", r'<font name="ArialBold" color="#1D4F7A">\1</font>', escaped
    )
    return escaped


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "Title",
            parent=base["Title"],
            fontName="ArialBold",
            fontSize=20,
            leading=24,
            textColor=NAVY,
            spaceAfter=10,
        ),
        "h2": ParagraphStyle(
            "Heading2",
            parent=base["Heading2"],
            fontName="ArialBold",
            fontSize=12,
            leading=15,
            textColor=BLUE,
            spaceBefore=5,
            spaceAfter=5,
        ),
        "h3": ParagraphStyle(
            "Heading3",
            parent=base["Heading3"],
            fontName="ArialBold",
            fontSize=10,
            leading=13,
            textColor=NAVY,
            spaceBefore=4,
            spaceAfter=3,
        ),
        "body": ParagraphStyle(
            "Body",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=9.3,
            leading=13.1,
            textColor=INK,
            alignment=TA_JUSTIFY,
            spaceAfter=5,
        ),
        "bullet": ParagraphStyle(
            "Bullet",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=9.1,
            leading=12.5,
            leftIndent=13,
            firstLineIndent=-8,
            bulletIndent=2,
            textColor=INK,
            spaceAfter=2.5,
        ),
        "small": ParagraphStyle(
            "Small",
            parent=base["BodyText"],
            fontName="Arial",
            fontSize=7.6,
            leading=9.4,
            textColor=INK,
        ),
        "cover_school": ParagraphStyle(
            "CoverSchool",
            fontName="ArialBold",
            fontSize=13,
            leading=17,
            alignment=TA_CENTER,
            textColor=NAVY,
        ),
        "cover_title": ParagraphStyle(
            "CoverTitle",
            fontName="ArialBold",
            fontSize=28,
            leading=33,
            alignment=TA_CENTER,
            textColor=NAVY,
        ),
        "cover_subtitle": ParagraphStyle(
            "CoverSubtitle",
            fontName="ArialBold",
            fontSize=14,
            leading=18,
            alignment=TA_CENTER,
            textColor=BLUE,
        ),
        "cover_report": ParagraphStyle(
            "CoverReport",
            fontName="ArialBold",
            fontSize=16,
            leading=20,
            alignment=TA_CENTER,
            textColor=ORANGE,
        ),
        "cover_bottom": ParagraphStyle(
            "CoverBottom",
            fontName="Arial",
            fontSize=10,
            leading=14,
            alignment=TA_CENTER,
            textColor=GRAY,
        ),
    }


class AccentRule(Flowable):
    def __init__(self, width: float):
        super().__init__()
        self.width = width
        self.height = 4

    def draw(self) -> None:
        self.canv.setFillColor(ORANGE)
        self.canv.roundRect(0, 0, self.width, 3, 1.5, fill=1, stroke=0)


def arrow(drawing: Drawing, x1: float, y1: float, x2: float, y2: float) -> None:
    drawing.add(Line(x1, y1, x2, y2, strokeColor=BLUE, strokeWidth=1.4))
    angle_x = 5 if x2 >= x1 else -5
    drawing.add(
        Polygon(
            [x2, y2, x2 - angle_x, y2 + 3, x2 - angle_x, y2 - 3],
            fillColor=BLUE,
            strokeColor=BLUE,
        )
    )


def architecture_diagram() -> Drawing:
    d = Drawing(480, 185)

    def box(x: float, y: float, w: float, h: float, label: str, fill: colors.Color) -> None:
        d.add(Rect(x, y, w, h, rx=7, ry=7, fillColor=fill, strokeColor=BLUE, strokeWidth=1))
        lines = label.split("\n")
        for idx, line in enumerate(lines):
            d.add(
                String(
                    x + w / 2,
                    y + h / 2 + (len(lines) - 1 - idx) * 11 - 3,
                    line,
                    fontName="ArialBold" if idx == 0 else "Arial",
                    fontSize=8.5 if idx == 0 else 7.2,
                    textAnchor="middle",
                    fillColor=NAVY,
                )
            )

    box(10, 112, 105, 50, "Flutter Mobile\nMVVM + Core", LIGHT_BLUE)
    box(10, 28, 105, 50, "Web Admin\nPrototype", colors.HexColor("#FFF3E4"))
    box(185, 70, 110, 62, "Firebase\nAuth + Firestore", colors.HexColor("#E9F7EF"))
    box(365, 112, 105, 50, "Cloud Functions\nFCM + OCR", LIGHT_BLUE)
    box(365, 28, 105, 50, "Storage / Config\nCloud Vision", colors.HexColor("#F2ECFA"))
    box(185, 5, 110, 34, "Security Rules\nRBAC + schema", colors.HexColor("#FDECEC"))
    arrow(d, 115, 137, 185, 112)
    arrow(d, 115, 53, 185, 89)
    arrow(d, 295, 112, 365, 137)
    arrow(d, 295, 89, 365, 53)
    arrow(d, 240, 70, 240, 39)
    d.add(String(240, 171, "Kiến trúc triển khai hiện tại", fontName="ArialBold", fontSize=10, textAnchor="middle", fillColor=NAVY))
    return d


def results_chart() -> Drawing:
    d = Drawing(480, 150)
    d.add(String(10, 132, "Android E2E – 30 lượt theo kế hoạch", fontName="ArialBold", fontSize=10, fillColor=NAVY))
    x, y, total_w, h = 10, 88, 460, 25
    segments = [(17, GREEN, "17 Pass"), (8, RED, "8 Fail"), (5, colors.HexColor("#A8B0BA"), "5 chưa chạy")]
    cursor = x
    for value, color, label in segments:
        width = total_w * value / 30
        d.add(Rect(cursor, y, width, h, fillColor=color, strokeColor=colors.white, strokeWidth=0.8))
        d.add(String(cursor + width / 2, y + 8, label, fontName="ArialBold", fontSize=8, textAnchor="middle", fillColor=colors.white))
        cursor += width
    cards = [
        (10, "Functions", "78/78", GREEN),
        (170, "Remote Config", "3/3", BLUE),
        (330, "Exploratory", "15,1 phút", ORANGE),
    ]
    for cx, title, value, color in cards:
        d.add(Rect(cx, 18, 140, 50, rx=6, ry=6, fillColor=colors.white, strokeColor=color, strokeWidth=1.2))
        d.add(String(cx + 70, 47, title, fontName="Arial", fontSize=8, textAnchor="middle", fillColor=GRAY))
        d.add(String(cx + 70, 29, value, fontName="ArialBold", fontSize=13, textAnchor="middle", fillColor=color))
    return d


def table_widths(column_count: int, available: float) -> list[float]:
    if column_count == 2:
        return [available * 0.31, available * 0.69]
    if column_count == 3:
        return [available * 0.18, available * 0.24, available * 0.58]
    if column_count == 4:
        return [available * 0.19, available * 0.17, available * 0.17, available * 0.47]
    return [available / column_count] * column_count


def build_table(rows: list[list[str]], styles: dict[str, ParagraphStyle], available: float) -> Table:
    column_count = max(len(row) for row in rows)
    normalized = [row + [""] * (column_count - len(row)) for row in rows]
    data = [
        [Paragraph(inline_markup(cell), styles["small"]) for cell in row]
        for row in normalized
    ]
    table = Table(data, colWidths=table_widths(column_count, available), repeatRows=1, hAlign="LEFT")
    commands = [
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "ArialBold"),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#C9D2DC")),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    for idx in range(1, len(data)):
        if idx % 2 == 0:
            commands.append(("BACKGROUND", (0, idx), (-1, idx), LIGHT_GRAY))
    table.setStyle(TableStyle(commands))
    return table


def parse_page(
    chunk: str,
    styles: dict[str, ParagraphStyle],
    available: float,
    is_cover: bool,
) -> list[Flowable]:
    lines = [line.rstrip() for line in chunk.splitlines()]
    story: list[Flowable] = []
    if is_cover:
        story.append(Spacer(1, 15 * mm))
        badge = Drawing(150, 60)
        badge.add(Rect(10, 10, 130, 42, rx=10, ry=10, fillColor=NAVY, strokeColor=NAVY))
        badge.add(String(75, 24, "FAP CHECK-IN", fontName="ArialBold", fontSize=16, textAnchor="middle", fillColor=colors.white))
        badge.hAlign = "CENTER"
        story.append(badge)
        story.append(Spacer(1, 8 * mm))

    index = 0
    heading_count = 0
    while index < len(lines):
        line = lines[index].strip()
        if not line or line.startswith("<!--"):
            index += 1
            continue
        if line == "[[ARCH_DIAGRAM]]":
            diagram = architecture_diagram()
            diagram.hAlign = "CENTER"
            story.extend([diagram, Spacer(1, 3 * mm)])
            index += 1
            continue
        if line == "[[RESULTS_CHART]]":
            chart = results_chart()
            chart.hAlign = "CENTER"
            story.extend([chart, Spacer(1, 2 * mm)])
            index += 1
            continue
        if line.startswith("|"):
            rows: list[list[str]] = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                raw = [cell.strip() for cell in lines[index].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-{3,}:?", cell) for cell in raw):
                    rows.append(raw)
                index += 1
            if rows:
                story.extend([build_table(rows, styles, available), Spacer(1, 3 * mm)])
            continue
        if line.startswith("# "):
            heading_count += 1
            text = inline_markup(line[2:].strip())
            if is_cover:
                style = styles["cover_school"] if heading_count == 1 else styles["cover_title"]
                story.append(Paragraph(text, style))
                story.append(Spacer(1, 4 * mm))
            else:
                story.extend([Paragraph(text, styles["title"]), AccentRule(available), Spacer(1, 4 * mm)])
            index += 1
            continue
        if line.startswith("## "):
            text = inline_markup(line[3:].strip())
            if is_cover:
                story.append(Paragraph(text, styles["cover_subtitle"]))
                story.append(Spacer(1, 5 * mm))
            else:
                story.append(Paragraph(text, styles["h2"]))
            index += 1
            continue
        if line.startswith("### "):
            story.append(Paragraph(inline_markup(line[4:].strip()), styles["h3"]))
            index += 1
            continue
        if line.startswith("- "):
            story.append(Paragraph(inline_markup(line[2:].strip()), styles["bullet"], bulletText="•"))
            index += 1
            continue
        numbered = re.match(r"^(\d+)\.\s+(.+)$", line)
        if numbered:
            story.append(
                Paragraph(
                    inline_markup(numbered.group(2)),
                    styles["bullet"],
                    bulletText=numbered.group(1) + ".",
                )
            )
            index += 1
            continue
        if is_cover and line.startswith("**"):
            style = styles["cover_report"] if "BÁO CÁO" in line else styles["cover_bottom"]
            story.extend([Paragraph(inline_markup(line), style), Spacer(1, 5 * mm)])
        else:
            story.append(Paragraph(inline_markup(line), styles["body"]))
        index += 1
    return story


def decorate_page(canvas, doc) -> None:
    canvas.saveState()
    canvas.setTitle("FAP Check-in – Báo cáo dự án cuối kỳ")
    canvas.setAuthor("Nhóm dự án FAP Check-in")
    canvas.setSubject("PRM393 Final Assignment")
    if doc.page > 1:
        width, height = A4
        canvas.setStrokeColor(colors.HexColor("#D5DCE3"))
        canvas.setLineWidth(0.5)
        canvas.line(18 * mm, height - 15 * mm, width - 18 * mm, height - 15 * mm)
        canvas.setFont("ArialBold", 7.5)
        canvas.setFillColor(NAVY)
        canvas.drawString(18 * mm, height - 11.5 * mm, "FAP CHECK-IN • PRM393 FINAL REPORT")
        canvas.setFont("Arial", 7.5)
        canvas.setFillColor(GRAY)
        canvas.drawRightString(width - 18 * mm, 10 * mm, f"Trang {doc.page}")
        canvas.drawString(18 * mm, 10 * mm, "Phiên bản 1.0 • 01/11/2026")
    canvas.restoreState()


def generate() -> None:
    register_fonts()
    styles = make_styles()
    page_width, page_height = A4
    left = right = 18 * mm
    top = 20 * mm
    bottom = 17 * mm
    available = page_width - left - right
    frame = Frame(left, bottom, available, page_height - top - bottom, id="normal", showBoundary=0)
    document = BaseDocTemplate(
        str(OUTPUT),
        pagesize=A4,
        leftMargin=left,
        rightMargin=right,
        topMargin=top,
        bottomMargin=bottom,
        title="FAP Check-in – Báo cáo dự án cuối kỳ",
        author="Nhóm dự án FAP Check-in",
    )
    document.addPageTemplates(PageTemplate(id="report", frames=[frame], onPage=decorate_page))

    raw = SOURCE.read_text(encoding="utf-8")
    chunks = re.split(r"<!-- PAGE(?:\s*:\s*COVER)? -->", raw)
    chunks = [chunk.strip() for chunk in chunks if chunk.strip()]
    story: list[Flowable] = []
    for idx, chunk in enumerate(chunks):
        story.extend(parse_page(chunk, styles, available, is_cover=idx == 0))
        if idx < len(chunks) - 1:
            story.append(PageBreak())
    document.build(story)
    print(OUTPUT)


if __name__ == "__main__":
    generate()
