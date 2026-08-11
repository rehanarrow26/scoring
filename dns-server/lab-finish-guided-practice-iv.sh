#!/usr/bin/env bash

set -u

API_BASE="${LAB_API_URL_BASE:-https://lms.teknolojia.my.id}"

CHAPTER_ID=10

LAB_DIR="$HOME/.lab"

TOKEN_FILE="$LAB_DIR/token"
START_FILE="$LAB_DIR/start_time"

RESULT_FILE="result.json"

echo "========================================="
echo "      LAB FINISH - DNS REVERSE"
echo "              CHAPTER 10"
echo "========================================="
echo

if [ ! -f "$TOKEN_FILE" ]; then
    echo "Token tidak ditemukan."
    echo "Jalankan lab-start.sh terlebih dahulu."
    exit 1
fi

if [ ! -f "$START_FILE" ]; then
    echo "Start time tidak ditemukan."
    exit 1
fi

if [ ! -f "$RESULT_FILE" ]; then
    echo "result.json tidak ditemukan."
    echo "Jalankan score.sh terlebih dahulu."
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

START_TIME=$(cat "$START_FILE")
END_TIME=$(date +%s)

DURATION=$((END_TIME - START_TIME))

SCORE=$(grep -o '"score":[0-9]*' "$RESULT_FILE" | cut -d: -f2)

if [ -z "$SCORE" ]; then
    echo "Score tidak ditemukan."
    exit 1
fi

if [ "$SCORE" -eq 100 ]; then
    STATUS="done"
else
    STATUS="failed"
fi

echo "Score    : $SCORE"
echo "Duration : ${DURATION}s"
echo "Status   : $STATUS"
echo

echo "Mengirim hasil ke LMS..."

RESP=$(curl -s -X POST "$API_BASE/api/lab/finish" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"chapter_id\":$CHAPTER_ID,
        \"score\":$SCORE,
        \"duration\":$DURATION,
        \"status\":\"$STATUS\",
        \"detail\":$(cat "$RESULT_FILE")
    }")

echo
echo "========================================="
echo "           LMS RESPONSE"
echo "========================================="
echo
echo "$RESP"
echo

if echo "$RESP" | grep -q '"success":true'
then
    echo "Session berhasil ditutup."
else
    echo "Submit gagal."
    echo "Session masih disimpan."
    echo "Silakan submit kembali."
fi
