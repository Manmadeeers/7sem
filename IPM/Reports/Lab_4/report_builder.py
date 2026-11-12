#!/usr/bin/env python3
"""Build the final DOCX report from the previous lab's visual template."""

from __future__ import annotations

import csv
import hashlib
from collections import defaultdict
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_ALIGN_VERTICAL, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parent
REFERENCE = ROOT.parent / "Lab_3.docx"
OUTPUT = ROOT / "Отчёт_ЛР4.docx"
CSV_PATH = ROOT / "output" / "results" / "experiment_results.csv"
CHARTS = ROOT / "output" / "charts"

EXPECTED_REFERENCE_SHA256 = "a939d51a896cbae0b9c6826d50e96ad46a44976f8cca2b455694c6330d67a7a4"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def clear_body(doc: Document) -> None:
    body = doc._element.body
    for child in list(body):
        if child.tag != qn("w:sectPr"):
            body.remove(child)


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, start=100, bottom=80, end=100) -> None:
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for margin, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{margin}"))
        if node is None:
            node = OxmlElement(f"w:{margin}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_table_borders(table, color="D9D9D9", size="8") -> None:
    tbl_pr = table._tbl.tblPr
    borders = tbl_pr.first_child_found_in("w:tblBorders")
    if borders is None:
        borders = OxmlElement("w:tblBorders")
        tbl_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = f"w:{edge}"
        element = borders.find(qn(tag))
        if element is None:
            element = OxmlElement(tag)
            borders.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), size)
        element.set(qn("w:space"), "0")
        element.set(qn("w:color"), color)


