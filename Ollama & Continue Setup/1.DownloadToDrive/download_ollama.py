# Bước 3: Start Ollama service
import subprocess
import time
import os
import shutil
from pathlib import Path

# Start Ollama server trong background
subprocess.Popen(['ollama', 'serve'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
time.sleep(5)  # Đợi service khởi động

# Bước 4: Tạo thư mục lưu trữ trong Drive
DRIVE_MODELS_PATH = '/content/drive/MyDrive/ollama_models'
os.makedirs(DRIVE_MODELS_PATH, exist_ok=True)

# Thư mục lưu cache của Ollama (blobs/manifests dùng chung cho tất cả models)
OLLAMA_MODELS_DIR = os.path.expanduser('~/.ollama/models')

# Bước 5: Danh sách mô hình cần download (ĐÃ SỬA: codegamma -> codegemma)
MODELS = [
    'qwen2.5-coder:7b',
    'llama3.1:8b', 
    'deepseek-coder-v2:16b-lite-instruct-q4_K_M',
    'nomic-embed-text:latest',
    'nomic-embed-text:v1.5',
    'codegemma:7b', 
    # Mô hình bổ sung được đề xuất:
    'mistral:7b-instruct',  # Đa năng, tốt cho DevOps scripts
    'phi3:mini',  # Nhẹ, nhanh cho quick tasks
    'deepseek-coder:6.7b',  # Alternative cho code generation
]

def check_model_exists(model_name):
    """Kiểm tra xem mô hình đã được download chưa"""
    model_filename = model_name.replace(':', '_').replace('/', '_')
    model_dir = f"{DRIVE_MODELS_PATH}/{model_filename}"
    
    # Kiểm tra folder và các files quan trọng
    if os.path.exists(model_dir):
        required_files = ['Modelfile', 'blobs', 'manifests']
        existing_files = [f for f in required_files if os.path.exists(f"{model_dir}/{f}")]
        
        if len(existing_files) >= 2:  # Ít nhất có Modelfile và blobs hoặc manifests
            return True
    return False

def clear_ollama_storage():
    """Xóa sạch blobs & manifests của Ollama để tránh lẫn model khác.

    Cảnh báo: Thao tác này sẽ xóa cache của tất cả models trong phiên hiện tại.
    Dùng trong Colab/VM là an toàn; không khuyến khích chạy trên máy cá nhân nếu đang dùng các model khác.
    """
    blobs = os.path.join(OLLAMA_MODELS_DIR, 'blobs')
    manifests = os.path.join(OLLAMA_MODELS_DIR, 'manifests')

    print("\n🧹 Dọn dẹp Ollama cache (blobs/manifests) trước khi pull model...")
    try:
        shutil.rmtree(blobs, ignore_errors=True)
        shutil.rmtree(manifests, ignore_errors=True)
        os.makedirs(blobs, exist_ok=True)
        os.makedirs(manifests, exist_ok=True)
        print("✅ Đã dọn dẹp cache")
    except Exception as e:
        print(f"⚠️ Không thể dọn dẹp cache: {e}")

def download_and_export_model(model_name):
    """Download model từ Ollama và export ra file"""
    
    # ✅ KIỂM TRA MÔ HÌNH ĐÃ TỒN TẠI
    if check_model_exists(model_name):
        print(f"\n{'='*60}")
        print(f"✅ MÔ HÌNH ĐÃ TỒN TẠI: {model_name}")
        print(f"{'='*60}")
        return True
    
    print(f"\n{'='*60}")
    print(f"🔄 Đang xử lý: {model_name}")
    print(f"{'='*60}")
    
    # XÓA CACHE OLLAMA TRƯỚC KHI PULL
    clear_ollama_storage()

    # Pull model (sau khi cache trống => chỉ có dữ liệu của model này)
    print(f"[1/3] Pulling {model_name}...")
    result = subprocess.run(['ollama', 'pull', model_name], 
                          capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Lỗi khi pull {model_name}: {result.stderr}")
        return False
    
    # Export model thành file
    model_filename = model_name.replace(':', '_').replace('/', '_')
    
    # ✅ TẠO FOLDER MỚI CHO MÔ HÌNH
    model_dir = f"{DRIVE_MODELS_PATH}/{model_filename}"
    os.makedirs(model_dir, exist_ok=True)
    print(f"[2/3] Tạo folder mới: {model_dir}")
    
    # Tìm file model trong Ollama storage
    ollama_models_dir = OLLAMA_MODELS_DIR
    
    # Export model using ollama show
    modelfile_path = f"{model_dir}/Modelfile"
    result = subprocess.run(['ollama', 'show', model_name, '--modelfile'], 
                          capture_output=True, text=True)
    if result.returncode == 0:
        with open(modelfile_path, 'w') as f:
            f.write(result.stdout)
        print(f"✅ Đã lưu Modelfile")
    
    # Copy blobs (weights)
    print(f"[3/3] Copying model blobs...")
    blobs_source = f"{ollama_models_dir}/blobs"
    blobs_dest = f"{model_dir}/blobs"
    
    if os.path.exists(blobs_source):
        subprocess.run(['cp', '-r', blobs_source, blobs_dest])
        print(f"✅ Đã copy blobs")
    
    # Copy manifests
    manifests_source = f"{ollama_models_dir}/manifests"
    manifests_dest = f"{model_dir}/manifests"
    
    if os.path.exists(manifests_source):
        subprocess.run(['cp', '-r', manifests_source, manifests_dest])
        print(f"✅ Đã copy manifests")
    
    print(f"✅ Hoàn thành: {model_name}")
    return True