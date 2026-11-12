from __future__ import annotations

import csv
from pathlib import Path

from stego_methods import (
    SteganographyError,
    embed_space,
    embed_zero_width,
    extract_space,
    extract_zero_width,
    pack_message,
    space_capacity_bits,
    visible_projection,
    zero_width_capacity_bits,
)

LAB_ROOT = Path(__file__).resolve().parents[1]
DATA_ROOT = LAB_ROOT / "data"
ARTIFACTS_ROOT = LAB_ROOT / "artifacts"
RESULTS_ROOT = LAB_ROOT / "results"

METHODS = {
    "space": (embed_space, extract_space, space_capacity_bits),
    "zero_width": (embed_zero_width, extract_zero_width, zero_width_capacity_bits),
}

BASE_TEXTS = {
    "ru": (
        "Информационная безопасность требует внимательного отношения к данным, "
        "способам их хранения и передачи. Учебный эксперимент позволяет проверить, "
        "как свойства текстового контейнера влияют на возможность скрыть сообщение."
    ),
    "en": (
        "Information security requires careful treatment of data, storage methods, "
        "and transmission channels. A classroom experiment shows how a text container "
        "affects the ability to hide a message."
    ),
}

MESSAGES = {
    "short": "Проверка",
    "medium": "Скрытое сообщение для лабораторного эксперимента.",
    "long": "Скрытое сообщение проверяет сохранность текста и возможность извлечения данных. " * 3,
}


def make_cover(language: str, text_format: str) -> str:
    paragraphs = [BASE_TEXTS[language]] * 180
    if text_format == "txt":
        return "\n\n".join(paragraphs)
    return "<html><head><meta charset=\"utf-8\"></head><body>" + "".join(
        f"<p>{paragraph}</p>" for paragraph in paragraphs
    ) + "</body></html>"


def write_input_files() -> None:
    covers_root = DATA_ROOT / "covers"
    messages_root = DATA_ROOT / "messages"
    covers_root.mkdir(parents=True, exist_ok=True)
    messages_root.mkdir(parents=True, exist_ok=True)

    for language in BASE_TEXTS:
        for text_format in ("txt", "html"):
            path = covers_root / f"cover_{language}.{text_format}"
            path.write_text(make_cover(language, text_format), encoding="utf-8")

    for size, message in MESSAGES.items():
        (messages_root / f"message_{size}.txt").write_text(message, encoding="utf-8")


def write_artifact(method: str, language: str, text_format: str, size: str, text: str) -> None:
    extension = "html" if text_format == "html" else "txt"
    path = ARTIFACTS_ROOT / f"{method}_{language}_{size}.{extension}"
    path.write_text(text, encoding="utf-8")


def run_scenario(method: str, language: str, text_format: str, size: str, message: str) -> dict[str, object]:
    embed, extract, capacity = METHODS[method]
    cover = make_cover(language, text_format)
    packed_message = pack_message(message)
    row: dict[str, object] = {
        "method": method,
        "language": language,
        "format": text_format,
        "message_size": size,
        "message_bytes": len(message.encode("utf-8")),
        "payload_bits": len(packed_message) * 8,
        "capacity_bits": capacity(cover),
        "cover_bytes": len(cover.encode("utf-8")),
        "stego_bytes": "",
        "size_delta_bytes": "",
        "embed_success": False,
        "extraction_success": False,
        "visible_projection_equal": False,
        "error": "",
    }

    try:
        stego_text = embed(cover, message)
        extracted_message = extract(stego_text)
        row.update(
            stego_bytes=len(stego_text.encode("utf-8")),
            size_delta_bytes=len(stego_text.encode("utf-8")) - len(cover.encode("utf-8")),
            embed_success=True,
            extraction_success=extracted_message == message,
            visible_projection_equal=visible_projection(stego_text) == cover,
        )
        write_artifact(method, language, text_format, size, stego_text)
    except SteganographyError as error:
        row["error"] = str(error)

    return row


def main() -> None:
    write_input_files()
    ARTIFACTS_ROOT.mkdir(parents=True, exist_ok=True)
    RESULTS_ROOT.mkdir(parents=True, exist_ok=True)
    rows = [
        run_scenario(method, language, text_format, size, message)
        for method in METHODS
        for language in BASE_TEXTS
        for text_format in ("txt", "html")
        for size, message in MESSAGES.items()
    ]

    result_path = RESULTS_ROOT / "lab4_results.csv"
    with result_path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    successful = sum(row["extraction_success"] is True for row in rows)
    print(f"Сценариев: {len(rows)}. Успешных извлечений: {successful}.")
    print(f"Результаты сохранены в {result_path}")


if __name__ == "__main__":
    main()
