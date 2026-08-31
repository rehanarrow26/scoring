#!/bin/bash
# ================================================================
# DOCKER ENGINE CHECKER (ROBUST & PACKAGE-AGNOSTIC)
# CHAPTER 22
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

echo "========================================="
echo "     DOCKER CHECKER - CH 22"
echo "========================================="
echo

# 1. Cek Service Docker (25 Poin)
echo -n "Checking Docker Daemon Service Status..............."
if systemctl is-active --quiet docker; then
    pass_check 25
else
    fail_check "Service Docker tidak aktif."
fi

# 2. Cek Perintah 'docker info' (25 Poin)
echo -n "Checking Docker Engine Functionality..............."
if docker info >/dev/null 2>&1; then
    pass_check 25
else
    fail_check "Docker Engine tidak merespon perintah 'docker info'."
fi

# 3. Cek Fitur Buildx (25 Poin)
echo -n "Checking Docker Buildx Plugin Availability........."
if docker buildx version >/dev/null 2>&1; then
    pass_check 25
else
    fail_check "Plugin 'docker buildx' tidak ditemukan/belum terinstal."
fi

# 4. Cek Fitur Docker Compose (25 Poin)
echo -n "Checking Docker Compose Plugin Availability........"
if docker compose version >/dev/null 2>&1; then
    pass_check 25
else
    fail_check "Plugin 'docker compose' tidak ditemukan/belum terinstal."
fi

# Limit Score Max 100
[ "$score" -gt 100 ] && score=100

echo
echo "========================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Score: $score/100\e[0m"
    status="FAIL"
fi
echo "========================================="

cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": 22,
  "score": $score,
  "status": "$status"
}
EOF
