from __future__ import annotations

import binascii
from typing import Iterable

NBSP = "\u00a0"
ZERO_WIDTH_ZERO = "\u200c"
ZERO_WIDTH_ONE = "\u200d"
_HEADER_SIZE = 8


class SteganographyError(ValueError):
    pass


def _text_indexes(text: str) -> Iterable[int]:
    in_tag = False
    for index, character in enumerate(text):
        if character == "<":
            in_tag = True
        elif character == ">":
            in_tag = False
        elif not in_tag:
            yield index


def _space_indexes(text: str) -> list[int]:
    return [index for index in _text_indexes(text) if text[index] in {" ", NBSP}]


def _letter_indexes(text: str) -> list[int]:
    return [index for index in _text_indexes(text) if text[index].isalpha()]


def _bytes_to_bits(data: bytes) -> list[int]:
    return [int(bit) for byte in data for bit in f"{byte:08b}"]


def _bits_to_bytes(bits: list[int]) -> bytes:
    if len(bits) % 8:
        raise SteganographyError("Количество битов должно быть кратно восьми.")
    return bytes(int("".join(map(str, bits[index:index + 8])), 2) for index in range(0, len(bits), 8))


def pack_message(message: str) -> bytes:
    data = message.encode("utf-8")
    if len(data) >= 2**32:
        raise SteganographyError("Сообщение слишком длинное.")
    checksum = binascii.crc32(data) & 0xFFFFFFFF
    return len(data).to_bytes(4, "big") + checksum.to_bytes(4, "big") + data


def unpack_message(data: bytes) -> str:
    if len(data) < _HEADER_SIZE:
        raise SteganographyError("Недостаточно данных для заголовка сообщения.")

    message_length = int.from_bytes(data[:4], "big")
    expected_checksum = int.from_bytes(data[4:8], "big")
    message = data[8:]

    if len(message) != message_length:
        raise SteganographyError("Длина извлечённого сообщения не совпадает с заголовком.")

    actual_checksum = binascii.crc32(message) & 0xFFFFFFFF
    if actual_checksum != expected_checksum:
        raise SteganographyError("Контрольная сумма извлечённого сообщения не совпадает.")

    try:
        return message.decode("utf-8")
    except UnicodeDecodeError as error:
        raise SteganographyError("Полезная нагрузка не является UTF-8 текстом.") from error


def _extract_packed_message(bits: list[int]) -> str:
    header_bits = _HEADER_SIZE * 8
    if len(bits) < header_bits:
        raise SteganographyError("В контейнере недостаточно данных для заголовка.")

    header = _bits_to_bytes(bits[:header_bits])
    message_length = int.from_bytes(header[:4], "big")
    required_bits = (message_length + _HEADER_SIZE) * 8
    if len(bits) < required_bits:
        raise SteganographyError("В контейнере недостаточно данных для сообщения.")

    return unpack_message(_bits_to_bytes(bits[:required_bits]))


def space_capacity_bits(cover: str) -> int:
    return sum(cover[index] == " " for index in _space_indexes(cover))


def zero_width_capacity_bits(cover: str) -> int:
    return len(_letter_indexes(cover))


def embed_space(cover: str, message: str) -> str:
    bits = _bytes_to_bits(pack_message(message))
    positions = _space_indexes(cover)
    if len(bits) > len(positions):
        raise SteganographyError(
            f"Недостаточная ёмкость метода пробелов: нужно {len(bits)} бит, доступно {len(positions)}."
        )

    characters = list(cover)
    for position, bit in zip(positions, bits):
        characters[position] = NBSP if bit else " "
    return "".join(characters)


def extract_space(stego_text: str) -> str:
    bits = [int(stego_text[index] == NBSP) for index in _space_indexes(stego_text)]
    return _extract_packed_message(bits)


def embed_zero_width(cover: str, message: str) -> str:
    bits = _bytes_to_bits(pack_message(message))
    positions = _letter_indexes(cover)
    if len(bits) > len(positions):
        raise SteganographyError(
            f"Недостаточная ёмкость метода невидимых символов: нужно {len(bits)} бит, доступно {len(positions)}."
        )

    bit_by_position = dict(zip(positions, bits))
    result: list[str] = []
    for index, character in enumerate(cover):
        result.append(character)
        if index in bit_by_position:
            result.append(ZERO_WIDTH_ONE if bit_by_position[index] else ZERO_WIDTH_ZERO)
    return "".join(result)


def extract_zero_width(stego_text: str) -> str:
    bits: list[int] = []
    in_tag = False
    for index, character in enumerate(stego_text):
        if character == "<":
            in_tag = True
            continue
        if character == ">":
            in_tag = False
            continue
        if not in_tag and character.isalpha() and index + 1 < len(stego_text):
            marker = stego_text[index + 1]
            if marker == ZERO_WIDTH_ZERO:
                bits.append(0)
            elif marker == ZERO_WIDTH_ONE:
                bits.append(1)
    return _extract_packed_message(bits)


def visible_projection(text: str) -> str:
    return text.replace(NBSP, " ").replace(ZERO_WIDTH_ZERO, "").replace(ZERO_WIDTH_ONE, "")
