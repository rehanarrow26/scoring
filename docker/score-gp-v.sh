#!/bin/bash
# ================================================================
# SCORING SCRIPT: DOCKER BIND MOUNTS (CHAPTER 36)
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
echo "  GRADER: MANAJEMEN DOCKER BIND MOUNTS (LAB 36)  "
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK DIREKTORI & BERKAS HOST (25 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Host Directory & File 'data/belajar.txt' (25 pts)..."
if [ -f "data/belajar.txt" ] || [ -f "/root/data/belajar.txt" ]; then
    pass_check 25
else
    fail_check "Direktori 'data' atau berkas 'data/belajar.txt' tidak ditemukan di host."
fi

# ------------------------------------------------------------------
# 2. CEK STATUS CONTAINER DOCKER (25 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Container 'nginx-bind-mount' Running Status (25 pts)..."
if docker ps --format '{{.Names}}' | grep -q "^nginx-bind-mount$"; then
    pass_check 25
else
    fail_check "Container 'nginx-bind-mount' tidak ditemukan atau sedang tidak berjalan (stopped)."
fi

# ------------------------------------------------------------------
# 3. CEK SPESIFIKASI BIND MOUNT CONTAINER (25 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Bind Mount Configuration on Container (25 pts)..."
MOUNT_TYPE=$(docker inspect nginx-bind-mount --format '{{range .Mounts}}{{if eq .Destination "/mnt"}}{{.Type}}{{end}}{{end}}' 2>/dev/null)

if [ "$MOUNT_TYPE" = "bind" ]; then
    pass_check 25
else
    fail_check "Mount ke '/mnt' bukan bertipe 'bind' atau direktori tujuan '/mnt' tidak sesuai."
fi

# ------------------------------------------------------------------
# 4. CEK KONTEN BERKAS DI DALAM CONTAINER (25 POIN)
# ------------------------------------------------------------------
echo -n "4. Verifying File Content Inside Container (/mnt/belajar.txt) (25 pts)..."
FILE_CONTENT=$(docker exec nginx-bind-mount cat /mnt/belajar.txt 2>/dev/null | xargs)

if [[ "$FILE_CONTENT" == *"Belajar Cloud Native"* ]]; then
    pass_check 25
else
    fail_check "Isi berkas '/mnt/belajar.txt' di dalam container tidak cocok (Ekspektasi: 'Belajar Cloud Native')."
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
  "chapter_id": "lab-36-docker-bind-mounts",
  "score": $score,
  "status": "$status"
}
EOF
