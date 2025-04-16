import json
import os
from deep_translator import GoogleTranslator
from colorama import Fore, Style, init

init(autoreset=True)  # For coloring output

# Load the source file
with open("en.json", "r", encoding="utf-8") as f:
    data = json.load(f)

languages = {
    "am": "Amharic",
    "gu": "Gujarati",
    "kn": "Kannada",
    "mr": "Marathi",
    "pa": "Punjabi",
    "zh-TW": "Chinese",
    "bn": "Bengali",
    "ja": "Japanese",
    "te": "Telugu",
    "ta": "Tamil",
    "ur": "Urdu",
    "hi": "Hindi",
    "ko": "Korean",
    "pt": "Portuguese"
}

os.makedirs("translations", exist_ok=True)

for lang_code, lang_name in languages.items():
    print(f"\n🌍 Translating to {Fore.GREEN}{lang_name}{Style.RESET_ALL} ({lang_code})")
    translated_data = {}

    total = len(data)
    for i, (key, value) in enumerate(data.items(), start=1):
        try:
            translation = GoogleTranslator(source='en', target=lang_code).translate(value)
            translated_data[key] = translation

            print(f"{Fore.CYAN}✔️ [{i}/{total}] Translating key: {key}{Style.RESET_ALL}")
        except Exception as e:
            print(f"{Fore.RED}❌ Error translating {key}: {e}{Style.RESET_ALL}")
            translated_data[key] = value  # fallback to English

    # Save to file
    with open(f"translations/{lang_code}.json", "w", encoding="utf-8") as f:
        json.dump(translated_data, f, ensure_ascii=False, indent=2)

    print(f"{Fore.YELLOW}✅ Done: {lang_name} → translations/{lang_code}.json{Style.RESET_ALL}")
