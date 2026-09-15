#!/bin/bash
# ================================================================
# AUTOMATED GRADER: CHAPTER 47 - CMD VS ENTRYPOINT ASSESSMENT
# Total Max Score: 100 Pts
# ================================================================

clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"
WORK_DIR="$HOME/images"

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
echo "  GRADER: CHAPTER 47 DOCKERFILE ASSESSMENT"
echo "================================================="
echo

# 1. CEK DIREKTORI ~/images DAN DOCKERFILE (25 POIN)
echo -n "Step 1: Checking Directory '$WORK_DIR' and 'Dockerfile' (25 pts)..."
if [ -d "$WORK_DIR" ] && [ -f "$WORK_DIR/Dockerfile" ]; then
    cd "$WORK_DIR"
    pass_check 25
else
    fail_check "Direktori '$WORK_DIR' atau file '$WORK_DIR/Dockerfile' tidak ditemukan."
fi

# 2. CEK ISI DOCKERFILE (25 POIN)
echo -n "Step 2: Validating ENTRYPOINT and CMD pattern in Dockerfile (25 pts)..."
if [ -f "$WORK_DIR/Dockerfile" ]; then
    HAS_ENTRYPOINT=$(grep -E -i 'ENTRYPOINT\s+\[\s*"cat"\s*\]' "$WORK_DIR/Dockerfile" || echo "")
    HAS_CMD=$(grep -E -i 'CMD\s+\[\s*"data/baca.txt"\s*\]' "$WORK_DIR/Dockerfile" || echo "")
    HAS_CADANGAN=$(grep -E "Ini adalah data cadangan" "$WORK_DIR/Dockerfile" || echo "")

    if [ -n "$HAS_ENTRYPOINT" ] && [ -n "$HAS_CMD" ] && [ -n "$HAS_CADANGAN" ]; then
        pass_check 25
    else
        fail_check "Dockerfile belum dikonfigurasi dengan pola ENTRYPOINT ['cat'] dan CMD ['data/baca.txt']."
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

# 4. CEK EXECUTION DENGAN DEFAULT DAN OVERRIDDEN CMD (25 POIN)
echo -n "Step 4: Testing Container Default & Overridden Arguments (25 pts)..."
if [ -n "$IMAGE_EXISTS" ]; then
    DEFAULT_OUT=$(docker run --rm sederhana:latest 2>/dev/null || echo "")
    OVERRIDE_OUT=$(docker run --rm sederhana:latest data/cadangan.txt 2>/dev/null || echo "")

    if [[ "$DEFAULT_OUT" == *"Pelatihan Cloud Native"* ]] && [[ "$OVERRIDE_OUT" == *"Ini adalah data cadangan"* ]]; then
        pass_check 25
    else
        fail_check "Output container tidak sesuai ketika diuji dengan argumen default dan argumen cadangan."
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
  "chapter_id": "lab-docker-chapter-47",
  "score": $score,
  "status": "$status"
}
EOF
