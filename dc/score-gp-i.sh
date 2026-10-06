#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 68 (DOCKER COMPOSE BASIC MANAGEMENT)
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
echo "  GRADER: LAB 68 (DOCKER COMPOSE BASIC MANAGEMENT)"
echo "================================================="
echo

# 1. CEK DIREKTORI KERJA & COMPOSE.YAML (25 Pts)
echo -n "Step 1: Memeriksa Direktori /root/compose/container & compose.yaml (25 pts)..."
TARGET_DIR="/root/compose/container"
COMPOSE_FILE="$TARGET_DIR/compose.yaml"

if [ -d "$TARGET_DIR" ] && [ -f "$COMPOSE_FILE" ]; then
    pass_check 25
else
    fail_check "Direktori '$TARGET_DIR' atau berkas '$COMPOSE_FILE' tidak ditemukan."
fi

# 2. CEK ISI CONFIGURATION COMPOSE.YAML (25 Pts)
echo -n "Step 2: Memeriksa Konfigurasi Service & Image pada compose.yaml (25 pts)..."
if [ -f "$COMPOSE_FILE" ]; then
    # Cek apakah nama container dan image nginx dikonfigurasi
    CONTAINER_NAME_OK=$(grep -E '^[[:space:]]*container_name:[[:space:]]*nginx-contoh' "$COMPOSE_FILE" >/dev/null && echo "yes" || echo "no")
    IMAGE_OK=$(grep -E '^[[:space:]]*image:[[:space:]]*nginx' "$COMPOSE_FILE" >/dev/null && echo "yes" || echo "no")
    PORT_OK=$(grep -E '80:80' "$COMPOSE_FILE" >/dev/null && echo "yes" || echo "no")

    if [ "$CONTAINER_NAME_OK" = "yes" ] && [ "$IMAGE_OK" = "yes" ] && [ "$PORT_OK" = "yes" ]; then
        pass_check 25
    else
        REASON=""
        [ "$CONTAINER_NAME_OK" = "no" ] && REASON="container_name 'nginx-contoh' tidak ditemukan. "
        [ "$IMAGE_OK" = "no" ] && REASON="${REASON}image 'nginx' tidak dikonfigurasi. "
        [ "$PORT_OK" = "no" ] && REASON="${REASON}pemetaan port '80:80' tidak sesuai."
        fail_check "$REASON"
    fi
else
    fail_check "Berkas $COMPOSE_FILE tidak dapat dibaca."
fi

# 3. CEK CONTAINER DOCKER BERJALAN (25 Pts)
echo -n "Step 3: Memeriksa Container 'nginx-contoh' sedang Berjalan (25 pts)..."
CONTAINER_STATUS=$(docker inspect -f '{{.State.Running}}' nginx-contoh 2>/dev/null || echo "false")

if [ "$CONTAINER_STATUS" = "true" ]; then
    pass_check 25
else
    fail_check "Container 'nginx-contoh' tidak dalam kondisi berjalan (Running)."
fi

# 4. CEK RESPON HTTP NGINX VIA CURL (25 Pts)
echo -n "Step 4: Memeriksa Respons Web Service (curl localhost) (25 pts)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")

if [ "$HTTP_CODE" -eq 200 ]; then
    pass_check 25
else
    fail_check "Pengujian web ke http://localhost/ gagal atau tidak merespon HTTP 200 (Respon: $HTTP_CODE)."
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
  "chapter_id": "lab-docker-compose-basic-ch68",
  "score": $score,
  "status": "$status"
}
EOF
