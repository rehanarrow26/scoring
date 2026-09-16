#!/bin/bash
# ================================================================
# AUTOMATED GRADER: CHAPTER 53 (EXPOSE)
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
echo "  GRADER: CHAPTER 53 (EXPOSE)"
echo "================================================="
echo

# 1. CEK KEBERADAAN DAN STRUKTUR DOCKERFILE (25 POIN)
echo -n "Step 1: Memeriksa instruksi EXPOSE 8080 pada Dockerfile (25 pts)..."
if [ -f "$DOCKERFILE" ]; then
    HAS_EXPOSE=$(grep -E "^\s*EXPOSE\s+8080" "$DOCKERFILE" || echo "")
    HAS_HTTPD=$(grep -E "busybox-extras" "$DOCKERFILE" || echo "")

    if [ -n "$HAS_EXPOSE" ] && [ -n "$HAS_HTTPD" ]; then
        pass_check 25
    else
        fail_check "Dockerfile tidak memiliki instruksi 'EXPOSE 8080' atau instalasi 'busybox-extras'."
    fi
else
    fail_check "Berkas $DOCKERFILE tidak ditemukan."
fi

# 2. CEK KEBERADAAN IMAGE & METADATA EXPOSE (25 POIN)
echo -n "Step 2: Memeriksa metadata ExposedPorts pada image sederhana:latest (25 pts)..."
IMAGE_EXISTS=$(docker images -q sederhana:latest 2>/dev/null || echo "")

if [ -n "$IMAGE_EXISTS" ]; then
    EXPOSED_META=$(docker inspect sederhana:latest --format '{{.Config.ExposedPorts}}' 2>/dev/null || echo "")
    if [[ "$EXPOSED_META" == *"8080/tcp"* ]]; then
        pass_check 25
    else
        fail_check "Metadata ExposedPorts pada image tidak memuat '8080/tcp' (Output: '$EXPOSED_META')."
    fi
else
    fail_check "Image sederhana:latest belum dibangun."
fi

# 3. CEK RUNTIME DENGAN BINDING PORT 8080 (25 POIN)
echo -n "Step 3: Memeriksa respon web server httpd via port binding (-p 8080:8080) (25 pts)..."
TEST_CONTAINER="grader-web-check"
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
    fail_check "Akses HTTP ke localhost:8080 gagal atau konten index.html tidak sesuai."
fi

# 4. CEK PEMAHAMAN SIFAT EXPOSE (TANPA PORT PUBLISH HARUS FAIL/CLOSED FROM HOST) (25 POIN)
echo -n "Step 4: Verifikasi bahwa EXPOSE saja tidak mem-publish port ke host (25 pts)..."
NOPORT_CONTAINER="grader-noport-check"
docker stop "$NOPORT_CONTAINER" 2>/dev/null || true
docker rm "$NOPORT_CONTAINER" 2>/dev/null || true

docker run -d --name "$NOPORT_CONTAINER" sederhana:latest >/dev/null 2>&1
sleep 2

FAIL_CURL=$(curl -s --connect-timeout 2 http://localhost:8080 || echo "FAILED")
docker stop "$NOPORT_CONTAINER" >/dev/null 2>&1 || true
docker rm "$NOPORT_CONTAINER" >/dev/null 2>&1 || true

if [ "$FAIL_CURL" = "FAILED" ]; then
    pass_check 25
else
    fail_check "Port 8080 terakses padahal container dijalankan tanpa flag -p / -P."
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
  "chapter_id": "lab-docker-expose-ch53",
  "score": $score,
  "status": "$status"
}
EOF
