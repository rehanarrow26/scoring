#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 46 (Dockerfile FROM & RUN)
# Total Max Score: 100 Pts
# ================================================================

clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"

score=0

pass_check() {
    echo -e "\e[32m[PASS]\e[0m $2"
    score=$((score + $1))
}

fail_check() {
    local reason="$1"
    echo -e "\e[31m[FAIL]\e[0m $reason"
}

echo "================================================="
echo "  GRADER: LAB 46 (DOCKERFILE FROM & RUN)"
echo "================================================="
echo

# 1. CEK DIREKTORI & DOCKERFILE
echo "Step 1: Memeriksa direktori /root/images dan berkas Dockerfile..."
if [ -d "/root/images" ] && [ -f "/root/images/Dockerfile" ]; then
    pass_check 25 "Direktori /root/images dan Dockerfile ditemukan."
else
    fail_check "Direktori /root/images atau /root/images/Dockerfile tidak ditemukan."
fi

# 2. CEK SINTAKS DOCKERFILE
echo "Step 2: Memeriksa isi Dockerfile..."
if [ -f "/root/images/Dockerfile" ]; then
    HAS_FROM=$(grep -i "FROM alpine:latest" /root/images/Dockerfile || true)
    HAS_RUN_MKDIR=$(grep -i "RUN mkdir data" /root/images/Dockerfile || true)
    HAS_RUN_ECHO=$(grep -i "RUN echo" /root/images/Dockerfile | grep -i "data/baca.txt" || true)

    if [ -n "$HAS_FROM" ] && [ -n "$HAS_RUN_MKDIR" ] && [ -n "$HAS_RUN_ECHO" ]; then
        pass_check 25 "Instruksi FROM dan RUN pada Dockerfile sesuai."
    else
        fail_check "Instruksi di dalam Dockerfile belum sesuai dengan instruksi modul."
    fi
else
    fail_check "Dockerfile tidak dapat dibaca."
fi

# 3. CEK KETERSEDIAAN DOCKER IMAGE
echo "Step 3: Memeriksa keberadaan image 'sederhana:latest'..."
IMAGE_EXISTS=$(docker images -q sederhana:latest 2>/dev/null || true)
if [ -n "$IMAGE_EXISTS" ]; then
    pass_check 25 "Docker image 'sederhana:latest' ditemukan."
else
    fail_check "Docker image 'sederhana:latest' tidak ditemukan di local registry."
fi

# 4. CEK EKSEKUSI CONTAINER
echo "Step 4: Menguji eksekusi berkas data/baca.txt di dalam container..."
if [ -n "$IMAGE_EXISTS" ]; then
    OUTPUT=$(docker run --rm sederhana:latest cat data/baca.txt 2>/dev/null || echo "")
    if echo "$OUTPUT" | grep -q "Pelatihan Cloud Native"; then
        pass_check 25 "Konten 'data/baca.txt' berhasil diverifikasi ($OUTPUT)."
    else
        fail_check "Output kontainer tidak sesuai (Diharapkan: 'Pelatihan Cloud Native', Hasil: '$OUTPUT')."
    fi
else
    fail_check "Image tidak ada, pengujian kontainer dilewati."
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

# Menuliskan luaran JSON
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-dockerfile-ch46",
  "score": $score,
  "status": "$status"
}
EOF
