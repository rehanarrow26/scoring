#!/bin/bash

clear

API_URL="https://lms.teknolojia.my.id/api/lab/finish"
CHAPTER_ID=9

LAB_DIR="$HOME/.lab"

TOKEN_FILE="$LAB_DIR/token"
START_FILE="$LAB_DIR/start_time"
RESULT_FILE="$LAB_DIR/result.json"

RESPONSE_FILE="/tmp/lab_finish_response.json"

echo "========================================="
echo "        LAB FINISH - DNS REVERSE"
echo "              CHAPTER 9"
echo "========================================="
echo

if [ ! -f "$TOKEN_FILE" ]; then
    echo "Session tidak ditemukan."
    echo "Jalankan lab-start.sh terlebih dahulu."
    exit 1
fi

if [ ! -f "$START_FILE" ]; then
    echo "Start time tidak ditemukan."
    exit 1
fi

if [ ! -f "$RESULT_FILE" ]; then
    echo "Hasil scoring belum ditemukan."
    echo
    echo "Jalankan:"
    echo "bash score.sh"
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

START_TIME=$(cat "$START_FILE")
END_TIME=$(date +%s)

DURATION=$((END_TIME - START_TIME))

SCORE=$(jq -r '.score' "$RESULT_FILE")
STATUS=$(jq -r '.status' "$RESULT_FILE")
DETAIL=$(jq -c '.detail' "$RESULT_FILE")

echo "Score    : $SCORE / 100"
echo "Status   : $STATUS"
echo "Duration : $DURATION seconds"
echo

PAYLOAD=$(jq -n \
    --argjson chapter "$CHAPTER_ID" \
    --argjson score "$SCORE" \
    --argjson duration "$DURATION" \
    --arg status "$STATUS" \
    --argjson detail "$DETAIL" \
    '{
        chapter_id: $chapter,
        score: $score,
        duration: $duration,
        status: $status,
        detail: $detail
    }')

echo "Mengirim hasil ke LMS..."
echo

HTTP_CODE=$(curl \
    -sS \
    -o "$RESPONSE_FILE" \
    -w "%{http_code}" \
    -X POST "$API_URL" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then

    echo "========================================="
    echo "          SUBMIT BERHASIL"
    echo "========================================="
    echo

    cat "$RESPONSE_FILE"

    rm -f "$TOKEN_FILE"
    rm -f "$START_FILE"
    rm -f "$RESULT_FILE"

    echo
    echo
    echo "Session berhasil ditutup."

else

    echo "========================================="
    echo "           SUBMIT GAGAL"
    echo "========================================="
    echo

    cat "$RESPONSE_FILE"

    echo
    echo "HTTP Code : $HTTP_CODE"
    echo
    echo "Session masih disimpan."
    echo "Silakan jalankan lab-finish.sh kembali."

fi

rm -f "$RESPONSE_FILE"

echo
