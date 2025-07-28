#!/usr/bin/env python3

import json
import os
import re
import subprocess
import sys
from abc import ABC, abstractmethod

from css_colors import CSS_COLORS


class ColorExtractor(ABC):
    _pattern = None

    @abstractmethod
    def extractColor(self, text: str) -> dict or None:
        pass

    @staticmethod
    def to_hex(r, g, b, a=None) -> str:
        if a is None or a == 1.0:
            return f"#{r:02x}{g:02x}{b:02x}"
        return f"#{r:02x}{g:02x}{b:02x}{round(a * 255):02x}"


class HexColorExtractor(ColorExtractor):
    _pattern = re.compile(
        r"#[0-9a-fA-F]{8}|#[0-9a-fA-F]{6}|#[0-9a-fA-F]{4}|#[0-9a-fA-F]{3}|[0-9a-fA-F]{8}|[0-9a-fA-F]{6}"
    )

    def extractColor(self, text: str) -> dict or None:
        results = {}
        for match in self._pattern.finditer(text):
            color_string = match.group(0)
            if color_string.startswith("#"):
                hex_str = color_string
                if len(hex_str) == 4:  # #rgb
                    hex_str = f"#{hex_str[1] * 2}{hex_str[2] * 2}{hex_str[3] * 2}"
                elif len(hex_str) == 5:  # #rgba
                    hex_str = f"#{hex_str[1] * 2}{hex_str[2] * 2}{hex_str[3] * 2}{hex_str[4] * 2}"
                results[color_string] = hex_str
            else:
                results[color_string] = f"#{color_string}"
        return results


class RgbColorExtractor(ColorExtractor):
    _pattern = re.compile(
        r"rgba?\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})(?:,\s*(\d*\.?\d+))?\)",
        re.IGNORECASE,
    )

    def extractColor(self, text: str) -> dict or None:
        results = {}
        for match in self._pattern.finditer(text):
            color_string = match.group(0)
            r, g, b = int(match.group(1)), int(match.group(2)), int(match.group(3))
            a = float(match.group(4)) if match.group(4) else None
            results[color_string] = self.to_hex(r, g, b, a)
        return results


class HslColorExtractor(ColorExtractor):
    _pattern = re.compile(
        r"hsla?\((\d{1,3}),\s*(\d{1,3})%,\s*(\d{1,3})%(?:,\s*(\d*\.?\d+))?\)",
        re.IGNORECASE,
    )

    def extractColor(self, text: str) -> dict or None:
        results = {}
        for match in self._pattern.finditer(text):
            color_string = match.group(0)
            h, s, l = int(match.group(1)), int(match.group(2)), int(match.group(3))
            a = float(match.group(4)) if match.group(4) else None
            r, g, b = self.hsl_to_rgb(h, s, l)
            results[color_string] = self.to_hex(r, g, b, a)
        return results

    @staticmethod
    def hsl_to_rgb(h, s, l):
        s /= 100
        l /= 100
        c = (1 - abs(2 * l - 1)) * s
        x = c * (1 - abs((h / 60) % 2 - 1))
        m = l - c / 2
        r, g, b = 0, 0, 0
        if 0 <= h < 60:
            r, g, b = c, x, 0
        elif 60 <= h < 120:
            r, g, b = x, c, 0
        elif 120 <= h < 180:
            r, g, b = 0, c, x
        elif 180 <= h < 240:
            r, g, b = 0, x, c
        elif 240 <= h < 300:
            r, g, b = x, 0, c
        elif 300 <= h < 360:
            r, g, b = c, 0, x
        r, g, b = round((r + m) * 255), round((g + m) * 255), round((b + m) * 255)
        return r, g, b


class CssColorNameExtractor(ColorExtractor):
    _pattern = re.compile(
        r"\b(?:" + "|".join(CSS_COLORS.keys()) + r")\b", re.IGNORECASE
    )

    def extractColor(self, text: str) -> dict or None:
        results = {}
        for match in self._pattern.finditer(text):
            color_string = match.group(0)
            color_name = color_string.lower()
            hex_str = CSS_COLORS.get(color_name)
            results[color_string] = hex_str
        return results


def get_clipboard_text() -> str:
    try:
        return subprocess.check_output("pbpaste", universal_newlines=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def extract_color(original_string) -> dict:
    extractors = [
        HexColorExtractor(),
        RgbColorExtractor(),
        HslColorExtractor(),
        CssColorNameExtractor(),
    ]
    results = {}
    for extractor in extractors:
        results.update(extractor.extractColor(original_string) or {})
    return results


HISTORY_FILE = ".clip-color-history"


def get_history() -> dict:
    history_file = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), HISTORY_FILE
    )

    history = {}
    if os.path.exists(history_file):
        with open(history_file, "r") as f:
            history_lines = f.readlines()
        for line in reversed(history_lines):
            parts = line.strip().split(",")
            if len(parts) != 2:
                print(f"Error: malformatted histtory line {line}.", file=sys.stderr)
                continue
            history[parts[0]] = parts[1]
    return history


def write_to_history(results: dict):
    history_file = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), HISTORY_FILE
    )

    with open(history_file, "w") as f:
        for color_str, hex_str in results.items():
            f.write(f"{color_str},{hex_str}\n")


def format_results(results: dict) -> str:
    menu_items = []
    for color_str, hex_str in results.items():
        hex_code = hex_str.removeprefix("#")
        menu_items.append(
            {
                "text": color_str,
                "imagecolor": hex_str,
                "subtext": hex_str,
                "click": f"https://www.color-hex.com/color/{hex_code}",
            }
        )
    return json.dumps(
        {"text": "", "imagesymbol": "list.bullet.clipboard", "menus": menu_items}
    )


def main():
    MAX_RESULT_NUM = 20
    results = {}

    # Add entries from history
    for color_str, hex_str in get_history().items():
        if len(results) == MAX_RESULT_NUM:
            break
        results[color_str] = hex_str

    # Add results from the current clipboard content
    text = get_clipboard_text()
    if text:
        for color_str, hex_str in extract_color(text).items():
            if color_str not in results:
                results[color_str] = hex_str

    # Resize results to max (keeping the last MAX_RESULT_NUM items)
    results = dict(list(results.items())[-MAX_RESULT_NUM:])

    # Write back to history
    write_to_history(results)

    # Print result
    print(format_results(results))


if __name__ == "__main__":
    main()
