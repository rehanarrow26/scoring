#!/usr/bin/env bash

set -u

########################################
# CONFIG
########################################

API_BASE="${LAB_API_URL_BASE:-https://lms.teknolojia.my.id}"

LAB_DIR="$HOME/.lab"

TOKEN_FILE="$LAB_DIR/token"
START_FILE="$LAB_DIR/start_time"

RESULT_FILE="result.json"

########################################
# CHECK ARGUMENT
########################################

if [ $# -ne 1 ]; then
    echo "Usage:"
    echo
    echo "  bash lab-finish.sh <chapter_id>"
    echo
    echo "Example:"
    echo "  bash lab-finish.sh 10"
    exit 1
fi

CHAPTER_ID="$1"

########################################
# VALIDATE
########################################

if ! [[ "$CHAPTER_ID" =~ ^[0-9]+$ ]]; then
    echo "Chapter ID harus berupa angka."
    exit 1
fi

########################################
# CHECK SESSION
########################################

if [ ! -f "$TOKEN_FILE" ]; then
    echo "Token tidak ditemukan."
    echo "Jalankan lab-start.sh terlebih dahulu."
    exit 1
fi

if [ ! -f "$START_FILE" ]; then
    echo "Start time tidak ditemukan."
    exit 1
fi

########################################
# CHECK RESULT
########################################

if [ ! -f "$RESULT_FILE" ]; then
    echo "result.json tidak ditemukan."
    echo "Jalankan score.sh terlebih dahulu."
    exit 1
fi

########################################
# READ SESSION
########################################

TOKEN=$(cat "$TOKEN_FILE")

START_TIME=$(cat "$START_FILE")
END_TIME=$(date +%s)

DURATION=$((END_TIME - START_TIME))

########################################
# READ SCORE
########################################

SCORE=$(grep -o '"score"[[:space:]]*:[[:space:]]*[0-9]*' "$RESULT_FILE" |
head -1 |
grep -o '[0-9]*$')

if [ -z "$SCORE" ]; then
    echo "Score tidak ditemukan."
    exit 1
fi

########################################
# STATUS
########################################

if [ "$SCORE" -eq 100 ]; then
    STATUS="done"
else
    STATUS="failed"
fi

########################################
# HEADER
########################################

clear

echo "========================================="
echo "             LAB FINISH"
echo "========================================="
echo
echo "Chapter  : $CHAPTER_ID"
echo "Score    : $SCORE"
echo "Duration : ${DURATION}s"
echo "Status   : $STATUS"
echo

########################################
# SUBMIT
########################################

echo "Mengirim hasil ke LMS..."
echo

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

########################################
# RESPONSE
########################################

echo "========================================="
echo "           LMS RESPONSE"
echo "========================================="
echo
echo "$RESP"
echo

if echo "$RESP" | grep -q '"success":true'; then

    echo "Session berhasil ditutup."

else

    echo "Submit gagal."
    echo "Session masih disimpan."
    echo "Silakan submit kembali."

fi
