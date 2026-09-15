#!/bin/bash
# ================================================================
# AUTOMATED GRADER: CHAPTER 46 - DOCKERFILE ASSESSMENT
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
echo "  GRADER: CHAPTER 46 DOCKERFILE ASSESSMENT"
echo "================================================="
echo

# 1. CEK DIREKTORI DAN FILE DOCKERFILE (25 POIN)
echo -n "Step 1: Checking Directory 'images' and 'Dockerfile' (25 pts)..."
DOCKERFILE_PATH=""

# Daftar lokasi pencarian file Dockerfile (termasuk path lengkap ~/images)
SEARCH_PATHS=(
    "images/Dockerfile"
    "images/dockerfile"
    "Dockerfile"
    "dockerfile"
    "$HOME/images/Dockerfile"
    "$HOME/images/dockerfile"
)

for path in "${SEARCH_PATHS[@]}"; do
    if [ -f "$path" ]; then
        DOCKERFILE_PATH="$path"
        break
    fi
done

if [ -n "$DOCKERFILE_PATH" ]; then
    pass_check 25
else
    fail_check "File 'Dockerfile' tidak ditemukan di '~/images/Dockerfile' atau current path."
fi

# 2. CEK ISI DOCKERFILE (25 POIN)
echo -n "Step 2: Validating Dockerfile Instructions (25 pts)..."
if [ -n "$DOCKERFILE_PATH" ]; then
    HAS_FROM=$(grep -E -i "^\s*FROM\s+alpine" "$DOCKERFILE_PATH" || echo "")
    HAS_MKDIR=$(grep -E -i "RUN\s+mkdir\s+data" "$DOCKERFILE_PATH" || echo "")
    HAS_ECHO=$(grep -E -i "Pelatihan Cloud Native" "$DOCKERFILE_PATH" || echo "")

    if [ -n "$HAS_FROM" ] && [ -n "$HAS_MKDIR" ] && [ -n "$HAS_ECHO" ]; then
        pass_check 25
    else
        fail_check "Instruksi di dalam $DOCKERFILE_PATH tidak sesuai dengan spesifikasi modul."
    fi
else
    fail_check "Dockerfile tidak ditemukan."
fi

# 3. CEK KEBERADAAN DOCKER IMAGE (25 POIN)
echo -n "Step 3: Checking Docker Image 'sederhana:latest' (25 pts)..."
IMAGE_EXISTS=$(docker image inspect sederhana:latest 2>/dev/null || echo "")

if [ -n "$IMAGE_EXISTS" ]; then
    pass_check 25
else
    fail_check "Docker image 'sederhana:latest' belum dibuild atau tidak ditemukan."
fi

# 4. CEK OUTPUT CONTAINER RUN (25 POIN)
echo -n "Step 4: Testing Container Execution & Content Output (25 pts)..."
if [ -n "$IMAGE_EXISTS" ]; then
    OUTPUT=$(docker run --rm sederhana:latest cat data/baca.txt 2>/dev/null || echo "")
    if [[ "$OUTPUT" == *"Pelatihan Cloud Native"* ]]; then
        pass_check 25
    else
        fail_check "Isi file 'data/baca.txt' di dalam container tidak cocok (Ekspektasi: 'Pelatihan Cloud Native')."
    fi
else
    fail_check "Tidak dapat menguji container karena image tidak ditemukan."
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
  "chapter_id": "lab-docker-chapter-46",
  "score": $score,
  "status": "$status"
}
EOF
