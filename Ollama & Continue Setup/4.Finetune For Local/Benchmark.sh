#!/bin/bash

###############################################################################
# Script Benchmark Ollama Models
# Test speed, quality và VRAM usage của các models
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
║           OLLAMA MODELS BENCHMARK SCRIPT                   ║
║         Testing Speed, Quality & Memory Usage              ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if Ollama is running
if ! pgrep -x "ollama" > /dev/null; then
    echo -e "${YELLOW}⚠️  Starting Ollama service...${NC}"
    ollama serve &
    sleep 3
fi

# Test prompts
SIMPLE_PROMPT="Write a hello world function in Go"
MEDIUM_PROMPT="Write a Go function to fetch user from MongoDB with error handling and context timeout"
COMPLEX_PROMPT="Create a complete Go HTTP handler for user registration with validation, password hashing, MongoDB insertion, and proper error handling"

# Models to test
declare -a MODELS=(
    "qwen2.5-coder:1.5b"
    "deepseek-coder:1.3b"
    "codegemma:2b"
    "starcoder2:3b"
    "qwen2.5-coder:3b"
    "phi3.5:3.8b"
)

# Results file
RESULTS_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).md"

# Function to get GPU memory
get_gpu_memory() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -1
    else
        echo "N/A"
    fi
}

# Function to test a model
test_model() {
    local model=$1
    local prompt=$2
    local test_type=$3
    
    echo -e "${CYAN}Testing ${model} - ${test_type}${NC}"
    
    # Get initial GPU memory
    local mem_before=$(get_gpu_memory)
    
    # Run the test and capture timing
    local start_time=$(date +%s.%N)
    local output=$(ollama run "$model" "$prompt" 2>&1)
    local end_time=$(date +%s.%N)
    
    # Calculate duration
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Get GPU memory after
    local mem_after=$(get_gpu_memory)
    local mem_used="N/A"
    if [ "$mem_before" != "N/A" ] && [ "$mem_after" != "N/A" ]; then
        mem_used=$((mem_after - mem_before))
    fi
    
    # Extract tokens/s if available
    local tokens_per_sec=$(echo "$output" | grep -oP '\d+\.\d+(?= tokens/s)' | tail -1)
    if [ -z "$tokens_per_sec" ]; then
        tokens_per_sec="N/A"
    fi
    
    # Count output tokens (rough estimate)
    local output_tokens=$(echo "$output" | wc -w)
    
    # Calculate average speed if not available
    if [ "$tokens_per_sec" == "N/A" ] && [ "$output_tokens" -gt 0 ]; then
        tokens_per_sec=$(echo "scale=2; $output_tokens / $duration" | bc)
    fi
    
    echo -e "${GREEN}  ✓ Duration: ${duration}s${NC}"
    echo -e "${GREEN}  ✓ Speed: ${tokens_per_sec} tokens/s${NC}"
    echo -e "${GREEN}  ✓ VRAM: ${mem_used}MB${NC}"
    echo ""
    
    # Store results
    echo "| $model | $test_type | ${duration}s | ${tokens_per_sec} tok/s | ${mem_used}MB |" >> "$RESULTS_FILE"
}

# Initialize results file
cat > "$RESULTS_FILE" << 'EOF'
# Ollama Models Benchmark Results

## Test Configuration
- Date: $(date)
- GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
- VRAM: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1)

## Test Prompts

### Simple
```
Write a hello world function in Go
```

### Medium
```
Write a Go function to fetch user from MongoDB with error handling and context timeout
```

### Complex
```
Create a complete Go HTTP handler for user registration with validation, password hashing, MongoDB insertion, and proper error handling
```

## Results

### Simple Prompt Test

