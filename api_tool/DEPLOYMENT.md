# 🚀 How to Deploy This API

You can deploy this Flask API for free using platforms like **Render**, **Railway**, or **PythonAnywhere**.

Here is a step-by-step guide using **Render** (recommended for its free tier and ease of use).

## 1. Prepare Your Repository
Ensure you have committed the latest changes, including the new `requirements.txt` and `Procfile` inside the `api_tool` folder.

```bash
git add api_tool/requirements.txt api_tool/Procfile
git commit -m "Add deployment config"
git push origin main
```

## 2. Deploy on Render.com
1. **Sign Up/Login**: Go to [render.com](https://render.com) and log in with your GitHub account.
2. **New Web Service**: Click **"New +"** → **"Web Service"**.
3. **Connect Repo**: Select your `automate_localization` repository.
4. **Configure Settings**:
   - **Name**: `my-localization-api` (or anything you like)
   - **Region**: Choose the one closest to you (e.g., Singapore, Frankfurt, Oregon).
   - **Branch**: `main` (or `master`).
   - **Root Directory**: `api_tool` (⚠️ **Important**: This tells Render the app is in this subfolder).
   - **Runtime**: `Python 3`.
   - **Build Command**: `pip install -r requirements.txt`.
   - **Start Command**: `gunicorn app:app`.
   - **Plan**: Select **Free**.

5. **Deploy**: Click **"Create Web Service"**.

Render will now clone your repo, install the dependencies, and start the Gunicorn server.

## 3. API Usage
Once deployed, Render will give you a URL (e.g., `https://my-localization-api.onrender.com`).

### Check Status
**GET** `/`
Returns running status and documentation.
```bash
curl https://my-localization-api.onrender.com/
```

### List Supported Languages
**GET** `/api/languages`
Returns a JSON object of supported language codes and names.
```bash
curl https://my-localization-api.onrender.com/api/languages
```

### Translate a File
**POST** `/api/translate_single`
Uploads a JSON file and returns the translated JSON content.

**Parameters:**
- `file`: The source `.json` file (multipart/form-data).
- `language`: The target language code (e.g., `es`, `hi`, `fr`).

**Example using CURL:**
```bash
# Translate en.json to Spanish (es) and save as es.json
curl -X POST \
  -F "file=@en.json" \
  -F "language=es" \
  https://my-localization-api.onrender.com/api/translate_single > es.json
```

**Example Response:**
```json
{
  "hello": "Hola",
  "welcome": "Bienvenido"
}
```

---

## Alternative: PythonAnywhere
1. Sign up at [PythonAnywhere.com](https://www.pythonanywhere.com/).
2. Go to the **Web** tab and add a new web app.
3. Select **Flask** and the correct Python version.
4. Upload your `app.py` or pull your git repo.
5. In the **WSGI configuration file**, point to your `app.py`.
6. Go to **Consoles** -> **Bash** and install dependencies:
   ```bash
   pip install flask flask-cors deep-translator
   ```
7. Reload the web app.

## ⚠️ Important Notes
- **Cold Starts**: On the Render free tier, the server will "sleep" after 15 minutes of inactivity. The first request after sleep might take 30-60 seconds.
- **Rate Limits**: Since this uses `deep-translator` (which scrapes Google Translate), excessive requests might get blocked. For heavy production use, consider using the official Google Cloud Translation API.
