#!/bin/bash

###############################################################################
# Script Setup Continue Extension for VSCode
# Tự động cài đặt và config Continue extension
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        CONTINUE EXTENSION SETUP FOR GOLANG/MONGODB         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    CONTINUE_DIR="$HOME/.continue"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
    CONTINUE_DIR="$HOME/.continue"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
    CONTINUE_DIR="$APPDATA/.continue"
fi

echo -e "${YELLOW}🖥️  Detected OS: ${OS}${NC}"
echo ""

# Check if VSCode is installed
if ! command -v code &> /dev/null; then
    echo -e "${RED}❌ VSCode không tìm thấy!${NC}"
    echo "Vui lòng cài đặt VSCode và thêm 'code' vào PATH"
    exit 1
fi

echo -e "${GREEN}✅ VSCode đã được cài đặt${NC}"

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}⚠️  Ollama chưa chạy, đang khởi động...${NC}"
    if [[ "$OS" == "windows" ]]; then
        echo "Vui lòng khởi động Ollama manually trên Windows"
    else
        ollama serve &
        sleep 3
    fi
fi

echo -e "${GREEN}✅ Ollama service đang chạy${NC}"
echo ""

# Install Continue extension
echo -e "${YELLOW}📦 Đang cài đặt Continue extension...${NC}"
code --install-extension continue.continue 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Extension có thể đã được cài đặt${NC}"
}
echo -e "${GREEN}✅ Continue extension ready${NC}"
echo ""

# Create Continue config directory
echo -e "${YELLOW}📁 Tạo thư mục config: ${CONTINUE_DIR}${NC}"
mkdir -p "$CONTINUE_DIR"

## Backup existing YAML config if exists
if [ -f "$CONTINUE_DIR/config.yaml" ]; then
    BACKUP_FILE="$CONTINUE_DIR/config.yaml.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}💾 Backup config cũ: ${BACKUP_FILE}${NC}"
    cp "$CONTINUE_DIR/config.yaml" "$BACKUP_FILE"
fi

## Copy provided YAML config into Continue config directory
SOURCE_YAML="$(cd "$(dirname "$0")" && pwd)/config.yaml"
if [ ! -f "$SOURCE_YAML" ]; then
    echo -e "${RED}❌ Không tìm thấy file config.yaml tại: ${SOURCE_YAML}${NC}"
    exit 1
fi

echo -e "${YELLOW}⚙️  Đang copy config.yaml vào ${CONTINUE_DIR}...${NC}"
cp "$SOURCE_YAML" "$CONTINUE_DIR/config.yaml"

echo -e "${GREEN}✅ Config đã được copy vào: ${CONTINUE_DIR}/config.yaml${NC}"
echo ""

# Test Ollama models
echo -e "${YELLOW}🔍 Kiểm tra models có sẵn trong Ollama...${NC}"
ollama list

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    SETUP HOÀN TẤT!                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✨ Continue extension đã được cấu hình!${NC}"
echo ""
echo -e "${YELLOW}📋 Bước tiếp theo:${NC}"
echo "1. Restart VSCode"
echo "2. Mở Continue sidebar (Ctrl+L hoặc Cmd+L)"
echo "3. Test bằng cách gõ: '/review-go' hoặc '/gen-handler'"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo "- Tab autocomplete: Gõ code và nhấn Tab để gợi ý"
echo "- Inline edit: Ctrl+I (Windows/Linux) hoặc Cmd+I (Mac)"
echo "- Custom commands: Gõ '/' để xem danh sách commands"
echo ""