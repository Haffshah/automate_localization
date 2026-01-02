import json
import os
import argparse
from deep_translator import GoogleTranslator
from colorama import Fore, Style, init

init(autoreset=True)  # For coloring output

def translate_batch(target_lang, texts, chunk_size=50):
    """Translate a list of texts in chunks to avoid rate limits/payload issues."""
    translated_results = []
    translator = GoogleTranslator(source='en', target=target_lang)
    
    for i in range(0, len(texts), chunk_size):
        chunk = texts[i:i + chunk_size]
        try:
            translated_chunk = translator.translate_batch(chunk)
            translated_results.extend(translated_chunk)
            print(f"{Fore.CYAN}   ... translated batch {i // chunk_size + 1}/{len(texts) // chunk_size + 1}{Style.RESET_ALL}")
        except Exception as e:
            print(f"{Fore.RED}❌ Error translating batch starting at index {i}: {e}{Style.RESET_ALL}")
            # Fallback: append original text or try individual? 
            # For now, append original to keep alignment
            translated_results.extend(chunk)
            
    return translated_results

def main():
    parser = argparse.ArgumentParser(description="Automate localization using Google Translate.")
    parser.add_argument("--source", default="en.json", help="Source JSON file (default: en.json)")
    parser.add_argument("--output_dir", default="translations", help="Output directory (default: translations)")
    args = parser.parse_args()

    source_file = args.source
    output_dir = args.output_dir

    if not os.path.exists(source_file):
        print(f"{Fore.RED}❌ Source file '{source_file}' not found.{Style.RESET_ALL}")
        return

    # Load the source file
    with open(source_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    languages = {
        "am": "Amharic",
        "gu": "Gujarati",
        "kn": "Kannada",
        "mr": "Marathi",
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
        "ar": "Arabic"
    }

    os.makedirs(output_dir, exist_ok=True)

    keys = list(data.keys())
    values = list(data.values())

    print(f"{Fore.BLUE}ℹ️ Loaded {len(keys)} keys from {source_file}{Style.RESET_ALL}")

    for lang_code, lang_name in languages.items():
        print(f"\n🌍 Translating to {Fore.GREEN}{lang_name}{Style.RESET_ALL} ({lang_code})")
        
        translated_values = translate_batch(lang_code, values)
        
        # reconstruct dictionary
        translated_data = dict(zip(keys, translated_values))

        # Save to file
        output_path = os.path.join(output_dir, f"{lang_code}.json")
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(translated_data, f, ensure_ascii=False, indent=2)

        print(f"{Fore.YELLOW}✅ Saved: {output_path}{Style.RESET_ALL}")

if __name__ == "__main__":
    main()
