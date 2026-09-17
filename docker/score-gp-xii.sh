#!/bin/bash
# ================================================================
# AUTOMATED GRADER: CHAPTER 49 (ARG INSTRUCTION)
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
echo "  GRADER: CHAPTER 49 (ARG INSTRUCTION)"
echo "================================================="
echo

# 1. CEK DEKLARASI ARG PADA DOCKERFILE (25 POIN)
echo -n "Step 1: Memeriksa instruksi ARG (BUILD_ENV & APP_VERSION_BUILD) pada Dockerfile (25 pts)..."
if [ -f "$DOCKERFILE" ]; then
    HAS_ARG_ENV=$(grep -E "^\s*ARG\s+BUILD_ENV" "$DOCKERFILE" || echo "")
    HAS_ARG_VER=$(grep -E "^\s*ARG\s+APP_VERSION_BUILD" "$DOCKERFILE" || echo "")
    # Menggunakan regex aman tanpa trailing backslash
    HAS_ENV_PASS=$(grep -E "ENV\s+APP_VERSION\s*=\s*\"?\\\${?APP_VERSION_BUILD}?\"?" "$DOCKERFILE" || echo "")

    if [ -n "$HAS_ARG_ENV" ] && [ -n "$HAS_ARG_VER" ] && [ -n "$HAS_ENV_PASS" ]; then
        pass_check 25
    else
        fail_check "Dockerfile tidak memuat ARG BUILD_ENV, ARG APP_VERSION_BUILD, atau penerusan ENV APP_VERSION=\$APP_VERSION_BUILD."
    fi
else
    fail_check "Berkas $DOCKERFILE tidak ditemukan."
fi

# 2. CEK IMAGE & ISI BUILD-INFO.TXT (25 POIN)
echo -n "Step 2: Memeriksa keberadaan image sederhana:latest & isi build-info.txt (25 pts)..."
IMAGE_EXISTS=$(docker images -q sederhana:latest 2>/dev/null || echo "")

if [ -n "$IMAGE_EXISTS" ]; then
    BUILD_INFO=$(docker run --rm --entrypoint cat sederhana:latest /data/build-info.txt 2>/dev/null || echo "")
    if [[ "$BUILD_INFO" == *"Build environment: development"* ]]; then
        pass_check 25
    else
        fail_check "Berkas build-info.txt tidak ditemukan atau isinya tidak sesuai ('$BUILD_INFO')."
    fi
else
    fail_check "Image sederhana:latest belum dibangun."
fi

# 3. MEMASTIKAN ARG BUILD_ENV TIDAK BOCOR KE RUNTIME CONFIG.ENV (25 POIN)
echo -n "Step 3: Memastikan ARG BUILD_ENV tidak bocor ke runtime Config.Env (25 pts)..."
ENV_INSPECT=$(docker inspect sederhana:latest --format '{{json .Config.Env}}' 2>/dev/null || echo "")

if [[ "$ENV_INSPECT" != *"BUILD_ENV"* ]]; then
    pass_check 25
else
    fail_check "ARG BUILD_ENV bocor dan tersimpan di Config.Env runtime."
fi

# 4. CEK PENERUSAN ARG KE ENV RUNTIME (25 POIN)
echo -n "Step 4: Memeriksa penerusan ARG APP_VERSION_BUILD ke ENV APP_VERSION pada runtime (25 pts)..."
if [[ "$ENV_INSPECT" == *"APP_VERSION=1.0"* ]]; then
    pass_check 25
else
    fail_check "ENV APP_VERSION=1.0 tidak ditemukan pada Config.Env runtime."
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
  "chapter_id": "lab-docker-arg-ch49",
  "score": $score,
  "status": "$status"
}
EOF
