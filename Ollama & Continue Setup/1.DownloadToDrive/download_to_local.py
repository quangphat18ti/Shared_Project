
import os
import zipfile
import datetime

# Đường dẫn Google Drive chứa các model (đã mount Drive trên Colab)
GDRIVE_MODELS_PATH = '/content/drive/MyDrive/ollama_models'

# Danh sách models cần tải về (tên thư mục model)
MODELS_TO_DOWNLOAD = [
    'qwen2.5-coder_7b',
    'llama3.1_8b',
    'deepseek-coder-v2_16b-lite-instruct-q4_K_M',
    'nomic-embed-text_latest',
    'codegemma_7b',
    'mistral_7b-instruct',
    'phi3_mini',
    'sqlcoder_7b',
]

def is_colab():
    try:
        import google.colab  # type: ignore
        return True
    except Exception:
        return os.path.exists('/content')

def zip_and_download_model(model_name):
    src_folder = os.path.join(GDRIVE_MODELS_PATH, model_name)
    if not os.path.isdir(src_folder):
        print(f"❌ Không tìm thấy thư mục model: {src_folder}")
        return
    ts = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    zip_name = f"{model_name}_{ts}.zip"
    zip_path = os.path.join('/content', zip_name)
    print(f"📦 Đang nén {model_name}...")
    with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED, allowZip64=True) as zf:
        for root, dirs, files in os.walk(src_folder):
            for f in files:
                abs_path = os.path.join(root, f)
                rel_path = os.path.relpath(abs_path, start=os.path.dirname(src_folder))
                zf.write(abs_path, arcname=rel_path)
    print(f"✅ Đã tạo: {zip_path}")
    if is_colab():
        try:
            from google.colab import files  # type: ignore
            print(f"⬇️ Đang tải {zip_name} về máy...")
            files.download(zip_path)
        except Exception as e:
            print(f"❌ Không thể trigger download: {e}")
            print(f"Bạn có thể tự tải file này: {zip_path}")

if __name__ == "__main__":
    print("=== ZIP & DOWNLOAD OLLAMA MODELS ===")
    for model in MODELS_TO_DOWNLOAD:
        zip_and_download_model(model)