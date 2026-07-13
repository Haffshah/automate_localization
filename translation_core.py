import json
import os
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
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
        core = part.strip()
        translated_core = translate_fn(core)
        if translated_core is None:
            translated_core = core
        translated_parts.append(leading + translated_core + trailing)

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
        translated = translator.translate(segment)
        return translated if translated is not None else segment

    if is_icu_message(text):
        return translate_icu_message(text, translate_segment)

    return translate_plain_text(text, translate_segment)


def translate_batch(target_lang: str, texts: list[str], chunk_size: int = 40, max_retries: int = 5) -> list[str]:
    translated_results: list[str] = []
    translator = GoogleTranslator(source="en", target=target_lang)
    total_batches = (len(texts) + chunk_size - 1) // chunk_size

    for index in range(0, len(texts), chunk_size):
        chunk = texts[index : index + chunk_size]
        translated_chunk = None

        for attempt in range(max_retries):
            try:
                translated_chunk = translator.translate_batch(chunk)
                print(
                    f"{Fore.CYAN}   ... translated batch {index // chunk_size + 1}/{total_batches}{Style.RESET_ALL}"
                )
                break
            except Exception as error:
                wait = min(2 ** attempt, 30)
                print(
                    f"{Fore.RED}❌ Batch {index // chunk_size + 1} attempt {attempt + 1}/{max_retries}: {error}{Style.RESET_ALL}"
                )
                if attempt < max_retries - 1:
                    time.sleep(wait)

        if translated_chunk is None:
            print(f"{Fore.YELLOW}   ... falling back to per-string translation for batch {index // chunk_size + 1}{Style.RESET_ALL}")
            for text in chunk:
                for attempt in range(max_retries):
                    try:
                        translated_results.append(translator.translate(text) or text)
                        break
                    except Exception:
                        if attempt < max_retries - 1:
                            time.sleep(min(2 ** attempt, 15))
                        else:
                            translated_results.append(text)
        else:
            translated_results.extend(translated_chunk)

    return translated_results


def translate_arb_batch(target_lang: str, texts: list[str]) -> list[str]:
    translated_results: list[str | None] = [None] * len(texts)
    plain_indices: list[int] = []
    plain_texts: list[str] = []
    complex_indices: list[int] = []

    for index, text in enumerate(texts):
        if is_icu_message(text) or ("{" in text and "}" in text):
            complex_indices.append(index)
        else:
            plain_indices.append(index)
            plain_texts.append(text)

    total = len(texts)
    if plain_texts:
        print(f"{Fore.CYAN}   ... batch translating {len(plain_texts)} plain strings{Style.RESET_ALL}")
        translated_plain = translate_batch(target_lang, plain_texts)
        for index, translated in zip(plain_indices, translated_plain):
            translated_results[index] = translated

    if complex_indices:
        print(f"{Fore.CYAN}   ... translating {len(complex_indices)} strings with placeholders{Style.RESET_ALL}")
        for count, index in enumerate(complex_indices, start=1):
            try:
                translated_results[index] = translate_text_value(texts[index], target_lang)
            except Exception as error:
                print(f"{Fore.RED}❌ Error translating entry {index + 1}: {error}{Style.RESET_ALL}")
                translated_results[index] = texts[index]
            if count % 10 == 0 or count == len(complex_indices):
                print(f"{Fore.CYAN}   ... placeholders {count}/{len(complex_indices)}{Style.RESET_ALL}")

    print(f"{Fore.CYAN}   ... completed {total}/{total}{Style.RESET_ALL}")
    return [value if value is not None else "" for value in translated_results]


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


def translate_arb_source(
    source_file: str,
    output_dir: str,
    languages: dict[str, str] | None = None,
    parallel_workers: int = 1,
) -> None:
    languages = languages or LANGUAGES
    data = load_json_file(source_file)
    translatable_keys = get_translatable_keys(data)
    values = [data[key] for key in translatable_keys]

    print(
        f"{Fore.BLUE}ℹ️ Loaded {len(translatable_keys)} translatable keys from {source_file}{Style.RESET_ALL}"
    )
    os.makedirs(output_dir, exist_ok=True)

    def translate_language(lang_code: str, lang_name: str) -> str:
        print(f"\n🌍 Translating to {Fore.GREEN}{lang_name}{Style.RESET_ALL} ({lang_code})")
        translated_values = translate_arb_batch(lang_code, values)
        translated_map = dict(zip(translatable_keys, translated_values))
        translated_data = build_arb_output(data, translated_map, lang_code)
        output_path = output_path_for_lang("arb", output_dir, lang_code)
        save_json_file(output_path, translated_data)
        print(f"{Fore.YELLOW}✅ Saved: {output_path}{Style.RESET_ALL}")
        return lang_code

    if parallel_workers > 1:
        with ThreadPoolExecutor(max_workers=parallel_workers) as executor:
            futures = {
                executor.submit(translate_language, code, name): code
                for code, name in languages.items()
            }
            for future in as_completed(futures):
                future.result()
    else:
        for lang_code, lang_name in languages.items():
            translate_language(lang_code, lang_name)
