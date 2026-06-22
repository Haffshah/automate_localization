#!/usr/bin/env python3
import argparse
import os
import sys

from colorama import Fore, Style

from translation_core import (
    FILE_TYPES,
    translate_arb_source,
    translate_json_source,
)


def prompt_choice(prompt: str, valid_choices: dict[str, str]) -> str:
    while True:
        choice = input(prompt).strip().lower()
        if choice in valid_choices:
            return valid_choices[choice]
        print(f"{Fore.RED}Invalid choice. Please enter one of: {', '.join(sorted(set(valid_choices)))}{Style.RESET_ALL}")


def prompt_path(prompt: str, default: str, must_exist: bool = False) -> str:
    while True:
        value = input(f"{prompt} [{default}]: ").strip() or default
        if must_exist and not os.path.exists(value):
            print(f"{Fore.RED}❌ File not found: {value}{Style.RESET_ALL}")
            continue
        return value


def resolve_interactive_options(args: argparse.Namespace) -> tuple[str, str, str]:
    print(f"\n{Fore.BLUE}🌍 Localization Translation Tool{Style.RESET_ALL}\n")
    print("Select source file type:")
    print(f"  1. JSON - {FILE_TYPES['json']['description']}")
    print(f"  2. ARB  - {FILE_TYPES['arb']['description']}")

    if args.yes and args.type:
        file_type = args.type
    else:
        file_type = prompt_choice(
            "\nEnter choice [1/2]: ",
            {"1": "json", "2": "arb", "json": "json", "arb": "arb"},
        )

    config = FILE_TYPES[file_type]
    default_source = config["default_source"]
    if args.source and os.path.exists(args.source):
        default_source = args.source
    default_output = args.output_dir or config["default_output"]

    if args.yes and args.source:
        source_file = args.source
    else:
        source_file = prompt_path("Source file", default_source, must_exist=True)

    if args.yes and args.output_dir:
        output_dir = args.output_dir
    else:
        output_dir = prompt_path("Output directory", default_output)

    return file_type, source_file, output_dir


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Automate localization for JSON and Flutter ARB files using Google Translate."
    )
    parser.add_argument(
        "--type",
        choices=["json", "arb"],
        help="Source file type: json (en.json) or arb (intl_en.arb)",
    )
    parser.add_argument("--source", help="Source file path")
    parser.add_argument("--output_dir", help="Output directory")
    parser.add_argument(
        "-y",
        "--yes",
        action="store_true",
        help="Skip interactive prompts when --type, --source, and --output_dir are provided",
    )
    args = parser.parse_args()

    if args.yes and args.type and args.source and args.output_dir:
        file_type, source_file, output_dir = args.type, args.source, args.output_dir
    else:
        file_type, source_file, output_dir = resolve_interactive_options(args)

    if not os.path.exists(source_file):
        print(f"{Fore.RED}❌ Source file '{source_file}' not found.{Style.RESET_ALL}")
        sys.exit(1)

    print(
        f"\n{Fore.BLUE}ℹ️ Mode: {FILE_TYPES[file_type]['label']} | "
        f"Source: {source_file} | Output: {output_dir}{Style.RESET_ALL}"
    )

    if file_type == "json":
        translate_json_source(source_file, output_dir)
    else:
        translate_arb_source(source_file, output_dir)

    print(f"\n{Fore.GREEN}✅ Translation complete.{Style.RESET_ALL}")


if __name__ == "__main__":
    main()
