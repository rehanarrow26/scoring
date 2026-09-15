#!/bin/bash
# ================================================================
# AUTOMATED GRADER: CHAPTER 48 - COPY VS ADD ASSESSMENT
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
echo "  GRADER: CHAPTER 48 COPY VS ADD ASSESSMENT"
echo "================================================="
echo

# 1. CEK DIREKTORI ~/images, HOST FILES, DAN DOCKERFILE (25 POIN)
echo -n "Step 1: Checking Workspace Files in '$WORK_DIR' (25 pts)..."
if [ -d "$WORK_DIR" ] && [ -f "$WORK_DIR/Dockerfile" ] && [ -f "$WORK_DIR/host-info.txt" ] && [ -f "$WORK_DIR/extra.tar.gz" ]; then
    cd "$WORK_DIR"
    pass_check 25
else
    fail_check "Direktori '$WORK_DIR', 'Dockerfile', 'host-info.txt', atau 'extra.tar.gz' tidak lengkap."
fi

# 2. CEK INSTRUKSI COPY DAN ADD DI DOCKERFILE (25 POIN)
echo -n "Step 2: Validating COPY and ADD instructions in Dockerfile (25 pts)..."
if [ -f "$WORK_DIR/Dockerfile" ]; then
    HAS_COPY=$(grep -E -i 'COPY\s+host-info\.txt\s+/data/host-info\.txt' "$WORK_DIR/Dockerfile" || grep -E -i 'COPY\s+host-info\.txt\s+/data/' "$WORK_DIR/Dockerfile" || echo "")
    HAS_ADD=$(grep -E -i 'ADD\s+extra\.tar\.gz\s+/data/' "$WORK_DIR/Dockerfile" || echo "")

    if [ -n "$HAS_COPY" ] && [ -n "$HAS_ADD" ]; then
        pass_check 25
    else
        fail_check "Dockerfile belum dikonfigurasi dengan instruksi COPY host-info.txt dan ADD extra.tar.gz."
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

# 4. CEK HASIL EKSEKUSI CONTAINER (COPY & ADD EXTRACTION) (25 POIN)
echo -n "Step 4: Testing Container Copy & Add Extraction Output (25 pts)..."
if [ -n "$IMAGE_EXISTS" ]; then
    COPY_OUT=$(docker run --rm sederhana:latest data/host-info.txt 2>/dev/null || echo "")
    ADD_OUT=$(docker run --rm sederhana:latest data/extra/catatan.txt 2>/dev/null || echo "")

    if [[ "$COPY_OUT" == *"Dibuat oleh Tim Sysadmin SMK"* ]] && [[ "$ADD_OUT" == *"Berkas hasil ekstraksi otomatis"* ]]; then
        pass_check 25
    else
        fail_check "Output file hasil COPY (/data/host-info.txt) atau hasil ADD (/data/extra/catatan.txt) tidak sesuai."
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
  "chapter_id": "lab-docker-chapter-48",
  "score": $score,
  "status": "$status"
}
EOF
