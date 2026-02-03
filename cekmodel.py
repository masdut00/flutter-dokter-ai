import requests
import json

# Paste API Key BARU kamu di sini
API_KEY = "AIzaSyBejc1i1aYo2Zly_CvJa40LKJnznxKEWsk"

url = f"https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}"

try:
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        print("=== DAFTAR MODEL YANG TERSEDIA UNTUK KUNCI INI ===")
        found_any = False
        for model in data.get('models', []):
            # Kita cari model yang support 'generateContent'
            if 'generateContent' in model.get('supportedGenerationMethods', []):
                print(f"- {model['name']}") # Contoh output: models/gemini-1.5-flash
                found_any = True
        
        if not found_any:
            print("Tidak ada model yang support generateContent.")
    else:
        print(f"Error {response.status_code}: {response.text}")

except Exception as e:
    print(f"Script Error: {e}")