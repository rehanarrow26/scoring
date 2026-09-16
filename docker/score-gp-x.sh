#!/bin/bash
# ================================================================
# AUTOMATED GRADER: CHAPTER 49 (WORKDIR & ENV)
# Total Max Score: 100 Pts
# ================================================================

clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"
TARGET_DIR="/root/images"
DOCKERFILE="$TARGET_DIR/Dockerfile"

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
echo "  GRADER: CHAPTER 49 (WORKDIR & ENV)"
echo "================================================="
echo

# 1. CEK KEBERADAAN DAN STRUKTUR DOCKERFILE (25 POIN)
echo -n "Step 1: Memeriksa struktur Dockerfile (/root/images/Dockerfile) (25 pts)..."
if [ -f "$DOCKERFILE" ]; then
    HAS_WORKDIR=$(grep -E "^\s*WORKDIR\s+/data" "$DOCKERFILE" || echo "")
    HAS_ENV_NAME=$(grep -E "^\s*ENV\s+APP_NAME=" "$DOCKERFILE" || echo "")
    HAS_ENV_VER=$(grep -E "^\s*ENV\s+APP_VERSION=" "$DOCKERFILE" || echo "")

    if [ -n "$HAS_WORKDIR" ] && [ -n "$HAS_ENV_NAME" ] && [ -n "$HAS_ENV_VER" ]; then
        pass_check 25
    else
        fail_check "Dockerfile tidak memiliki instruksi WORKDIR /data atau ENV (APP_NAME & APP_VERSION) yang sesuai."
    fi
else
    fail_check "Berkas $DOCKERFILE tidak ditemukan."
fi

# 2. CEK KEBERADAAN DOCKER IMAGE (25 POIN)
echo -n "Step 2: Memeriksa keberadaan image sederhana:latest (25 pts)..."
IMAGE_EXISTS=$(docker images -q sederhana:latest 2>/dev/null || echo "")

if [ -n "$IMAGE_EXISTS" ]; then
    pass_check 25
else
    fail_check "Image sederhana:latest belum dibangun."
fi

# 3. CEK INTEGRITAS WORKDIR PADA CONTAINER RUNTIME (25 POIN)
echo -n "Step 3: Memeriksa WORKDIR runtime (/data) saat container berjalan (25 pts)..."
PWD_OUT=$(docker run --rm --entrypoint pwd sederhana:latest 2>/dev/null | tr -d '\r' || echo "")

if [ "$PWD_OUT" = "/data" ]; then
    pass_check 25
else
    fail_check "Working directory container bukan /data (Hasil output: '$PWD_OUT')."
fi

# 4. CEK INTEGRITAS ENV PADA RUNTIME DAN ISI BERKAS (25 POIN)
echo -n "Step 4: Memeriksa isi berkas info-app.txt & Environment Variable runtime (25 pts)..."
INFO_OUT=$(docker run --rm sederhana:latest info-app.txt 2>/dev/null | tr -d '\r' || echo "")
ENV_OUT=$(docker run --rm --entrypoint sh sederhana:latest -c 'echo $APP_NAME' 2>/dev/null | tr -d '\r' || echo "")

EXPECTED_INFO="Aplikasi: Sistem Pelatihan SMK versi 1.0"
EXPECTED_ENV="Sistem Pelatihan SMK"

if [ "$INFO_OUT" = "$EXPECTED_INFO" ] && [ "$ENV_OUT" = "$EXPECTED_ENV" ]; then
    pass_check 25
else
    fail_check "Hasil output info-app.txt atau environment variable $APP_NAME tidak sesuai."
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
  "chapter_id": "lab-docker-workdir-env-ch49",
  "score": $score,
  "status": "$status"
}
EOF