def repeat_table_header(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def prevent_row_split(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = OxmlElement("w:cantSplit")
    cant_split.set(qn("w:val"), "true")
    tr_pr.append(cant_split)


def keep_with_next(paragraph, value=True) -> None:
    paragraph.paragraph_format.keep_with_next = value


def configure_styles(doc: Document) -> None:
    styles = doc.styles
    normal = styles.get_by_id("891", WD_STYLE_TYPE.PARAGRAPH)
    normal.font.name = "Times New Roman"
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    normal.font.size = Pt(14)
    normal.font.color.rgb = RGBColor(0, 0, 0)
    normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    normal.paragraph_format.first_line_indent = Cm(1.25)
    normal.paragraph_format.space_after = Pt(4)
    normal.paragraph_format.line_spacing = 1.15

    title = styles.get_by_id("912", WD_STYLE_TYPE.PARAGRAPH)
    title.font.name = "Times New Roman"
    title._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    title.font.size = Pt(24)
    title.font.bold = True
    title.font.color.rgb = RGBColor(0, 0, 0)
    title.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER

    for style_id, size in (("896", 16), ("897", 14)):
        style = styles.get_by_id(style_id, WD_STYLE_TYPE.PARAGRAPH)
        style.font.name = "Times New Roman"
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = RGBColor(0, 0, 0)
        style.paragraph_format.space_before = Pt(10)
        style.paragraph_format.space_after = Pt(5)
        style.paragraph_format.keep_with_next = True
        style.paragraph_format.first_line_indent = Cm(0)

    caption = styles.get_by_id("945", WD_STYLE_TYPE.PARAGRAPH)
    caption.font.name = "Times New Roman"
    caption._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    caption.font.size = Pt(12)
    caption.font.italic = False
    caption.font.color.rgb = RGBColor(0, 0, 0)
    caption.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    caption.paragraph_format.first_line_indent = Cm(0)
    caption.paragraph_format.space_before = Pt(3)
    caption.paragraph_format.space_after = Pt(8)


def add_text(doc: Document, text: str, *, bold_lead: str | None = None) -> None:
    p = doc.add_paragraph()
    if bold_lead and text.startswith(bold_lead):
        p.add_run(bold_lead).bold = True
        p.add_run(text[len(bold_lead):])
    else:
        p.add_run(text)


def add_bullets(doc: Document, items: list[str]) -> None:
    for item in items:
        p = doc.add_paragraph()
        p.style = doc.styles.get_by_id("926", WD_STYLE_TYPE.PARAGRAPH)
        p.paragraph_format.left_indent = Cm(0.7)
        p.paragraph_format.first_line_indent = Cm(-0.35)
        p.paragraph_format.space_after = Pt(2)
        p.add_run(item)


def add_numbered(doc: Document, items: list[str]) -> None:
    for item in items:
        p = doc.add_paragraph()
        p.style = doc.styles.get_by_id("929", WD_STYLE_TYPE.PARAGRAPH)
        p.paragraph_format.left_indent = Cm(0.7)
        p.paragraph_format.first_line_indent = Cm(-0.35)
        p.paragraph_format.space_after = Pt(2)
        p.add_run(item)


def add_table(doc: Document, headers: list[str], rows: list[list[str]], widths: list[float] | None = None,
              font_size: float = 9.5) -> None:
    table = doc.add_table(rows=1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    set_table_borders(table)
    header = table.rows[0]
    repeat_table_header(header)
    for index, text in enumerate(headers):
        cell = header.cells[index]
        set_cell_shading(cell, "1F4E78")
        set_cell_margins(cell, 100, 110, 100, 110)
        cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(text)
        run.bold = True
        run.font.color.rgb = RGBColor(255, 255, 255)
        run.font.name = "Times New Roman"
        run.font.size = Pt(font_size)
    for row_index, values in enumerate(rows):
        row = table.add_row()
        for col_index, text in enumerate(values):
            cell = row.cells[col_index]
            if row_index % 2:
                set_cell_shading(cell, "EAF1F8")
            set_cell_margins(cell, 95, 110, 95, 110)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.first_line_indent = Cm(0)
            p.paragraph_format.space_after = Pt(0)
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if len(text) < 22 else WD_ALIGN_PARAGRAPH.LEFT
            run = p.add_run(text)
            run.font.name = "Times New Roman"
            run.font.size = Pt(font_size)
        prevent_row_split(row)
    if widths:
        for row in table.rows:
            for index, width in enumerate(widths):
                row.cells[index].width = Inches(width)
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(2)


def add_figure(doc: Document, image_path: Path, caption: str, width=Inches(6.15)) -> None:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.keep_with_next = True
    p.add_run().add_picture(str(image_path), width=width)
    cap = doc.add_paragraph(caption)
    cap.style = doc.styles.get_by_id("945", WD_STYLE_TYPE.PARAGRAPH)
    cap.paragraph_format.keep_with_next = False


def add_heading(doc: Document, text: str, level: int = 1):
    p = doc.add_paragraph(text)
    p.style = doc.styles.get_by_id("896" if level == 1 else "897", WD_STYLE_TYPE.PARAGRAPH)
    return p


def title_page(doc: Document) -> None:
    def center(text="", size=14, bold=False, after=0):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.space_after = Pt(after)
        r = p.add_run(text)
        r.font.name = "Times New Roman"
        r.font.size = Pt(size)
        r.bold = bold
        return p

    center("Белорусский Государственный Технологический Университет", 14, False, 3)
    center("Кафедра Информационных Систем и Технологий", 14)
    for _ in range(5):
        center()
    center("Отчёт", 24, True, 8)
    report_title = center("Сравнительный анализ методов текстовой стеганографии", 19, True, 4)
    report_title.style = doc.styles.get_by_id("912", WD_STYLE_TYPE.PARAGRAPH)
    center("Замена пробелов и невидимые символы Unicode", 16, True)
    for _ in range(4):
        center()
    center("Тема курсового проекта", 14, True, 5)
    center("Велотрекер с построением маршрутов", 14)
    for _ in range(5):
        center()
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.left_indent = Cm(9)
    p.paragraph_format.first_line_indent = Cm(0)
    p.add_run("Выполнил студент 4 курса 6 группы").font.size = Pt(14)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.left_indent = Cm(9)
    p.paragraph_format.first_line_indent = Cm(0)
    p.add_run("Филипюк Илья Андреевич").font.size = Pt(14)
    for _ in range(3):
        center()
    center("Минск 2026", 14)
    doc.add_page_break()


def load_results() -> list[dict[str, str]]:
    with CSV_PATH.open(encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def percent(rows: list[dict[str, str]], key: str) -> int:
    return round(100 * sum(int(row[key]) for row in rows) / len(rows))


def avg(rows: list[dict[str, str]], key: str) -> float:
    return sum(float(row[key]) for row in rows) / len(rows)


def build() -> None:
    if sha256(REFERENCE) != EXPECTED_REFERENCE_SHA256:
        raise RuntimeError("Reference document changed; template must be distilled again")
    rows = load_results()
    by_method = {method: [r for r in rows if r["method"] == method] for method in ("space", "zero_width")}

    doc = Document(str(REFERENCE))
    clear_body(doc)
    configure_styles(doc)
    section = doc.sections[0]
    section.different_first_page_header_footer = True
    if section.header.paragraphs:
        hp = section.header.paragraphs[0]
        hp.text = "Сравнительный анализ методов текстовой стеганографии"
        hp.alignment = WD_ALIGN_PARAGRAPH.LEFT
        for run in hp.runs:
            run.font.name = "Times New Roman"
            run.font.size = Pt(11)
            run.font.bold = True
    title_page(doc)

    add_heading(doc, "1 Цель работы", level=1)
    add_text(doc, "Сравнить метод замены пробелов и метод невидимых символов Unicode по заметности, влиянию на исходный текст, стойкости к обнаружению и сохранности после преобразования формата. Практическая часть должна определить, какой метод уместен для HTML и PDF, как на результат влияют язык контейнера и длина сообщения, а также какие ограничения делают скрытый канал ненадёжным.")
    add_text(doc, "Главный результат эксперимента: zero-width метод визуально точнее и обладает большей ёмкостью, но оба метода легко обнаруживаются по кодовым точкам. Замена пробелов оказалась особенно чувствительной к PDF и нормализации пробелов. Невидимые символы лучше пережили выбранный PDF-конвейер, однако длинные сообщения в PDF восстановить не удалось.")

    add_heading(doc, "2 Условие задания", level=1)
    add_text(doc, "Необходимо провести теоретический и практический анализ двух способов текстовой стеганографии: Space Steganography и Zero-Width Characters Steganography. Сравнение выполняется для английских и русских контейнеров, коротких, средних и длинных сообщений, а результаты представляются в HTML и PDF.")
    add_table(doc, ["Фактор", "Значения"], [
        ["Метод", "Замена U+0020 на U+00A0; вставка U+200B и U+200C"],
        ["Язык контейнера", "Английский и русский"],
        ["Длина сообщения", "8, 32 и 96 байт"],
        ["Формат", "HTML и PDF"],
        ["Проверки", "Прямое извлечение, HTML-текст, PDF-текст, нормализация пробелов, удаление Cf"],
    ], [1.45, 5.0], 10.5)

    add_heading(doc, "3 Теоретические основы", level=1)
    add_heading(doc, "3.1 Стеганография заменой пробелов", level=2)
    add_text(doc, "В выбранной реализации бит 0 задаётся обычным пробелом U+0020, а бит 1 — неразрывным пробелом U+00A0. Перед полезной нагрузкой записывается 32-битная длина сообщения. Кодирование не меняет слова и знаки препинания, но изменяет свойства переноса строк: U+00A0 запрещает обычный разрыв между соседними словами. Поэтому метод может стать заметным при выравнивании текста или узкой колонке.")
    add_text(doc, "Классические whitespace-схемы также используют пробелы и табуляции в конце строк. Например, программа SNOW скрывает данные в последовательностях конечных пробелов и табуляций. В этой работе использована замена внутренних пробелов, потому что она применима к сплошному HTML-тексту и позволяет непосредственно сравнить Unicode-маркеры обоих методов.")

    add_heading(doc, "3.2 Стеганография невидимыми символами", level=2)
    add_text(doc, "Второй метод вставляет после видимых символов U+200B ZERO WIDTH SPACE для бита 0 и U+200C ZERO WIDTH NON-JOINER для бита 1. U+200B не имеет собственной ширины, но обозначает возможность переноса; U+200C управляет соединением и лигатурами. Для латиницы и кириллицы при обычном наборе они чаще всего не дают видимого глифа, однако остаются в строке как отдельные кодовые точки категории Cf.")
    add_text(doc, "Нулевая ширина не гарантирует одинаковый результат во всех движках. Алгоритм переноса, шрифт, очистка Unicode и копирование через промежуточный формат могут удалить символы или изменить их порядок. В письменностях, где ZWNJ имеет языковое значение, произвольная вставка может менять форму слова, поэтому такой алфавит нельзя считать универсальным.")

    add_heading(doc, "3.3 Сравнение принципов", level=2)
    add_table(doc, ["Характеристика", "Замена пробелов", "Невидимые символы"], [
        ["Позиции для встраивания", "Только обычные пробелы", "Почти каждый видимый символ"],
        ["Визуальный риск", "Изменение переноса строк", "Обычно отсутствует; возможны особенности лигатур и переноса"],
        ["Простой детектор", "Подсчёт U+00A0", "Поиск U+200B и U+200C или категории Cf"],
        ["Типичная очистка", "Унификация всех пробелов", "Удаление форматирующих символов"],
        ["Основное преимущество", "Простая реализация и понятная модель", "Высокая ёмкость и точное визуальное совпадение"],
    ], [1.55, 2.4, 2.4], 9.2)

    add_heading(doc, "4 Методика эксперимента", level=1)
    add_text(doc, "Для каждого языка сформирован нейтральный текст о велотрекере: 8466 видимых символов в английском контейнере и 8691 в русском. В каждый контейнер последовательно встраивались сообщения из 8, 32 и 96 байт. С учётом 32-битного заголовка требовалось 96, 288 и 800 бит соответственно. Всего выполнено 12 основных случаев; каждый сохранён в HTML и PDF.")
    add_numbered(doc, [
        "Сформировать битовую строку из длины и сообщения.",
        "Встроить биты выбранным методом без изменения видимых букв.",
        "Проверить прямое извлечение и извлечение из HTML-текста.",
        "Создать PDF, извлечь из него текст и повторить декодирование.",
        "Применить нормализацию пробелов и удаление символов Unicode категории Cf.",
        "Отрисовать чистый и стеганографический PDF и подсчитать долю изменившихся пикселей.",
    ])
    add_text(doc, "Для PDF использованы ReportLab, шрифт DejaVu Sans и извлечение через pdfplumber. Пиксельное сравнение выполнено после рендеринга Poppler при 110 dpi. Поэтому результаты характеризуют конкретный воспроизводимый конвейер, а не все существующие редакторы и просмотрщики.")

    add_heading(doc, "5 Результаты эксперимента", level=1)
    space = by_method["space"]
    zero = by_method["zero_width"]
    add_table(doc, ["Метрика", "Замена пробелов", "Невидимые символы"], [
        ["Прямое извлечение", f"{percent(space, 'raw_success')} %", f"{percent(zero, 'raw_success')} %"],
        ["HTML исходник", f"{percent(space, 'html_source_success')} %", f"{percent(zero, 'html_source_success')} %"],
        ["HTML видимый текст", f"{percent(space, 'html_text_success')} %", f"{percent(zero, 'html_text_success')} %"],
        ["PDF извлечение", f"{percent(space, 'pdf_success')} %", f"{percent(zero, 'pdf_success')} %"],
        ["После нормализации пробелов", f"{percent(space, 'whitespace_normalization_success')} %", f"{percent(zero, 'whitespace_normalization_success')} %"],
        ["После удаления Cf", f"{percent(space, 'cf_stripping_success')} %", f"{percent(zero, 'cf_stripping_success')} %"],
        ["Ёмкость на 1000 видимых символов", f"{avg(space, 'capacity_per_1000_chars'):.1f} бита", f"{avg(zero, 'capacity_per_1000_chars'):.1f} бита"],
        ["Изменённых пикселей на миллион", f"{avg(space, 'visual_difference_ppm'):.1f}", f"{avg(zero, 'visual_difference_ppm'):.1f}"],
    ], [2.85, 1.75, 1.75], 9.2)
    add_figure(doc, CHARTS / "channel_survival.png", "Рисунок 1 — Сохранность сообщения при передаче через HTML и PDF")
    add_text(doc, "Оба метода полностью сохранились в HTML. При извлечении текста из PDF метод пробелов дал 0 %, потому что различие U+0020 и U+00A0 не сохранилось в доступной декодеру форме. Невидимые символы дали 67 %: короткие и средние сообщения восстановились для обоих языков, а длинные — нет.")
    add_figure(doc, CHARTS / "sanitization_survival.png", "Рисунок 2 — Стойкость к двум видам очистки текста")
    add_text(doc, "Атаки оказались взаимно дополнительными. Нормализация пробелов полностью уничтожила канал замены пробелов, но не затронула U+200B и U+200C. Удаление символов категории Cf уничтожило zero-width канал, сохранив U+00A0. Следовательно, ни один метод не выдерживает целевую очистку, если защитник знает тип алфавита.")
    add_figure(doc, CHARTS / "capacity.png", "Рисунок 3 — Доступная ёмкость контейнера")
    add_text(doc, "Zero-width вариант предоставил в среднем 1000 позиций на 1000 видимых символов. Замена пробелов дала 150,6 позиции, то есть примерно в 6,6 раза меньше. Различие между английским и русским контейнерами связано с частотой пробелов: 168,3 позиции на 1000 видимых символов для английского текста и 132,9 для русского.")
    add_figure(doc, CHARTS / "visual_difference.png", "Рисунок 4 — Пиксельное отличие PDF от чистого контейнера")
    add_text(doc, "Zero-width PDF совпал с чистым контейнером на уровне пикселей во всех 6 случаях. Для метода пробелов среднее отличие составило 91 555 пикселей на миллион, то есть около 9,16 %. Причина — запрет переносов в позициях U+00A0 и последующее перераспределение строк. На русском тексте влияние было сильнее из-за иного распределения длины слов и меньшей частоты пробелов.")

    add_heading(doc, "5.1 Влияние длины сообщения", level=2)
    length_labels = {"short": "Короткое, 8 байт", "medium": "Среднее, 32 байта", "long": "Длинное, 96 байт"}
    length_rows = []
    for method, method_name in (("space", "Замена пробелов"), ("zero_width", "Невидимые символы")):
        for length_name in ("short", "medium", "long"):
            subset = [r for r in rows if r["method"] == method and r["message_length"] == length_name]
            length_rows.append([
                method_name,
                length_labels[length_name],
                f"{percent(subset, 'pdf_success')} %",
                f"{avg(subset, 'visual_difference_ppm'):.1f}",
                f"{avg(subset, 'utilization_percent'):.1f} %",
            ])
    add_table(doc, ["Метод", "Сообщение", "PDF", "Пикселей на млн", "Заполнение"], length_rows,
              [1.55, 1.6, 0.7, 1.3, 1.0], 8.8)
    add_text(doc, "Для zero-width метода рост длины не изменил изображение, но снизил надёжность PDF: при 96 байтах результат составил 0 %. У замены пробелов визуальное отклонение возрастало вместе с числом U+00A0. Это означает, что длинная полезная нагрузка одновременно повышает заметность и увеличивает вероятность потери.")

    add_heading(doc, "5.2 Влияние языка", level=2)
    add_text(doc, "Язык не повлиял на прямое извлечение и результаты атак очистки. Различия проявились в доступной ёмкости и компоновке PDF. Английский контейнер содержал больше пробелов относительно числа видимых символов, поэтому метод пробелов имел большую ёмкость. Zero-width метод использовал позиции после букв и знаков и потому дал одинаковое нормированное значение для обоих языков.")

    add_heading(doc, "6 Анализ заметности, качества и безопасности", level=1)
    add_heading(doc, "6.1 Степень заметности", level=2)
    add_text(doc, "Для человека zero-width метод оказался незаметнее: рендер PDF не изменился. Замена пробелов заметна косвенно по переносу строк, особенно при средней и длинной нагрузке. Для автоматического анализатора оба метода очевидны. Проверка на U+00A0, U+200B и U+200C пометила 100 % стеганографических контейнеров.")

    add_heading(doc, "6.2 Качество исходного текста", level=2)
    add_text(doc, "Семантика слов не менялась ни в одном методе. Однако качество документа включает и вёрстку. U+00A0 объединяет соседние слова в неразрывные фрагменты, поэтому строка может стать неравномерной. U+200B и U+200C в выбранных латинских и кириллических текстах не дали видимых отличий, но способны влиять на перенос и лигатуры в других движках и письменностях.")

    add_heading(doc, "6.3 Безопасность", level=2)
    add_text(doc, "Оба метода обеспечивают только сокрытие факта передачи и не заменяют шифрование. Частота нестандартных кодовых точек, позиционная регулярность и длина скрытой последовательности дают простые признаки обнаружения. Целевой фильтр удаляет канал за один проход. Без шифрования извлечённая нагрузка читается, а без кода аутентификации её можно незаметно изменить.")
    add_table(doc, ["Угроза", "Замена пробелов", "Невидимые символы", "Мера снижения риска"], [
        ["Unicode-сканер", "Легко находит U+00A0", "Легко находит U+200B/U+200C", "Шифровать нагрузку; уменьшать и рандомизировать число маркеров"],
        ["Нормализация", "Канал уничтожается", "Обычно сохраняется", "Выбирать профиль под известный канал передачи"],
        ["Удаление Cf", "Сохраняется", "Канал уничтожается", "Резервное кодирование или иной алфавит"],
        ["PDF-конвертация", "В опыте 0 %", "В опыте 67 %", "Тестировать конкретный редактор и извлекатель"],
        ["Повреждение одного бита", "Сдвиг или ошибка длины", "Сдвиг или ошибка длины", "Синхромаркеры, CRC и помехоустойчивый код"],
    ], [1.15, 1.45, 1.45, 2.35], 8.4)

    add_heading(doc, "7 Сильные и слабые стороны", level=1)
    add_table(doc, ["Метод", "Сильные стороны", "Слабые стороны"], [
        ["Замена пробелов", "Простая реализация; понятное извлечение; сохраняется при удалении Cf", "Низкая ёмкость; заметное влияние на перенос; полная потеря после нормализации и в выбранном PDF-конвейере"],
        ["Невидимые символы", "Высокая ёмкость; нулевое пиксельное отличие; устойчивость к нормализации пробелов", "Легко обнаружить и удалить; длинное сообщение потерялось в PDF; возможное влияние на лигатуры и языковую норму"],
    ], [1.35, 2.55, 2.55], 9.2)

    add_heading(doc, "8 Области применения и рекомендации", level=1)
    add_table(doc, ["Сценарий", "Предпочтительный вариант", "Обоснование"], [
        ["Контролируемый HTML-канал", "Невидимые символы", "Оба метода дали 100 %, но zero-width имеет большую ёмкость и не изменил изображение"],
        ["Документ с жёсткой вёрсткой", "Невидимые символы после проверки", "U+00A0 меняет перенос; zero-width нужно проверить в конкретном движке"],
        ["Канал с удалением Cf", "Замена пробелов", "Zero-width данные будут удалены; пробельный метод сохранится, если не нормализуются пробелы"],
        ["Канал с нормализацией пробелов", "Невидимые символы", "Метод пробелов в опыте потерял сообщение полностью"],
        ["Неизвестные редакторы и PDF", "Не использовать без предварительного теста", "Результат зависит от конвертера; ни один метод не дал полной надёжности"],
        ["Конфиденциальная передача", "Шифрование плюс проверенный канал", "Стеганография без криптографии не защищает содержание"],
    ], [1.55, 1.75, 3.15], 8.8)
    add_text(doc, "Практический выбор следует начинать не с визуальной незаметности, а с известного пути документа. Если канал контролируется и остаётся HTML, zero-width метод предпочтительнее. Если текст проходит нормализаторы, мессенджеры, офисные редакторы или PDF-конвертеры, необходимо выполнить сквозной тест на том же программном стеке. Для критичных данных скрытый канал следует считать дополнительным слоем, а не основной защитой.")

    add_heading(doc, "9 Направления развития", level=1)
    add_bullets(doc, [
        "Шифровать и сжимать полезную нагрузку перед встраиванием, чтобы убрать читаемую структуру и сократить число маркеров.",
        "Добавить CRC, код исправления ошибок и периодические синхромаркеры для восстановления после частичной потери символов.",
        "Выбирать позиции псевдослучайно по ключу, а не заполнять контейнер с начала, чтобы снизить регулярность распределения.",
        "Создать профили совместимости для браузеров, офисных редакторов, мессенджеров и PDF-конвертеров.",
        "Использовать адаптивный алфавит с учётом языка: не вставлять ZWNJ там, где он меняет соединение букв, и избегать U+00A0 около вероятных переносов.",
        "Оценивать заметность автоматическим детектором и визуальным рендерингом одновременно; одна метрика не отражает весь риск.",
    ])

    add_heading(doc, "10 Выводы", level=1)
    add_text(doc, "Практический эксперимент подтвердил, что zero-width метод эффективнее по ёмкости и визуальному качеству. Он предоставил примерно в 6,6 раза больше позиций и не изменил пиксельный рендер PDF. В HTML оба метода обеспечили полное восстановление сообщений любой исследованной длины.")
    add_text(doc, "Преимущество zero-width метода не означает универсальной стойкости. В PDF восстановились только 4 из 6 сообщений, а удаление символов Cf уничтожило канал полностью. Метод замены пробелов не пережил ни нормализацию пробелов, ни извлечение из PDF и заметно изменил перенос строк.")
    add_text(doc, "Для контролируемого HTML-канала рекомендуется zero-width вариант с шифрованием, проверкой целостности и умеренной нагрузкой. Метод пробелов оправдан только там, где гарантированно сохраняются типы пробелов и не выполняется повторная вёрстка. В неизвестном канале требуется предварительное сквозное тестирование; для конфиденциальных данных оба метода должны дополнять, а не заменять криптографическую защиту.")

    add_heading(doc, "11 Использованные источники", level=1)
    sources = [
        "1. Unicode Consortium. The Unicode Standard, Version 18.0, Chapter 23 Special Areas and Format Characters. Сведения о U+00A0, U+200B и U+200C. https://www.unicode.org/versions/Unicode18.0.0/core-spec/chapter-23/",
        "2. WHATWG. HTML Living Standard. Правила обработки текста и пробельных символов в HTML. https://html.spec.whatwg.org/",
        "3. Kwan M. SNOW whitespace steganography program, version 1.1. Описание скрытия данных конечными пробелами и табуляциями. https://github.com/mattkwan-zz/snow/blob/master/snow.1",
        "4. Исходный код и результаты эксперимента в каталоге Lab_4: experiment.py и output/results/experiment_results.csv. Дата выполнения 11.11.2026.",
    ]
    for source in sources:
        p = doc.add_paragraph(source)
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.left_indent = Cm(0)
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.space_after = Pt(5)

    add_heading(doc, "Приложение А Состав материалов", level=1)
    add_text(doc, "Скрипт experiment.py воспроизводит встраивание, извлечение, атаки, создание HTML/PDF и расчёт метрик. Таблица experiment_results.csv содержит 12 строк с параметрами каждого случая. Каталоги output/samples/html и output/samples/pdf содержат контейнеры, а output/charts — четыре графика, включённые в отчёт.")

    doc.core_properties.title = "Сравнительный анализ методов текстовой стеганографии"
    doc.core_properties.subject = "Лабораторная работа 4"
    doc.core_properties.author = "Филипюк Илья Андреевич"
    doc.core_properties.keywords = "стеганография, пробелы, zero-width, HTML, PDF"
    doc.save(str(OUTPUT))
    print(OUTPUT)


if __name__ == "__main__":
    build()
