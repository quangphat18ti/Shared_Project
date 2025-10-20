#!/bin/bash

###############################################################################
# Script Import Ollama Models từ Google Drive
# Sử dụng: ./import_models.sh /path/to/downloaded/ollama_models
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if path argument provided
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ Lỗi: Chưa cung cấp đường dẫn thư mục models${NC}"
    echo "Sử dụng: $0 /path/to/ollama_models"
    exit 1
fi

MODELS_DIR="$1"

# Verify directory exists
if [ ! -d "$MODELS_DIR" ]; then
    echo -e "${RED}❌ Thư mục không tồn tại: $MODELS_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          OLLAMA MODELS IMPORT SCRIPT                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}❌ Ollama chưa được cài đặt!${NC}"
    echo "Download tại: https://ollama.com/download"
    exit 1
fi

# Check if Ollama service is running
if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}⚠️  Ollama service chưa chạy, đang khởi động...${NC}"
    ollama serve &
    sleep 3
fi

echo -e "${GREEN}✅ Ollama service đang chạy${NC}"
echo ""

# Get Ollama models directory
OLLAMA_DIR="$HOME/.ollama/models"

if [ ! -d "$OLLAMA_DIR" ]; then
    echo -e "${YELLOW}📁 Tạo thư mục Ollama: $OLLAMA_DIR${NC}"
    mkdir -p "$OLLAMA_DIR"
fi

# Ensure required subdirectories exist
mkdir -p "$OLLAMA_DIR/blobs" "$OLLAMA_DIR/manifests"

# Function to import a single model
import_model() {
    local model_dir="$1"
    local model_name=$(basename "$model_dir")
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📦 Đang import: ${model_name}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    # Check if model directory has required files
    if [ ! -d "$model_dir/blobs" ]; then
        echo -e "${RED}❌ Thiếu blobs directory, bỏ qua${NC}"
        return 1
    fi
    
    # Copy blobs
    echo -e "${YELLOW}[1/3] Copy blobs...${NC}"
    if [ -d "$model_dir/blobs" ]; then
        # Copy toàn bộ nội dung, bao gồm file/dir ẩn, giữ nguyên quyền (+a)
        cp -a "$model_dir/blobs/." "$OLLAMA_DIR/blobs/" 2>/dev/null || true
        echo -e "${GREEN}  ✓ Blobs copied${NC}"
    fi
    
    # Copy manifests
    echo -e "${YELLOW}[2/3] Copy manifests...${NC}"
    if [ -d "$model_dir/manifests" ]; then
        # Copy toàn bộ nội dung, bao gồm file/dir ẩn
        cp -a "$model_dir/manifests/." "$OLLAMA_DIR/manifests/" 2>/dev/null || true
        echo -e "${GREEN}  ✓ Manifests copied${NC}"
    fi
    
    # Create model from Modelfile if exists
    echo -e "${YELLOW}[3/3] Tạo model từ Modelfile...${NC}"
    if [ -f "$model_dir/Modelfile" ]; then
        # Sử dụng chính tên thư mục làm tag local để tránh suy đoán sai
        create_name="$model_name"

        cd "$model_dir"
        ollama create "$create_name" -f Modelfile 2>/dev/null || {
            echo -e "${YELLOW}  ⚠️  Không thể tạo từ Modelfile, model có thể đã tồn tại${NC}"
        }
        cd - > /dev/null
        echo -e "${GREEN}  ✓ Model created/verified${NC}"
    fi
    
    echo -e "${GREEN}✅ Hoàn thành: ${model_name}${NC}"
    return 0
}

# Count models
total_models=$(find "$MODELS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
current=0
success=0
failed=0

echo -e "${BLUE}📊 Tìm thấy $total_models models để import${NC}"
echo ""

# Import all models
for model_path in "$MODELS_DIR"/*/ ; do
    if [ -d "$model_path" ]; then
        current=$((current + 1))
        echo -e "\n${BLUE}[${current}/${total_models}]${NC}"
        
        if import_model "$model_path"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
    fi
done

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    KẾT QUẢ IMPORT                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✅ Thành công: ${success}/${total_models}${NC}"
if [ $failed -gt 0 ]; then
    echo -e "${RED}❌ Thất bại: ${failed}/${total_models}${NC}"
fi
echo ""

# Verify imported models
echo -e "${YELLOW}📋 Danh sách models hiện có:${NC}"
echo ""
ollama list

echo ""
echo -e "${GREEN}✨ Import hoàn tất!${NC}"
echo -e "${BLUE}💡 Tip: Chạy 'ollama run <model-name>' để test model${NC}"
echo ""