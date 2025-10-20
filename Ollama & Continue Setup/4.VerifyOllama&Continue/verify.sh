#!/bin/bash
###############################################################################
# Script Kiểm tra toàn bộ setup Ollama + Continue
# Verify models, config, và test functionality
###############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║       OLLAMA + CONTINUE SETUP VERIFICATION SCRIPT          ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# Counter for checks
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Arrays to store results
declare -a FAILED_ITEMS
declare -a WARNING_ITEMS

# Function to run check
run_check() {
    local check_name="$1"
    local check_command="$2"
    local is_critical="${3:-true}"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "${CYAN}[CHECK $TOTAL_CHECKS]${NC} $check_name"
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}   ✓ PASSED${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        if [ "$is_critical" = "true" ]; then
            echo -e "${RED}   ✗ FAILED${NC}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            FAILED_ITEMS+=("$check_name")
        else
            echo -e "${YELLOW}   ⚠ WARNING${NC}"
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            WARNING_ITEMS+=("$check_name")
        fi
        return 1
    fi
}

# Function to display info
show_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Function to display command output
show_output() {
    echo -e "${MAGENTA}   → $1${NC}"
}

###############################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PART 1: SYSTEM REQUIREMENTS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check 1: Ollama installed
run_check "Ollama installed" "command -v ollama"

if command -v ollama &> /dev/null; then
    OLLAMA_VERSION=$(ollama --version 2>&1 | head -n1)
    show_output "Version: $OLLAMA_VERSION"
fi

# Check 2: Ollama service running
run_check "Ollama service running" "pgrep -x ollama || pgrep -f 'ollama serve'"

if pgrep -x ollama > /dev/null || pgrep -f 'ollama serve' > /dev/null; then
    OLLAMA_PID=$(pgrep -x ollama || pgrep -f 'ollama serve' | head -n1)
    show_output "PID: $OLLAMA_PID"
fi

# Check 3: Ollama API responding
run_check "Ollama API responding" "curl -s http://localhost:11434/api/version"

if curl -s http://localhost:11434/api/version &> /dev/null; then
    API_VERSION=$(curl -s http://localhost:11434/api/version)
    show_output "API: $API_VERSION"
fi

# Check 4: VSCode installed
run_check "VSCode installed" "command -v code"

if command -v code &> /dev/null; then
    VSCODE_VERSION=$(code --version 2>&1 | head -n1)
    show_output "Version: $VSCODE_VERSION"
fi

# Check 5: GPU available (NVIDIA)
if command -v nvidia-smi &> /dev/null; then
    run_check "NVIDIA GPU available" "nvidia-smi" false
    
    if nvidia-smi &> /dev/null; then
        show_info "GPU Information:"
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
        GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -n1)
        GPU_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n1)
        show_output "GPU: $GPU_NAME"
        show_output "VRAM: $GPU_MEMORY"
        show_output "Driver: $GPU_DRIVER"
    fi
else
    show_info "GPU check skipped (NVIDIA drivers not found - CPU mode)"
fi

# Check 6: System RAM
TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
AVAILABLE_RAM=$(free -h | awk '/^Mem:/ {print $7}')
show_info "System Memory:"
show_output "Total: $TOTAL_RAM"
show_output "Available: $AVAILABLE_RAM"

# Check 7: Disk space for models
OLLAMA_DIR="$HOME/.ollama"
if [ -d "$OLLAMA_DIR" ]; then
    DISK_USAGE=$(du -sh "$OLLAMA_DIR" 2>/dev/null | cut -f1)
    show_info "Ollama storage: $DISK_USAGE"
fi

###############################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PART 2: OLLAMA MODELS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Required models for backend/devops
REQUIRED_MODELS=(
    "qwen2.5-coder:7b"
    "llama3.1:8b"
    "nomic-embed-text:latest"
)

RECOMMENDED_MODELS=(
    "deepseek-coder-v2:16b-lite-instruct-q4_K_M"
    "codegemma:7b"
    "mistral:7b-instruct"
    "phi3:mini"
    "sqlcoder:7b"
)

# Check required models
show_info "Checking required models..."
for model in "${REQUIRED_MODELS[@]}"; do
    run_check "Model: $model" "ollama list | grep -q '$model'"
done

# Check recommended models
show_info "Checking recommended models..."
for model in "${RECOMMENDED_MODELS[@]}"; do
    run_check "Model: $model" "ollama list | grep -q '$model'" false
done

# List all installed models
echo ""
show_info "All installed models:"
if command -v ollama &> /dev/null; then
    ollama list | tail -n +2 | while read -r line; do
        MODEL_NAME=$(echo "$line" | awk '{print $1}')
        MODEL_SIZE=$(echo "$line" | awk '{print $2}')
        show_output "$MODEL_NAME ($MODEL_SIZE)"
    done
