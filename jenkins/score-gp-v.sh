#!/bin/bash
# ================================================================
# AUTOMATED GRADER: DEPLOY OTOMATIS PIPELINE (LAB 82)
# Total Max Score: 100 Pts
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
    echo -e "    \e[33m└─> Alasan: $reason\e[0m"
}

echo "================================================="
echo "  GRADER: DEPLOY OTOMATIS PIPELINE (LAB 82)"
echo "================================================="
echo

# 1. CEK USER DEPLOY & KEANGGOTAAN GRUP DOCKER (25 Pts)
echo -n "Step 1: Memeriksa user 'deploy' dan akses grup docker (25 pts)..."
USER_EXISTS=$(id "deploy" &>/dev/null && echo "yes" || echo "no")
IN_DOCKER=$(groups deploy 2>/dev/null | grep -qw "docker" && echo "yes" || echo "no")

if [ "$USER_EXISTS" = "yes" ] && [ "$IN_DOCKER" = "yes" ]; then
    pass_check 25
else
    fail_check "User 'deploy' belum dibuat atau belum tergabung dalam grup 'docker'."
fi

# 2. CEK FOLDER DEPLOY & BERKAS COMPOSE.YAML (25 Pts)
echo -n "Step 2: Memeriksa folder /home/deploy/simple-app dan compose.yaml (25 pts)..."
COMPOSE_PATH="/home/deploy/simple-app/compose.yaml"
if [ -f "$COMPOSE_PATH" ]; then
    pass_check 25
else
    fail_check "Berkas konfigurasi $COMPOSE_PATH tidak ditemukan."
fi

# 3. CEK STATUS CONTAINER 'simple-app' BERJALAN AKTIF (30 Pts)
echo -n "Step 3: Memeriksa status container 'simple-app' aktif (30 pts)..."
APP_RUNNING=$(docker inspect -f '{{.State.Running}}' simple-app 2>/dev/null || echo "false")

if [ "$APP_RUNNING" = "true" ]; then
    pass_check 30
else
    fail_check "Container 'simple-app' tidak berjalan di server aplikasi."
fi

# 4. CEK RESPON HTTP APLIKASI PADA PORT 3000 (20 Pts)
echo -n "Step 4: Memeriksa respons layanan aplikasi pada http://localhost:3000 (20 pts)..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "000")

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "304" ]; then
    pass_check 20
else
    fail_check "Aplikasi di port 3000 tidak merespons dengan benar (HTTP status: $HTTP_STATUS)."
fi

# Limit Max Score 100
[ "$score" -gt 100 ] && score=100

echo
echo "================================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Total Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Total Score: $score/100\e[0m"
    status="FAIL"
fi
echo "================================================="

# Menulis Luaran JSON untuk Sistem Scoring Lab
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-jenkins-pipeline-deploy-ch82",
  "score": $score,
  "status": "$status"
}
EOF
