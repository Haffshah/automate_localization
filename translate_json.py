#!/usr/bin/env python3
"""Backward-compatible entry point. Prefer running `python translate.py` instead."""

import argparse
import os
import sys

from colorama import Fore, Style, init
from translation_core import translate_json_source

init(autoreset=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Automate JSON localization using Google Translate.")
    parser.add_argument("--source", default="en.json", help="Source JSON file (default: en.json)")
    parser.add_argument("--output_dir", default="translations", help="Output directory (default: translations)")
    args = parser.parse_args()

    if not os.path.exists(args.source):
        print(f"{Fore.RED}❌ Source file '{args.source}' not found.{Style.RESET_ALL}")
        sys.exit(1)

    print(
        f"{Fore.YELLOW}ℹ️ translate_json.py is kept for compatibility. "
        f"Use `python translate.py` for JSON and ARB support.{Style.RESET_ALL}"
    )
    translate_json_source(args.source, args.output_dir)


if __name__ == "__main__":
    main()