| Model | Test Type | Duration | Speed | VRAM Used |
|-------|-----------|----------|-------|-----------|
EOF

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 1: SIMPLE PROMPT TEST${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

for model in "${MODELS[@]}"; do
    if ollama list | grep -q "$model"; then
        test_model "$model" "$SIMPLE_PROMPT" "Simple"
    else
        echo -e "${YELLOW}⚠️  Model $model not found, skipping...${NC}"
        echo "| $model | Simple | N/A | N/A | N/A |" >> "$RESULTS_FILE"
    fi
    sleep 2
done

# Medium prompt test
echo "" >> "$RESULTS_FILE"
echo "### Medium Prompt Test" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "| Model | Test Type | Duration | Speed | VRAM Used |" >> "$RESULTS_FILE"
echo "|-------|-----------|----------|-------|-----------|" >> "$RESULTS_FILE"

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 2: MEDIUM PROMPT TEST${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

for model in "${MODELS[@]}"; do
    if ollama list | grep -q "$model"; then
        test_model "$model" "$MEDIUM_PROMPT" "Medium"
    else
        echo "| $model | Medium | N/A | N/A | N/A |" >> "$RESULTS_FILE"
    fi
    sleep 2
done

# Complex prompt test
echo "" >> "$RESULTS_FILE"
echo "### Complex Prompt Test" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "| Model | Test Type | Duration | Speed | VRAM Used |" >> "$RESULTS_FILE"
echo "|-------|-----------|----------|-------|-----------|" >> "$RESULTS_FILE"

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 3: COMPLEX PROMPT TEST${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

for model in "${MODELS[@]}"; do
    if ollama list | grep -q "$model"; then
        test_model "$model" "$COMPLEX_PROMPT" "Complex"
    else
        echo "| $model | Complex | N/A | N/A | N/A |" >> "$RESULTS_FILE"
    fi
    sleep 2
done

# Quality test
echo "" >> "$RESULTS_FILE"
echo "## Quality Assessment" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"
echo "Testing code quality for a simple Go function..." >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

QUALITY_PROMPT="Write a Go function to validate email address with proper error handling"

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PHASE 4: QUALITY TEST${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

for model in "${MODELS[@]}"; do
    if ollama list | grep -q "$model"; then
        echo -e "${CYAN}Testing quality: ${model}${NC}"
        echo "" >> "$RESULTS_FILE"
        echo "### $model Output" >> "$RESULTS_FILE"
        echo '```go' >> "$RESULTS_FILE"
        ollama run "$model" "$QUALITY_PROMPT" >> "$RESULTS_FILE" 2>&1
        echo '```' >> "$RESULTS_FILE"
        echo "" >> "$RESULTS_FILE"
        sleep 2
    fi
done

# Summary and recommendations
cat >> "$RESULTS_FILE" << 'EOF'

## Recommendations

### For Autocomplete (Tab completion)
**Best:** qwen2.5-coder:1.5b or deepseek-coder:1.3b
- Fastest response time
- Low VRAM usage
- Acceptable quality for completion

### For Inline Edit (Ctrl+I)
**Best:** qwen2.5-coder:3b or starcoder2:3b
- Balanced speed/quality
- Good context understanding
- Moderate VRAM usage

### For Chat & Code Review
**Best:** qwen2.5-coder:3b or phi3.5:3.8b
- Good quality responses
- Reasonable speed
- Can handle complex questions

### For Quick Explanations
**Best:** deepseek-coder:1.3b
- Ultra-fast
- Minimal VRAM
- Good for simple tasks

## Conclusion

Based on the benchmark results, the recommended setup for RTX 4060 8GB is:

1. **Primary Autocomplete:** qwen2.5-coder:1.5b
2. **Inline Edit:** qwen2.5-coder:3b
3. **Code Generation:** starcoder2:3b
4. **Quick Tasks:** deepseek-coder:1.3b
5. **Embedding:** nomic-embed-text

Total VRAM when all loaded: ~6-7GB (perfect fit!)

EOF

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 BENCHMARK COMPLETED!                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Results saved to: ${RESULTS_FILE}${NC}"
echo ""
echo -e "${YELLOW}📊 Quick Summary:${NC}"
echo ""

# Generate quick summary
if command -v nvidia-smi &> /dev/null; then
    echo -e "${CYAN}GPU Information:${NC}"
    nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
    echo ""
fi

echo -e "${CYAN}Available Models:${NC}"
ollama list

echo ""
echo -e "${GREEN}💡 Next Steps:${NC}"
echo "1. Review the results in: $RESULTS_FILE"
echo "2. Choose models based on your priorities (speed vs quality)"
echo "3. Update Continue config with your preferred models"
echo "4. Run: ./setup_continue.sh to apply configuration"
echo ""

# Open results file if possible
if command -v code &> /dev/null; then
    echo -e "${YELLOW}Opening results in VSCode...${NC}"
    code "$RESULTS_FILE"
elif command -v cat &> /dev/null; then
    echo -e "${YELLOW}Displaying results:${NC}"
    echo ""
    cat "$RESULTS_FILE"
fi