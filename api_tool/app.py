import json
from flask import Flask, request, jsonify
from flask_cors import CORS
from deep_translator import GoogleTranslator

app = Flask(__name__)
CORS(app)

# Available languages map
LANGUAGES = {
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

def translate_batch(target_lang, texts, chunk_size=50):
    """Translate a list of texts in chunks."""
    translated_results = []
    translator = GoogleTranslator(source='en', target=target_lang)
    
    for i in range(0, len(texts), chunk_size):
        chunk = texts[i:i + chunk_size]
        try:
            translated_chunk = translator.translate_batch(chunk)
            translated_results.extend(translated_chunk)
        except Exception as e:
            print(f"Error translating chunk to {target_lang}: {e}")
            translated_results.extend(chunk)
            
    return translated_results

@app.route('/', methods=['GET'])
def home():
    """API Root with documentation."""
    return jsonify({
        "status": "online",
        "message": "Localization API is running.",
        "endpoints": {
            "GET /api/languages": "List supported languages",
            "POST /api/translate_single": "Translate a JSON file. Params: 'file' (multipart/form-data), 'language' (string code)"
        }
    })

@app.route('/api/languages', methods=['GET'])
def get_languages():
    return jsonify(LANGUAGES)

@app.route('/api/translate_single', methods=['POST'])
def translate_single():
    """Translate file to a single language and return JSON (API endpoint)."""
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
        
    file = request.files['file']
    target_lang = request.form.get('language')
    
    if not target_lang or target_lang not in LANGUAGES:
         return jsonify({"error": f"Invalid or missing language. Supported: {list(LANGUAGES.keys())}"}), 400

    try:
        content = file.read().decode('utf-8')
        data = json.loads(content)
        
        keys = list(data.keys())
        values = list(data.values())
        
        print(f"Translating to {LANGUAGES[target_lang]}...")
        translated_values = translate_batch(target_lang, values)
        translated_data = dict(zip(keys, translated_values))
        
        return jsonify(translated_data)

    except json.JSONDecodeError:
        return jsonify({"error": "Invalid JSON file"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)