fi

###############################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PART 3: CONTINUE EXTENSION${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check Continue extension installed
CONTINUE_EXT="continue.continue"
run_check "Continue extension installed" "code --list-extensions | grep -q '$CONTINUE_EXT'"

if code --list-extensions | grep -q "$CONTINUE_EXT"; then
    CONTINUE_VERSION=$(code --list-extensions --show-versions | grep "$CONTINUE_EXT" | awk -F'@' '{print $2}')
    show_output "Version: $CONTINUE_VERSION"
fi

# Check Continue config file
CONTINUE_CONFIG="$HOME/.continue/config.json"
run_check "Continue config exists" "test -f '$CONTINUE_CONFIG'"

if [ -f "$CONTINUE_CONFIG" ]; then
    show_info "Config file location: $CONTINUE_CONFIG"
    
    # Validate JSON
    if command -v jq &> /dev/null; then
        if jq empty "$CONTINUE_CONFIG" 2>/dev/null; then
            echo -e "${GREEN}   ✓ Valid JSON${NC}"
        else
            echo -e "${RED}   ✗ Invalid JSON${NC}"
            FAILED_ITEMS+=("Continue config JSON validation")
        fi
        
        # Check models configured
        show_info "Configured models in Continue:"
        jq -r '.models[]?.model // .models[]?.title // empty' "$CONTINUE_CONFIG" 2>/dev/null | while read -r model; do
            show_output "$model"
        done
        
        # Check provider
        PROVIDER=$(jq -r '.models[0].provider // "unknown"' "$CONTINUE_CONFIG" 2>/dev/null)
        show_output "Provider: $PROVIDER"
        
        # Check API base
        API_BASE=$(jq -r '.models[0].apiBase // "default"' "$CONTINUE_CONFIG" 2>/dev/null)
        show_output "API Base: $API_BASE"
        
    else
        show_info "jq not installed, skipping JSON validation"
    fi
fi

# Check Continue config.ts (if exists)
CONTINUE_CONFIG_TS="$HOME/.continue/config.ts"
if [ -f "$CONTINUE_CONFIG_TS" ]; then
    show_info "TypeScript config detected: $CONTINUE_CONFIG_TS"
fi

###############################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PART 4: FUNCTIONAL TESTS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Test 1: Simple Ollama query
show_info "Testing Ollama API with simple query..."
TEST_MODEL="qwen2.5-coder:7b"

if ollama list | grep -q "$TEST_MODEL"; then
    echo -e "${CYAN}[TEST]${NC} Querying model: $TEST_MODEL"
    
    RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate \
        -d '{
            "model": "'$TEST_MODEL'",
            "prompt": "Write a hello world in Python",
            "stream": false
        }' 2>&1)
    
    if echo "$RESPONSE" | jq -e '.response' > /dev/null 2>&1; then
        echo -e "${GREEN}   ✓ Model response successful${NC}"
        RESPONSE_TEXT=$(echo "$RESPONSE" | jq -r '.response' | head -c 100)
        show_output "Preview: $RESPONSE_TEXT..."
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}   ✗ Model response failed${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        FAILED_ITEMS+=("Ollama API query test")
    fi
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
else
    echo -e "${YELLOW}   ⚠ Test model not available${NC}"
fi

# Test 2: Model loading speed
show_info "Testing model load time..."
if ollama list | grep -q "$TEST_MODEL"; then
    echo -e "${CYAN}[TEST]${NC} Measuring load time for: $TEST_MODEL"
    
    START_TIME=$(date +%s%N)
    curl -s -X POST http://localhost:11434/api/generate \
        -d '{
            "model": "'$TEST_MODEL'",
            "prompt": "hi",
            "stream": false
        }' > /dev/null 2>&1
    END_TIME=$(date +%s%N)
    
    LOAD_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
    show_output "Load time: ${LOAD_TIME}ms"
    
    if [ $LOAD_TIME -lt 5000 ]; then
        echo -e "${GREEN}   ✓ Fast load time${NC}"
    elif [ $LOAD_TIME -lt 10000 ]; then
        echo -e "${YELLOW}   ⚠ Moderate load time${NC}"
    else
        echo -e "${RED}   ⚠ Slow load time (check GPU/RAM)${NC}"
    fi
fi

# Test 3: Check Ollama logs for errors
show_info "Checking Ollama logs for recent errors..."
if [ -f "$HOME/.ollama/logs/server.log" ]; then
    ERROR_COUNT=$(grep -i "error" "$HOME/.ollama/logs/server.log" 2>/dev/null | wc -l)
    if [ $ERROR_COUNT -gt 0 ]; then
        echo -e "${YELLOW}   ⚠ Found $ERROR_COUNT error entries in logs${NC}"
    else
        echo -e "${GREEN}   ✓ No errors in logs${NC}"
    fi
