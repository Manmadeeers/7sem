from __future__ import annotations

import csv
import platform
import statistics
import sys
import time
from pathlib import Path

LAB5_ROOT = Path(__file__).resolve().parents[1]
LAB4_SRC = LAB5_ROOT.parent / "lab4" / "src"
sys.path.insert(0, str(LAB4_SRC))

from run_lab4 import BASE_TEXTS, MESSAGES, make_cover  # noqa: E402
from stego_methods import (  # noqa: E402
    SteganographyError,
    embed_space,
    embed_zero_width,
    extract_space,
    extract_zero_width,
)

RESULTS_ROOT = LAB5_ROOT / "results"
WARMUP = 5
REPEATS = 30

METHODS = {
    "space": (embed_space, extract_space),
    "zero_width": (embed_zero_width, extract_zero_width),
}


def configurations() -> list[tuple[str, str, str, str, str]]:
    return [
        (method, language, text_format, size, message)
        for method in METHODS
        for language in BASE_TEXTS
        for text_format in ("txt", "html")
        for size, message in MESSAGES.items()
    ]


def benchmark_configuration(method: str, language: str, text_format: str, size: str, message: str) -> list[dict[str, object]]:
    embed, extract = METHODS[method]
    cover = make_cover(language, text_format)
    rows: list[dict[str, object]] = []

    for iteration in range(WARMUP):
        stego_text = embed(cover, message)
        if extract(stego_text) != message:
            raise AssertionError(f"Прогревочный запуск {iteration} вернул неверное сообщение.")

    for iteration in range(REPEATS):
        start = time.perf_counter_ns()
        stego_text = embed(cover, message)
        embed_ns = time.perf_counter_ns() - start

        start = time.perf_counter_ns()
        extracted = extract(stego_text)
        extract_ns = time.perf_counter_ns() - start

        if extracted != message:
            raise AssertionError(f"Итерация {iteration}: извлечённое сообщение не совпадает с исходным.")

        rows.append({"method": method, "language": language, "format": text_format, "message_size": size,
                     "iteration": iteration, "operation": "embed", "nanoseconds": embed_ns})
        rows.append({"method": method, "language": language, "format": text_format, "message_size": size,
                     "iteration": iteration, "operation": "extract", "nanoseconds": extract_ns})
    return rows


def summarize(raw_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    grouped: dict[tuple[str, str, str, str, str], list[int]] = {}
    for row in raw_rows:
        key = (row["method"], row["language"], row["format"], row["message_size"], row["operation"])
        grouped.setdefault(key, []).append(int(row["nanoseconds"]))

    summary = []
    for (method, language, text_format, size, operation), timings in sorted(grouped.items()):
        summary.append({
            "method": method,
            "language": language,
            "format": text_format,
            "message_size": size,
            "operation": operation,
            "samples": len(timings),
            "mean_us": round(statistics.mean(timings) / 1000, 2),
            "stdev_us": round(statistics.stdev(timings) / 1000, 2) if len(timings) > 1 else 0.0,
            "min_us": round(min(timings) / 1000, 2),
            "max_us": round(max(timings) / 1000, 2),
        })
    return summary


def write_csv(path: Path, rows: list[dict[str, object]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    RESULTS_ROOT.mkdir(parents=True, exist_ok=True)
    raw_rows: list[dict[str, object]] = []
    for config in configurations():
        raw_rows.extend(benchmark_configuration(*config))

    write_csv(RESULTS_ROOT / "summary.csv", summarize(raw_rows))
    print(f"Замеров: {len(raw_rows)} по {len(configurations())} конфигурациям "
          f"(по {REPEATS} на операцию, прогрев {WARMUP}).")
    print(f"Окружение: Python {sys.version.split()[0]}, {platform.platform()}.")
    print(f"Результаты сохранены в {RESULTS_ROOT / 'summary.csv'}")


if __name__ == "__main__":
    main()
