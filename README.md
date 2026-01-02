# 🌍 Language Translation Automation using Python

This project demonstrates how to **automate translation** of an English `.json` file (typically used for localization in Flutter apps) into multiple languages using Python and the [`deep-translator`](https://github.com/nidhaloff/deep-translator) package.

> ✅ Automates translation of text into 15+ languages  
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

- English (`en`)
- Amharic (`am`)
- Gujarati (`gu`)
- Kannada (`kn`)
- Marathi (`mr`)
- Punjabi (`pa`)
- Chinese Traditional (`zh-TW`)
- Bengali (`bn`)
- Japanese (`ja`)
- Telugu (`te`)
- Tamil (`ta`)
- Urdu (`ur`)
- Hindi (`hi`)
- Number of others including Spanish, French, German, Italian, Russian, Arabic, etc.

You can customize this list in `translate_json.py`.

---

## 📦 Output

After completion, you will get JSON files like `hi.json`, `ta.json`, `pa.json` inside the `/translations` directory, ready for integration with your Flutter app.

---

## 💻 Web Interface (Flutter + Python)

This project now includes a **Flutter Web** interface powered by a **Python Flask** backend.

### Architecture
- **Frontend**: Flutter Web (`flutter_localization_web/`) - A modern, responsive UI.
- **Backend**: Python Flask (`web_tool/app.py`) - Handles the translation logic and file processing.

### How to Run

1. **Start the Backend Server**:
   ```bash
   # Terminal 1
   source venv/bin/activate
   python web_tool/app.py
   ```
   The API will be available at `http://127.0.0.1:5000/api`.

2. **Run the Flutter App**:
   ```bash
   # Terminal 2
   cd flutter_localization_web
   flutter run -d chrome --web-renderer html
   ```
   The app will open in Chrome. You can upload your `en.json`, select languages, and download the results.

### Technical Notes
- **CORS**: The Flask backend is configured to accept requests from the Flutter Web app.
- **Web Renderer**: Using `--web-renderer html` is recommended for better compatibility with file downloads in development, though `auto` usually works too.

---

## ✨ Contribution

Feel free to fork and contribute with:
- More translation services
- Web interface
- CLI improvements
- Language detection features

---

## 💬 Let’s Connect

If you like this, feel free to share on [LinkedIn](https://www.linkedin.com/in/harsh-m-shah-5152b21a9/) or drop a ⭐️ on the repo.