fi

# Test 4: Continue workspace settings
show_info "Checking VSCode workspace settings..."
if [ -f ".vscode/settings.json" ]; then
    echo -e "${GREEN}   ✓ Workspace settings found${NC}"
    if command -v jq &> /dev/null; then
        CONTINUE_ENABLED=$(jq -r '.["continue.enableTabAutocomplete"] // "not set"' .vscode/settings.json 2>/dev/null)
        show_output "Tab autocomplete: $CONTINUE_ENABLED"
    fi
else
    echo -e "${YELLOW}   ⚠ No workspace settings (optional)${NC}"
fi

###############################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PART 5: PERFORMANCE BENCHMARKS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Benchmark token generation speed
show_info "Running token generation benchmark..."
if ollama list | grep -q "$TEST_MODEL"; then
    echo -e "${CYAN}[BENCHMARK]${NC} Testing tokens/second..."
    
    START_TIME=$(date +%s%N)
    RESPONSE=$(curl -s -X POST http://localhost:11434/api/generate \
        -d '{
            "model": "'$TEST_MODEL'",
            "prompt": "Write a detailed explanation of quicksort algorithm in 200 words",
            "stream": false
        }')
    END_TIME=$(date +%s%N)
    
    DURATION=$(( (END_TIME - START_TIME) / 1000000 ))
    EVAL_COUNT=$(echo "$RESPONSE" | jq -r '.eval_count // 0')
    
    if [ $EVAL_COUNT -gt 0 ]; then
        TOKENS_PER_SEC=$(( EVAL_COUNT * 1000 / DURATION ))
        show_output "Generated tokens: $EVAL_COUNT"
        show_output "Time: ${DURATION}ms"
        show_output "Speed: ${TOKENS_PER_SEC} tokens/sec"
        
        if [ $TOKENS_PER_SEC -gt 40 ]; then
            echo -e "${GREEN}   ✓ Excellent performance${NC}"
        elif [ $TOKENS_PER_SEC -gt 20 ]; then
            echo -e "${YELLOW}   ⚠ Good performance${NC}"
        else
            echo -e "${RED}   ⚠ Low performance (check GPU usage)${NC}"
        fi
    fi
fi

###############################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PART 6: NETWORK & CONNECTIVITY${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check Ollama port
run_check "Ollama port 11434 accessible" "nc -z localhost 11434"

# Check firewall (if applicable)
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status 2>/dev/null | grep -i "active" || echo "inactive")
    show_info "Firewall status: $UFW_STATUS"
fi

# Check if running in WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    show_info "Running in WSL detected"
    echo -e "${CYAN}   → Make sure Windows can access localhost:11434${NC}"
fi

###############################################################################
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}SUMMARY${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Calculate percentage
PASS_PERCENTAGE=$(( PASSED_CHECKS * 100 / TOTAL_CHECKS ))

echo -e "${CYAN}Total Checks:${NC} $TOTAL_CHECKS"
echo -e "${GREEN}Passed:${NC} $PASSED_CHECKS ($PASS_PERCENTAGE%)"
echo -e "${RED}Failed:${NC} $FAILED_CHECKS"
echo -e "${YELLOW}Warnings:${NC} $WARNING_CHECKS"
echo ""

# Show failed items
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}FAILED CHECKS:${NC}"
    for item in "${FAILED_ITEMS[@]}"; do
        echo -e "${RED}  ✗ $item${NC}"
    done
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

# Show warnings
if [ $WARNING_CHECKS -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}WARNINGS:${NC}"
    for item in "${WARNING_ITEMS[@]}"; do
        echo -e "${YELLOW}  ⚠ $item${NC}"
    done
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
fi

# Final verdict
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✓ SETUP COMPLETE - Ready to code!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Open VSCode"
    echo "  2. Press Ctrl+L to open Continue chat"
    echo "  3. Try: 'Write a REST API endpoint in Go'"
    exit 0
elif [ $PASS_PERCENTAGE -ge 80 ]; then
    echo -e "${YELLOW}⚠ SETUP MOSTLY COMPLETE - Some optional features missing${NC}"
    echo ""
    echo -e "${CYAN}Recommendations:${NC}"
    echo "  • Review warnings above"
    echo "  • Install recommended models for better experience"
    exit 0
else
    echo -e "${RED}✗ SETUP INCOMPLETE - Please fix failed checks${NC}"
    echo ""
    echo -e "${CYAN}Troubleshooting:${NC}"
    echo "  • Check Ollama is running: ollama serve"
    echo "  • Install required models: ollama pull qwen2.5-coder:7b"
    echo "  • Install Continue extension in VSCode"
    echo "  • Check config: ~/.continue/config.json"
    exit 1
fi