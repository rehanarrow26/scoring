#!/bin/bash
# ================================================================
# AUTOMATED GRADER: CHAPTER 53 (LABEL - METADATA IMAGE)
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
echo "  GRADER: CHAPTER 53 (LABEL - METADATA IMAGE)"
echo "================================================="
echo

# 1. CEK DEKLARASI LABEL PADA DOCKERFILE (25 POIN)
echo -n "Step 1: Memeriksa instruksi LABEL pada Dockerfile (25 pts)..."
if [ -f "$DOCKERFILE" ]; then
    HAS_AUTHORS=$(grep -E "^\s*LABEL\s+org\.opencontainers\.image\.authors=" "$DOCKERFILE" || echo "")
    HAS_VERSION=$(grep -E "^\s*LABEL\s+org\.opencontainers\.image\.version=" "$DOCKERFILE" || echo "")
    HAS_EMAIL=$(grep -E "^\s*LABEL\s+maintainer\.email=" "$DOCKERFILE" || echo "")

    if [ -n "$HAS_AUTHORS" ] && [ -n "$HAS_VERSION" ] && [ -n "$HAS_EMAIL" ]; then
        pass_check 25
    else
        fail_check "Dockerfile belum menyertakan LABEL 'org.opencontainers.image.authors', 'version', atau 'maintainer.email'."
    fi
else
    fail_check "Berkas $DOCKERFILE tidak ditemukan."
fi

# 2. CEK METADATA LABELS PADA IMAGE (25 POIN)
echo -n "Step 2: Memeriksa keberadaan metadata Labels pada image sederhana:latest (25 pts)..."
IMAGE_EXISTS=$(docker images -q sederhana:latest 2>/dev/null || echo "")

if [ -n "$IMAGE_EXISTS" ]; then
    LABELS_JSON=$(docker inspect sederhana:latest --format '{{json .Config.Labels}}' 2>/dev/null || echo "")
    if [[ "$LABELS_JSON" == *"Tim Sysadmin SMK"* ]] && [[ "$LABELS_JSON" == *"sysadmin@smk-training.local"* ]]; then
        pass_check 25
    else
        fail_check "Metadata Labels pada image sederhana:latest tidak memuat nilai yang sesuai."
    fi
else
    fail_check "Image sederhana:latest belum dibangun."
fi

# 3. CEK DOCKER IMAGE FILTERING BERDASARKAN LABEL (25 POIN)
echo -n "Step 3: Memeriksa kemampuan filtering image berdasarkan LABEL (25 pts)..."
FILTER_OUT=$(docker image ls --filter "label=org.opencontainers.image.authors=Tim Sysadmin SMK" -q 2>/dev/null || echo "")

if [ -n "$FILTER_OUT" ]; then
    pass_check 25
else
    fail_check "Perintah 'docker image ls --filter label=...' tidak menemukan image sederhana:latest."
fi

# 4. CEK OPERASIONAL WEB SERVER (25 POIN)
echo -n "Step 4: Memastikan LABEL tidak mengganggu operasional container (25 pts)..."
TEST_CONTAINER="grader-label-check"
docker stop "$TEST_CONTAINER" 2>/dev/null || true
docker rm "$TEST_CONTAINER" 2>/dev/null || true

docker run -d --name "$TEST_CONTAINER" -p 8080:8080 sederhana:latest >/dev/null 2>&1
sleep 2

CURL_OUT=$(curl -s http://localhost:8080 || echo "")
docker stop "$TEST_CONTAINER" >/dev/null 2>&1 || true
docker rm "$TEST_CONTAINER" >/dev/null 2>&1 || true

if [[ "$CURL_OUT" == *"Selamat datang di Sistem Pelatihan SMK"* ]]; then
    pass_check 25
else
    fail_check "Aplikasi web server gagal merespons dengan benar."
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
  "chapter_id": "lab-docker-label-ch53",
  "score": $score,
  "status": "$status"
}
EOF
