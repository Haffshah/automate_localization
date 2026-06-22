import json
import os
import re
from deep_translator import GoogleTranslator
from colorama import Fore, Style, init

init(autoreset=True)

LANGUAGES = {
    "am": "Amharic",
    "as": "Assamese",
    "gu": "Gujarati",
    "kn": "Kannada",
    "ml": "Malayalam",
    "mr": "Marathi",
    "or": "Odia",
    "pa": "Punjabi",
    "zh-TW": "Chinese (Traditional)",
    "bn": "Bengali",
    "ja": "Japanese",
    "te": "Telugu",
    "ta": "Tamil",
    "ur": "Urdu",
    "hi": "Hindi",
    "ko": "Korean",
    "pt": "Portuguese",
    "es": "Spanish",
    "fr": "French",
    "de": "German",
    "it": "Italian",
    "ru": "Russian",
    "ar": "Arabic",
}

FILE_TYPES = {
    "json": {
        "label": "JSON",
        "default_source": "en.json",
        "default_output": "translations",
        "description": "en.json → translations/{lang}.json",
    },
    "arb": {
        "label": "ARB (Flutter intl)",
        "default_source": "intl_en.arb",
        "default_output": ".",
        "description": "intl_en.arb → intl_{lang}.arb",
    },
}

ICU_BRANCH_PATTERN = re.compile(r"(=\w+|zero|one|two|few|many|other)\{([^{}]*)\}")
BRACE_SEGMENT_PATTERN = re.compile(r"(\{[^{}]+\})")


def is_metadata_key(key: str) -> bool:
    return key.startswith("@")


def is_locale_key(key: str) -> bool:
    return key == "@@locale"


def is_icu_message(text: str) -> bool:
    return ", plural," in text or ", select," in text or ", selectordinal," in text


def translate_plain_text(text: str, translate_fn) -> str:
    parts = BRACE_SEGMENT_PATTERN.split(text)
    translated_parts: list[str] = []

    for part in parts:
        if not part:
            continue
        if part.startswith("{") and part.endswith("}"):
            translated_parts.append(part)
            continue

        if not part.strip():
            translated_parts.append(part)
            continue

        leading = part[: len(part) - len(part.lstrip())]
        trailing = part[len(part.rstrip()) :]
        translated_parts.append(leading + translate_fn(part.strip()) + trailing)

    return "".join(translated_parts)


def translate_icu_message(text: str, translate_fn) -> str:
    def replace_branch(match: re.Match[str]) -> str:
        prefix, inner = match.group(1), match.group(2)
        if not inner.strip():
            return match.group(0)
        translated_inner = translate_plain_text(inner, translate_fn)
        return f"{prefix}{{{translated_inner}}}"

    return ICU_BRANCH_PATTERN.sub(replace_branch, text)


def translate_text_value(text: str, target_lang: str) -> str:
    if not text or not text.strip():
        return text

    translator = GoogleTranslator(source="en", target=target_lang)

    def translate_segment(segment: str) -> str:
        if not segment or not segment.strip():
            return segment
        return translator.translate(segment)

    if is_icu_message(text):
        return translate_icu_message(text, translate_segment)

    return translate_plain_text(text, translate_segment)


def translate_batch(target_lang: str, texts: list[str], chunk_size: int = 50) -> list[str]:
    translated_results: list[str] = []
    translator = GoogleTranslator(source="en", target=target_lang)
    total_batches = (len(texts) + chunk_size - 1) // chunk_size

    for index in range(0, len(texts), chunk_size):
        chunk = texts[index : index + chunk_size]
        try:
            translated_chunk = translator.translate_batch(chunk)
            translated_results.extend(translated_chunk)
            print(
                f"{Fore.CYAN}   ... translated batch {index // chunk_size + 1}/{total_batches}{Style.RESET_ALL}"
            )
        except Exception as error:
            print(
                f"{Fore.RED}❌ Error translating batch starting at index {index}: {error}{Style.RESET_ALL}"
            )
            translated_results.extend(chunk)

    return translated_results


def translate_arb_batch(target_lang: str, texts: list[str]) -> list[str]:
    translated_results: list[str] = []
    total = len(texts)

    for index, text in enumerate(texts, start=1):
        try:
            translated_results.append(translate_text_value(text, target_lang))
            if index % 10 == 0 or index == total:
                print(f"{Fore.CYAN}   ... translated {index}/{total}{Style.RESET_ALL}")
        except Exception as error:
            print(f"{Fore.RED}❌ Error translating entry {index}: {error}{Style.RESET_ALL}")
            translated_results.append(text)

    return translated_results


def load_json_file(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def save_json_file(path: str, data: dict) -> None:
    with open(path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)
        file.write("\n")


def get_translatable_keys(data: dict) -> list[str]:
    return [
        key
        for key, value in data.items()
        if not is_metadata_key(key) and isinstance(value, str)
    ]


def build_arb_output(data: dict, translated_values: dict[str, str], lang_code: str) -> dict:
    output: dict = {}

    for key, value in data.items():
        if is_locale_key(key):
            output[key] = lang_code
        elif is_metadata_key(key):
            output[key] = value
        elif key in translated_values:
            output[key] = translated_values[key]
        else:
            output[key] = value

    return output


def output_path_for_lang(file_type: str, output_dir: str, lang_code: str) -> str:
    if file_type == "json":
        return os.path.join(output_dir, f"{lang_code}.json")
    return os.path.join(output_dir, f"intl_{lang_code}.arb")


def translate_json_source(source_file: str, output_dir: str, languages: dict[str, str] | None = None) -> None:
    languages = languages or LANGUAGES
    data = load_json_file(source_file)
    keys = list(data.keys())
    values = [data[key] for key in keys]

    print(f"{Fore.BLUE}ℹ️ Loaded {len(keys)} keys from {source_file}{Style.RESET_ALL}")
    os.makedirs(output_dir, exist_ok=True)

    for lang_code, lang_name in languages.items():
        print(f"\n🌍 Translating to {Fore.GREEN}{lang_name}{Style.RESET_ALL} ({lang_code})")
        translated_values = translate_batch(lang_code, values)
        translated_data = dict(zip(keys, translated_values))
        output_path = output_path_for_lang("json", output_dir, lang_code)
        save_json_file(output_path, translated_data)
        print(f"{Fore.YELLOW}✅ Saved: {output_path}{Style.RESET_ALL}")


def translate_arb_source(source_file: str, output_dir: str, languages: dict[str, str] | None = None) -> None:
    languages = languages or LANGUAGES
    data = load_json_file(source_file)
    translatable_keys = get_translatable_keys(data)
    values = [data[key] for key in translatable_keys]

    print(
        f"{Fore.BLUE}ℹ️ Loaded {len(translatable_keys)} translatable keys from {source_file}{Style.RESET_ALL}"
    )
    os.makedirs(output_dir, exist_ok=True)

    for lang_code, lang_name in languages.items():
        print(f"\n🌍 Translating to {Fore.GREEN}{lang_name}{Style.RESET_ALL} ({lang_code})")
        translated_values = translate_arb_batch(lang_code, values)
        translated_map = dict(zip(translatable_keys, translated_values))
        translated_data = build_arb_output(data, translated_map, lang_code)
        output_path = output_path_for_lang("arb", output_dir, lang_code)
        save_json_file(output_path, translated_data)
        print(f"{Fore.YELLOW}✅ Saved: {output_path}{Style.RESET_ALL}")
