#!/usr/bin/env python3
"""Reproducible comparison of space and zero-width text steganography.

The script creates HTML and PDF carriers, applies two sanitizing attacks,
checks extraction, writes CSV results and draws compact PNG charts.
"""

from __future__ import annotations

import csv
import hashlib
import html
import os
import re
import shutil
import subprocess
import unicodedata
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path

import pdfplumber
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from reportlab.lib.enums import TA_JUSTIFY
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "output"
HTML_DIR = OUT / "samples" / "html"
PDF_DIR = OUT / "samples" / "pdf"
RENDER_DIR = OUT / "renders"
CHART_DIR = OUT / "charts"
RESULT_DIR = OUT / "results"

SPACE_ZERO = "\u0020"
SPACE_ONE = "\u00a0"
ZW_ZERO = "\u200b"
ZW_ONE = "\u200c"


EN_BASE = (
    "Text steganography hides information inside an ordinary document while the visible message remains readable. "
    "A reliable experiment must separate visual similarity from technical robustness because an invisible marker can still be removed by a converter. "
    "The carrier in this study describes a bicycle route planner that records distance, duration, elevation, and selected map points. "
    "Users can compare routes, attach short notes, export a trip summary, and share selected results with a study group. "
    "The paragraph intentionally contains common punctuation and words of different lengths so that line wrapping resembles a normal report. "
)

RU_BASE = (
    "Текстовая стеганография скрывает данные внутри обычного документа, сохраняя читаемость видимого сообщения. "
    "Корректный эксперимент должен разделять визуальное сходство и техническую стойкость, потому что невидимый маркер может исчезнуть при конвертации. "
    "Текст-контейнер описывает велотрекер, который сохраняет расстояние, длительность, набор высоты и выбранные точки маршрута. "
    "Пользователь может сравнивать поездки, добавлять заметки, экспортировать сводку и делиться отдельными результатами с учебной группой. "
    "В абзаце намеренно использованы знаки препинания и слова разной длины, чтобы перенос строк был похож на обычный отчёт. "
)


@dataclass(frozen=True)
class Case:
    method: str
    language: str
    length_name: str
    message: bytes


