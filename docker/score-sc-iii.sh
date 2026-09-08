#!/bin/bash
# ================================================================
# SCORING SCRIPT: STUDI KASUS DOCKER BIND MOUNTS (CHAPTER 37)
# ================================================================

clear

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"

score=0

pass_check() {
    echo -e "\e[32m[PASS]\e[0m"
    score=$((score + $1))
}

fail_check() {
    local reason="$1"
    echo -e "\e[31m[FAIL]\e[0m"
    echo -e "   \e[33m└─> Alasan: $reason\e[0m"
}

echo "================================================="
echo "  GRADER: STUDI KASUS DOCKER BIND MOUNTS (LAB 37)"
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK STUDI KASUS 1 (25 POIN)
# ------------------------------------------------------------------
echo -n "1. Testing Case 1: Live Editing Container (nginx-live-edit) (25 pts)..."
CONTENT_CASE1=$(curl -s http://127.0.0.1:8080 2>/dev/null || echo "")

if docker ps --format '{{.Names}}' | grep -q "^nginx-live-edit$" && [ -n "$CONTENT_CASE1" ]; then
    pass_check 25
else
    fail_check "Container 'nginx-live-edit' tidak berjalan atau port 8080 tidak dapat diakses."
fi

# ------------------------------------------------------------------
# 2. CEK STUDI KASUS 2 - CONTAINER STATUS (25 POIN)
# ------------------------------------------------------------------
echo -n "2. Testing Case 2: Multi-Container Setup Status (25 pts)..."
if docker ps --format '{{.Names}}' | grep -q "^nginx-node-a$" && docker ps --format '{{.Names}}' | grep -q "^nginx-node-b$"; then
    pass_check 25
else
    fail_check "Container 'nginx-node-a' atau 'nginx-node-b' tidak sedang berjalan."
fi

# ------------------------------------------------------------------
# 3. CEK STUDI KASUS 2 - KONSISTENSI KONTEN (25 POIN)
# ------------------------------------------------------------------
echo -n "3. Testing Case 2: Shared Content Consistency Check (25 pts)..."
RESP_A=$(curl -s http://127.0.0.1:8081 2>/dev/null | xargs)
RESP_B=$(curl -s http://127.0.0.1:8082 2>/dev/null | xargs)

if [ -n "$RESP_A" ] && [ "$RESP_A" = "$RESP_B" ]; then
    pass_check 25
else
    fail_check "Konten dari port 8081 dan 8082 tidak cocok atau gagal diakses."
fi

# ------------------------------------------------------------------
# 4. CEK STUDI KASUS 3 - READ-ONLY MOUNT PROTECTION (25 POIN)
# ------------------------------------------------------------------
echo -n "4. Testing Case 3: Read-Only Mount Enforcement (25 pts)..."
IS_READONLY=$(docker inspect app-readonly-test --format '{{range .Mounts}}{{if eq .Destination "/etc/appconfig"}}{{.RW}}{{end}}{{end}}' 2>/dev/null)

# .RW harus 'false' jika mount bertipe Read-Only
if [ "$IS_READONLY" = "false" ]; then
    # Uji coba penulisan langsung di dalam container
    WRITE_TEST=$(docker exec app-readonly-test sh -c "echo 'tampered' > /etc/appconfig/config.txt" 2>&1)
    if [[ "$WRITE_TEST" == *"Read-only file system"* ]]; then
        pass_check 25
    else
        fail_check "Proteksi penulisan gagal, file di /etc/appconfig dapat diubah."
    fi
else
    fail_check "Mount ke '/etc/appconfig' tidak terkonfigurasi sebagai Read-Only (readonly)."
fi

# Limit Score Max 100
[ "$score" -gt 100 ] && score=100

echo
echo "================================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Score: $score/100\e[0m"
    status="FAIL"
fi
echo "================================================="

# Simpan hasil penilaian JSON untuk LMS
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-37-docker-bind-mounts-cases",
  "score": $score,
  "status": "$status"
}
EOF
