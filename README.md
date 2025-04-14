# automate_localization

---------------------------------------------------------------------
Install Python:
brew install python

Check Python Version:
python3 --version
pip3 --version

Install Deep Translator:
pip3 install deep-translator

Run the Script:
python3 translate_json.py

🔹 Step 1: Create a Virtual Environment
python3 -m venv venv

🔹 Step 2: Activate the Virtual Environment
source venv/bin/activate

Your prompt will now look like this:
(venv) username@user %

🔹 Step 3: Install Deep Translator (now allowed)
pip install deep-translator

🔹 Step 4: Run Your Script
python translate_json.py

# For Colored Output
Install deep-translator and colorama:
pip install deep-translator colorama
---------------------------------------------------------------------

Here’s a **GitHub README.md** version for your language translation automation project using `deep-translator`. It includes installation steps, usage instructions, images, and guidance.

---

# 🌍 Language Translation Automation using Python

This project demonstrates how to **automate translation** of an English `.json` file (typically used for localization in Flutter apps) into multiple languages using Python and the [`deep-translator`](https://github.com/nidhaloff/deep-translator) package.

> ✅ Automates translation of text into 15+ languages  
> ✅ Outputs Flutter-compatible JSON files  
> ✅ Simple setup and CLI usage  
> ✅ Uses Google Translate API via `deep-translator`

---

## 📸 Preview

### 🔧 Terminal Execution
![Screenshot 2025-04-14 at 7.24.50 PM.png](..%2F..%2FDesktop%2FScreenshot%202025-04-14%20at%207.24.50%E2%80%AFPM.png)
### 📁 Output Folder
Each language will have its corresponding JSON file:

```
translated_output/
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
pip install deep-translator
```

---

## 📄 Usage

### Input
Place your English translation file `en.json` in the root directory. Example:
```json
{
  "hello": "Hello",
  "welcome": "Welcome",
  "thanks": "Thank you"
}
```

### Run the Script
```bash
python translate_json.py
```

### During Execution
You'll see live updates like:
```
Translating to am (Amharic)
Line 1: Hello → ሰላም
Line 2: Welcome → እንኳን ደህና መጡ
...
```

---

## 🌐 Supported Languages

- English (`en`)
- Amharic (`am`)
- Gujarati (`gu`)
- Kannada (`kn`)
- Marathi (`mr`)
- Punjabi (`pa`)
- Oromo (`om`)
- Bengali (`bn`)
- Somali (`so`)
- Telugu (`te`)
- Tamil (`ta`)
- Urdu (`ur`)
- Hindi (`hi`)
- Tigrinya (`ti`)
- Portuguese (`pt`)

You can customize this list in `translate_json.py` under:
```python
target_languages = {
  'am': 'Amharic',
  'gu': 'Gujarati',
  ...
}
```

---

## 📦 Output

After completion, you will get JSON files like `hi.json`, `ta.json`, `pa.json` inside the `/translated_output` directory, ready for integration with your Flutter app.

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

---

Would you like me to generate the actual `translate_json.py` and folder structure as well?


