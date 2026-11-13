from __future__ import annotations

import re
import sys
import unicodedata
from pathlib import Path

LAB5_ROOT = Path(__file__).resolve().parents[1]
LAB4_SRC = LAB5_ROOT.parent / "lab4" / "src"
sys.path.insert(0, str(LAB4_SRC))

import csv  # noqa: E402
from run_lab4 import BASE_TEXTS, MESSAGES, make_cover  # noqa: E402
from stego_methods import (  # noqa: E402
    NBSP,
    ZERO_WIDTH_ONE,
    ZERO_WIDTH_ZERO,
    SteganographyError,
    embed_space,
    embed_zero_width,
    extract_space,
    extract_zero_width,
)

RESULTS_ROOT = LAB5_ROOT / "results"

METHODS = {
    "space": (embed_space, extract_space),
    "zero_width": (embed_zero_width, extract_zero_width),
}


def transform_identity(text: str) -> str:
    return text


def transform_utf8_bytes(text: str) -> str:
    return text.encode("utf-8").decode("utf-8")


def transform_nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text)


def transform_copy_paste(text: str) -> str:
    # Имитация редактора, который приводит неразрывные пробелы к обычным,
    # но не трогает символы нулевой ширины.
    return text.replace(NBSP, " ")


TRANSFORMATIONS = {
    "identity": transform_identity,
    "utf8_roundtrip": transform_utf8_bytes,
    "nfc_normalize": transform_nfc,
    "copy_paste": transform_copy_paste,
}


def run_scenario(method: str, language: str, text_format: str, size: str, message: str, transform_name: str) -> dict[str, object]:
    embed, extract = METHODS[method]
    transform = TRANSFORMATIONS[transform_name]
    cover = make_cover(language, text_format)
    stego_text = embed(cover, message)
    transformed = transform(stego_text)

    row: dict[str, object] = {
        "method": method,
        "language": language,
        "format": text_format,
        "message_size": size,
        "transformation": transform_name,
        "extraction_success": False,
        "markers_before": stego_text.count(NBSP) + stego_text.count(ZERO_WIDTH_ZERO) + stego_text.count(ZERO_WIDTH_ONE),
        "markers_after": transformed.count(NBSP) + transformed.count(ZERO_WIDTH_ZERO) + transformed.count(ZERO_WIDTH_ONE),
        "error": "",
    }

    try:
        row["extraction_success"] = extract(transformed) == message
    except SteganographyError as error:
        row["error"] = str(error)
    return row


def main() -> None:
    RESULTS_ROOT.mkdir(parents=True, exist_ok=True)
    rows = [
        run_scenario(method, language, text_format, size, message, transform_name)
        for method in METHODS
        for language in BASE_TEXTS
        for text_format in ("txt", "html")
        for size, message in MESSAGES.items()
        for transform_name in TRANSFORMATIONS
    ]

    result_path = RESULTS_ROOT / "universality.csv"
    with result_path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    print(f"Экспериментов по универсальности: {len(rows)}.")
    print(f"Результаты сохранены в {result_path}")


if __name__ == "__main__":
    main()
