# 🌍 Language Translation Automation using Python

This project automates translation of English localization files into multiple languages using Python and the [`deep-translator`](https://github.com/nidhaloff/deep-translator) package.

It supports **two file formats**:

| Type | Source | Output |
|------|--------|--------|
| **JSON** | `en.json` | `translations/{lang}.json` |
| **ARB (Flutter intl)** | `intl_en.arb` | `intl_{lang}.arb` |

> ✅ JSON and Flutter ARB (`.arb`) support  
> ✅ Interactive prompts to choose file type every run  
> ✅ Preserves ARB metadata (`@key`) and placeholders (`{name}`)  
> ✅ Handles ICU plural messages  
> ✅ 23+ target languages including all major Indian languages  
> ✅ Uses Google Translate API via `deep-translator`

---

## 🛠️ Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/Haffshah/automate_localization.git
cd automate_localization
```

### 2. Setup Python Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

---

## 📄 Usage

### Interactive mode (recommended)

Run the unified translator — it will ask which file type to use:

```bash
python translate.py
```

Example session:

```
🌍 Localization Translation Tool

Select source file type:
  1. JSON - en.json → translations/{lang}.json
  2. ARB  - intl_en.arb → intl_{lang}.arb

Enter choice [1/2]: 2
Source file [intl_en.arb]: 
Output directory [.]: arb_output
```

### Non-interactive mode (CI / scripts)

Pass all options and `-y` to skip prompts:

```bash
# JSON
python translate.py --type json --source en.json --output_dir translations -y

# ARB
python translate.py --type arb --source intl_en.arb --output_dir arb_output -y
```

### Legacy JSON-only script

`translate_json.py` still works for backward compatibility:

```bash
python translate_json.py --source en.json --output_dir translations
```

---

## 📁 Input file examples

### JSON (`en.json`)
```json
{
  "hello": "Hello",
  "welcome": "Welcome",
  "thanks": "Thank you"
}
```

### ARB (`intl_en.arb`)
```json
{
  "@@locale": "en",
  "hello": "Hello {name}",
  "@hello": {
    "description": "Greeting with name",
    "placeholders": {
      "name": { "type": "String" }
    }
  }
}
```

ARB translation rules:
- `@` metadata keys are copied unchanged
- `@@locale` is set per output file (e.g. `hi`, `gu`, `ta`)
- `{placeholders}` and ICU plural syntax are preserved

---

## 🌐 Supported Languages

**Indian languages:**
- Hindi (`hi`), Gujarati (`gu`), Kannada (`kn`), Marathi (`mr`), Punjabi (`pa`)
- Bengali (`bn`), Telugu (`te`), Tamil (`ta`), Urdu (`ur`)
- Malayalam (`ml`), Odia (`or`), Assamese (`as`)

**International languages:**
- Amharic (`am`), Chinese Traditional (`zh-TW`), Japanese (`ja`), Korean (`ko`)
- Portuguese (`pt`), Spanish (`es`), French (`fr`), German (`de`)
- Italian (`it`), Russian (`ru`), Arabic (`ar`)

Add or remove languages in the `LANGUAGES` dictionary in `translation_core.py`.

---

## 📦 Output

**JSON mode** — files in `translations/`:
```
translations/hi.json
translations/gu.json
...
```

**ARB mode** — Flutter intl files:
```
intl_hi.arb
intl_gu.arb
intl_ta.arb
...
```

---

## ✨ Contribution

Feel free to fork and contribute with:
- More translation services
- Web interface improvements
- CLI improvements
- Language detection features

---

## 💬 Let’s Connect

If you like this, feel free to share on [LinkedIn](https://www.linkedin.com/in/harsh-m-shah-5152b21a9/) or drop a ⭐️ on the repo.