class TextExtractor(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.in_paragraph = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "p":
            self.in_paragraph = True

    def handle_endtag(self, tag: str) -> None:
        if tag == "p":
            self.in_paragraph = False
            self.parts.append("\n\n")

    def handle_data(self, data: str) -> None:
        if self.in_paragraph:
            self.parts.append(data)

    def text(self) -> str:
        return "".join(self.parts)


def payload_bits(message: bytes) -> str:
    framed = len(message).to_bytes(4, "big") + message
    return "".join(f"{byte:08b}" for byte in framed)


def bits_to_message(bits: str) -> bytes | None:
    if len(bits) < 32:
        return None
    length = int(bits[:32], 2)
    needed = 32 + length * 8
    if length > 1_000_000 or len(bits) < needed:
        return None
    body = bits[32:needed]
    return bytes(int(body[i : i + 8], 2) for i in range(0, len(body), 8))


def capacity(text: str, method: str) -> int:
    if method == "space":
        return text.count(SPACE_ZERO)
    return sum(1 for ch in text if not ch.isspace())


def embed_space(text: str, message: bytes) -> str:
    bits = iter(payload_bits(message))
    result: list[str] = []
    exhausted = False
    for ch in text:
        if ch == SPACE_ZERO and not exhausted:
            try:
                result.append(SPACE_ONE if next(bits) == "1" else SPACE_ZERO)
            except StopIteration:
                exhausted = True
                result.append(ch)
        else:
            result.append(ch)
    if not exhausted:
        try:
            next(bits)
        except StopIteration:
            exhausted = True
    if not exhausted:
        raise ValueError("Carrier has insufficient spaces")
    return "".join(result)


def embed_zero_width(text: str, message: bytes) -> str:
    bits = iter(payload_bits(message))
    result: list[str] = []
    exhausted = False
    for ch in text:
        result.append(ch)
        if not ch.isspace() and not exhausted:
            try:
                result.append(ZW_ONE if next(bits) == "1" else ZW_ZERO)
            except StopIteration:
                exhausted = True
    if not exhausted:
        try:
            next(bits)
        except StopIteration:
            exhausted = True
    if not exhausted:
        raise ValueError("Carrier has insufficient visible characters")
    return "".join(result)


def embed(text: str, message: bytes, method: str) -> str:
    return embed_space(text, message) if method == "space" else embed_zero_width(text, message)


def extract_space(text: str) -> bytes | None:
    bits = "".join("1" if ch == SPACE_ONE else "0" for ch in text if ch in {SPACE_ZERO, SPACE_ONE})
    return bits_to_message(bits)


def extract_zero_width(text: str) -> bytes | None:
    bits = "".join("1" if ch == ZW_ONE else "0" for ch in text if ch in {ZW_ZERO, ZW_ONE})
    return bits_to_message(bits)


def extract(text: str, method: str) -> bytes | None:
    return extract_space(text) if method == "space" else extract_zero_width(text)


def normalize_whitespace(text: str) -> str:
    return "".join("\n" if ch == "\n" else SPACE_ZERO if ch.isspace() else ch for ch in text)


def strip_format_chars(text: str) -> str:
    return "".join(ch for ch in text if unicodedata.category(ch) != "Cf")


def make_cover(language: str) -> str:
    base = EN_BASE if language == "en" else RU_BASE
    paragraphs = []
    for i in range(1, 16):
        prefix = f"Experiment paragraph {i}. " if language == "en" else f"Экспериментальный абзац {i}. "
        paragraphs.append(prefix + base)
    return "\n\n".join(paragraphs)


def html_document(text: str, title: str) -> str:
    paragraphs = "\n".join(f"<p>{html.escape(p)}</p>" for p in text.split("\n\n"))
    return f"""<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <title>{html.escape(title)}</title>
  <style>
    body {{ max-width: 860px; margin: 40px auto; font: 18px/1.55 Georgia, serif; color: #111; }}
    h1 {{ font-size: 26px; }}
    p {{ text-align: justify; }}
  </style>
</head>
<body><h1>{html.escape(title)}</h1>{paragraphs}</body>
</html>
"""


def html_visible_text(source: str) -> str:
    parser = TextExtractor()
    parser.feed(source)
    return parser.text()


def register_font() -> str:
    candidates = [
        Path("/usr/share/fonts/TTF/DejaVuSans.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    ]
    for font_path in candidates:
        if font_path.exists():
            pdfmetrics.registerFont(TTFont("DejaVuSans", str(font_path)))
            return "DejaVuSans"
    return "Helvetica"


def write_pdf(path: Path, text: str, title: str, font_name: str) -> None:
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "LabTitle", parent=styles["Title"], fontName=font_name, fontSize=16, leading=20, spaceAfter=8 * mm
    )
    body_style = ParagraphStyle(
        "LabBody", parent=styles["BodyText"], fontName=font_name, fontSize=10.5, leading=14,
        alignment=TA_JUSTIFY, firstLineIndent=8 * mm, spaceAfter=3 * mm,
    )
    doc = SimpleDocTemplate(
        str(path), pagesize=letter, leftMargin=20 * mm, rightMargin=20 * mm,
        topMargin=18 * mm, bottomMargin=18 * mm,
        title=title, author="Филипюк Илья Андреевич",
    )
    story = [Paragraph(html.escape(title), title_style)]
    for paragraph in text.split("\n\n"):
        story.append(Paragraph(html.escape(paragraph), body_style))
        story.append(Spacer(1, 1.5 * mm))
    doc.build(story)


def extract_pdf_text(path: Path) -> str:
    with pdfplumber.open(path) as pdf:
        return "\n".join(page.extract_text(x_tolerance=1, y_tolerance=3) or "" for page in pdf.pages)


def render_pdf(path: Path, target_prefix: Path) -> list[Path]:
    target_prefix.parent.mkdir(parents=True, exist_ok=True)
    for old in target_prefix.parent.glob(target_prefix.name + "-*.png"):
        old.unlink()
    command = ["pdftoppm", "-r", "110", "-png", str(path), str(target_prefix)]
    subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return sorted(target_prefix.parent.glob(target_prefix.name + "-*.png"))


def image_difference_ppm(clean_pages: list[Path], stego_pages: list[Path]) -> float:
    total_pixels = 0
    changed_pixels = 0
    for clean_path, stego_path in zip(clean_pages, stego_pages):
        with Image.open(clean_path).convert("RGB") as a, Image.open(stego_path).convert("RGB") as b:
            width = min(a.width, b.width)
            height = min(a.height, b.height)
            a = a.crop((0, 0, width, height))
            b = b.crop((0, 0, width, height))
            changed_pixels += int(np.any(np.asarray(a) != np.asarray(b), axis=2).sum())
            total_pixels += width * height
    if len(clean_pages) != len(stego_pages):
        changed_pixels += abs(len(clean_pages) - len(stego_pages)) * 1_000_000
        total_pixels += abs(len(clean_pages) - len(stego_pages)) * 1_000_000
    return 1_000_000 * changed_pixels / max(total_pixels, 1)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    names = [
        "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for name in names:
        if Path(name).exists():
            return ImageFont.truetype(name, size)
    return ImageFont.load_default()


def draw_grouped_chart(path: Path, title: str, labels: list[str], series: dict[str, list[float]],
                       y_max: float, y_label: str, value_fmt: str = "{:.0f}") -> None:
    width, height = 1500, 880
    img = Image.new("RGB", (width, height), "white")
    d = ImageDraw.Draw(img)
    title_font = font(40, True)
    label_font = font(25)
    small_font = font(22)
    d.text((width // 2, 28), title, fill="#111111", font=title_font, anchor="ma")
    left, top, right, bottom = 150, 130, width - 70, height - 145
    d.line((left, top, left, bottom), fill="#333333", width=3)
    d.line((left, bottom, right, bottom), fill="#333333", width=3)
    for tick in range(0, 6):
        value = y_max * tick / 5
        y = bottom - (bottom - top) * tick / 5
        d.line((left, y, right, y), fill="#dddddd", width=2)
        d.text((left - 18, y), value_fmt.format(value), fill="#333333", font=small_font, anchor="rm")
    colors = ["#2f5597", "#c65911", "#548235", "#8064a2"]
    group_width = (right - left) / len(labels)
    bar_width = group_width / (len(series) + 1)
    for s_idx, (name, values) in enumerate(series.items()):
        color = colors[s_idx % len(colors)]
        for i, value in enumerate(values):
            x0 = left + i * group_width + (s_idx + 0.5) * bar_width
            x1 = x0 + bar_width * 0.82
            y = bottom - (bottom - top) * min(value, y_max) / y_max
            d.rectangle((x0, y, x1, bottom), fill=color)
            d.text(((x0 + x1) / 2, y - 8), value_fmt.format(value), fill="#222222", font=small_font, anchor="ms")
        legend_x = left + s_idx * 300
        d.rectangle((legend_x, height - 65, legend_x + 34, height - 31), fill=color)
        d.text((legend_x + 46, height - 48), name, fill="#222222", font=label_font, anchor="lm")
    for i, label in enumerate(labels):
        x = left + (i + 0.5) * group_width
        d.text((x, bottom + 22), label, fill="#222222", font=label_font, anchor="ma")
    bbox = d.textbbox((0, 0), y_label, font=small_font)
    label_layer = Image.new("RGBA", (bbox[2] - bbox[0] + 20, bbox[3] - bbox[1] + 20), (255, 255, 255, 0))
    label_draw = ImageDraw.Draw(label_layer)
    label_draw.text((10, 10), y_label, fill="#333333", font=small_font)
    label_layer = label_layer.rotate(90, expand=True)
    img.paste(label_layer, (18, int((top + bottom - label_layer.height) / 2)), label_layer)
    img.save(path, dpi=(180, 180))


def write_charts(rows: list[dict[str, object]]) -> None:
    methods = ["space", "zero_width"]
    method_labels = {"space": "Замена пробелов", "zero_width": "Невидимые символы"}
    aggregate: dict[str, dict[str, float]] = {}
    for method in methods:
        subset = [r for r in rows if r["method"] == method]
        aggregate[method] = {
            "html_source": 100 * sum(int(r["html_source_success"]) for r in subset) / len(subset),
            "html_text": 100 * sum(int(r["html_text_success"]) for r in subset) / len(subset),
            "pdf": 100 * sum(int(r["pdf_success"]) for r in subset) / len(subset),
            "ws": 100 * sum(int(r["whitespace_normalization_success"]) for r in subset) / len(subset),
            "cf": 100 * sum(int(r["cf_stripping_success"]) for r in subset) / len(subset),
            "ppm": sum(float(r["visual_difference_ppm"]) for r in subset) / len(subset),
            "capacity": sum(float(r["capacity_per_1000_chars"]) for r in subset) / len(subset),
        }
    labels = [method_labels[m] for m in methods]
    draw_grouped_chart(
        CHART_DIR / "channel_survival.png", "Сохранность сообщения при передаче",
        labels,
        {
            "HTML исходник": [aggregate[m]["html_source"] for m in methods],
            "HTML текст": [aggregate[m]["html_text"] for m in methods],
            "PDF извлечение": [aggregate[m]["pdf"] for m in methods],
        },
        100, "Успешное извлечение, %",
    )
    draw_grouped_chart(
        CHART_DIR / "sanitization_survival.png", "Стойкость к очистке текста",
        labels,
        {
            "Нормализация пробелов": [aggregate[m]["ws"] for m in methods],
            "Удаление Cf": [aggregate[m]["cf"] for m in methods],
        },
        100, "Успешное извлечение, %",
    )
    max_capacity = max(aggregate[m]["capacity"] for m in methods) * 1.15
    draw_grouped_chart(
        CHART_DIR / "capacity.png", "Доступная ёмкость контейнера",
        labels,
        {"Позиции": [aggregate[m]["capacity"] for m in methods]},
        max_capacity, "Позиций на 1000 видимых символов",
    )
    max_ppm = max(aggregate[m]["ppm"] for m in methods)
    draw_grouped_chart(
        CHART_DIR / "visual_difference.png", "Пиксельное отличие PDF от оригинала",
        labels,
        {"Изменённые пиксели": [aggregate[m]["ppm"] for m in methods]},
        max(1.0, max_ppm * 1.2), "Изменённых пикселей на миллион", "{:.1f}",
    )


def main() -> None:
    for directory in [HTML_DIR, PDF_DIR, RENDER_DIR, CHART_DIR, RESULT_DIR]:
        directory.mkdir(parents=True, exist_ok=True)
    font_name = register_font()
    messages = {
        "short": b"S" * 8,
        "medium": b"M" * 32,
        "long": b"L" * 96,
    }
    covers = {language: make_cover(language) for language in ["en", "ru"]}
    clean_pdf_renders: dict[str, list[Path]] = {}
    for language, cover in covers.items():
        common_title = f"Experimental carrier {language.upper()}"
        clean_html = html_document(cover, common_title)
        (HTML_DIR / f"clean_{language}.html").write_text(clean_html, encoding="utf-8")
        clean_pdf = PDF_DIR / f"clean_{language}.pdf"
        write_pdf(clean_pdf, cover, common_title, font_name)
        clean_pdf_renders[language] = render_pdf(clean_pdf, RENDER_DIR / f"clean_{language}")

    rows: list[dict[str, object]] = []
    for method in ["space", "zero_width"]:
        for language in ["en", "ru"]:
            cover = covers[language]
            visible_chars = sum(1 for ch in cover if not ch.isspace())
            for length_name, message in messages.items():
                stego = embed(cover, message, method)
                stem = f"{method}_{language}_{length_name}"
                title = f"Experimental carrier {language.upper()}"
                html_source = html_document(stego, title)
                html_path = HTML_DIR / f"{stem}.html"
                html_path.write_text(html_source, encoding="utf-8")
                pdf_path = PDF_DIR / f"{stem}.pdf"
                write_pdf(pdf_path, stego, title, font_name)

                extracted_html = html_visible_text(html_source)
                extracted_pdf = extract_pdf_text(pdf_path)
                stego_render = render_pdf(pdf_path, RENDER_DIR / stem)
                ppm = image_difference_ppm(clean_pdf_renders[language], stego_render)
                marker_count = sum(stego.count(ch) for ch in [SPACE_ONE, ZW_ZERO, ZW_ONE])
                payload = len(payload_bits(message))
                cap = capacity(cover, method)
                row: dict[str, object] = {
                    "method": method,
                    "language": language,
                    "message_length": length_name,
                    "message_bytes": len(message),
                    "payload_bits_with_header": payload,
                    "cover_visible_chars": visible_chars,
                    "capacity_bits": cap,
                    "capacity_per_1000_chars": round(1000 * cap / visible_chars, 2),
                    "utilization_percent": round(100 * payload / cap, 2),
                    "added_utf8_bytes": len(stego.encode("utf-8")) - len(cover.encode("utf-8")),
                    "marker_count": marker_count,
                    "raw_success": int(extract(stego, method) == message),
                    "html_source_success": int(extract(extracted_html, method) == message),
                    "html_text_success": int(extract(re.sub(r"[ \t\r\f]+", " ", extracted_html), method) == message),
                    "pdf_success": int(extract(extracted_pdf, method) == message),
                    "whitespace_normalization_success": int(extract(normalize_whitespace(stego), method) == message),
                    "cf_stripping_success": int(extract(strip_format_chars(stego), method) == message),
                    "simple_detector_flag": int(marker_count > 0),
                    "visual_difference_ppm": round(ppm, 3),
                    "stego_sha256": hashlib.sha256(stego.encode("utf-8")).hexdigest(),
                }
                rows.append(row)

    csv_path = RESULT_DIR / "experiment_results.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    write_charts(rows)

    summary_path = RESULT_DIR / "summary.txt"
    with summary_path.open("w", encoding="utf-8") as fh:
        fh.write(f"Cases: {len(rows)}\n")
        for method in ["space", "zero_width"]:
            subset = [r for r in rows if r["method"] == method]
            fh.write(f"\n{method}\n")
            for key in [
                "raw_success", "html_source_success", "html_text_success", "pdf_success",
                "whitespace_normalization_success", "cf_stripping_success", "simple_detector_flag",
            ]:
                fh.write(f"{key}: {sum(int(r[key]) for r in subset)}/{len(subset)}\n")
            avg_ppm = sum(float(r["visual_difference_ppm"]) for r in subset) / len(subset)
            avg_capacity = sum(float(r["capacity_per_1000_chars"]) for r in subset) / len(subset)
            fh.write(f"mean_visual_difference_ppm: {avg_ppm:.3f}\n")
            fh.write(f"mean_capacity_per_1000_chars: {avg_capacity:.2f}\n")
    print(f"Generated {len(rows)} cases in {OUT}")


if __name__ == "__main__":
    main()

