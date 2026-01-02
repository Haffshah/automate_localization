# 🌍 Language Translation Automation using Python

This project demonstrates how to **automate translation** of an English `.json` file (typically used for localization in Flutter apps) into multiple languages using Python and the [`deep-translator`](https://github.com/nidhaloff/deep-translator) package.

> ✅ Automates translation of text into 20+ languages  
> ✅ Outputs Flutter-compatible JSON files  
> ✅ Simple setup and CLI usage  
> ✅ Uses Google Translate API via `deep-translator`

---

## 📸 Preview

### 🔧 Terminal Execution 
<img width="581" alt="Screenshot 2025-04-14 at 7 24 50 PM" src="https://github.com/user-attachments/assets/1517444c-f577-4e9f-8c4d-06d09c89e6d7" />


### Output Folder
Each language will have its corresponding JSON file in the `translations` directory:

```
translations/
├── am.json
├── gu.json
├── hi.json
├── mr.json
├── pa.json
├── ta.json
├── te.json
└── ...
```

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
pip install deep-translator colorama
```

---

## 📄 Usage

### Input
Place your English translation file `en.json` in the root directory (or specify another file). Example:
```json
{
  "hello": "Hello",
  "welcome": "Welcome",
  "thanks": "Thank you"
}
```

### Run the Script
Basic usage (defaults to `en.json` and `translations/` output):
```bash
python translate_json.py
```

Custom usage:
```bash
python translate_json.py --source my_file.json --output_dir my_output
```

### During Execution
You'll see batch processing updates:
```
🌍 Translating to Hindi (hi)
   ... translated batch 1/1
✅ Saved: translations/hi.json
```

---

## 🌐 Supported Languages

The script currently supports the following languages:

- **Indian Languages:**
  - Hindi (`hi`)
  - Gujarati (`gu`)
  - Kannada (`kn`)
  - Marathi (`mr`)
  - Punjabi (`pa`)
  - Bengali (`bn`)
  - Telugu (`te`)
  - Tamil (`ta`)
  - Urdu (`ur`)

- **International Languages:**
  - English (`en`)
  - Amharic (`am`)
  - Chinese Traditional (`zh-TW`)
  - Japanese (`ja`)
  - Korean (`ko`)
  - Portuguese (`pt`)
  - Spanish (`es`)
  - French (`fr`)
  - German (`de`)
  - Italian (`it`)
  - Russian (`ru`)
  - Arabic (`ar`)

You can easily add or remove languages by modifying the `languages` dictionary in `translate_json.py`.

---

## 📦 Output

After completion, you will get JSON files like `hi.json`, `ta.json`, `pa.json` inside the `/translations` directory, ready for integration with your Flutter app (or any other project requiring JSON localization).

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
