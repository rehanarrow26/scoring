#!/bin/bash

clear

########################################
# CONFIG
########################################

API_URL="http://lms.teknolojia.my.id/api/lab/finish"

CHAPTER_ID=6

LAB_DIR="$HOME/.lab"

TOKEN_FILE="$LAB_DIR/token"

START_FILE="$LAB_DIR/start_time"

RESULT_FILE="$LAB_DIR/result.json"

########################################
# HEADER
########################################

echo "========================================="
echo "        LAB FINISH - DNS SERVER"
echo "========================================="
echo

########################################
# CHECK SESSION
########################################

if [ ! -f "$TOKEN_FILE" ]
then

    echo "ERROR : Session tidak ditemukan."
    echo "Silakan jalankan lab-start.sh terlebih dahulu."

    exit 1

fi

if [ ! -f "$START_FILE" ]
then

    echo "ERROR : Start Time tidak ditemukan."

    exit 1

fi

if [ ! -f "$RESULT_FILE" ]
then

    echo "ERROR : Result checker tidak ditemukan."
    echo "Silakan jalankan dns-primary-check.sh."

    exit 1

fi

########################################
# TOKEN
########################################

TOKEN=$(cat "$TOKEN_FILE")

########################################
# DURATION
########################################

START_TIME=$(cat "$START_FILE")

END_TIME=$(date +%s)

DURATION=$((END_TIME-START_TIME))

########################################
# RESULT
########################################

SCORE=$(python3 -c "import json;print(json.load(open('$RESULT_FILE'))['score'])")

STATUS=$(python3 -c "import json;print(json.load(open('$RESULT_FILE'))['status'])")

DETAIL=$(python3 - <<EOF
import json
print(json.dumps(json.load(open("$RESULT_FILE"))["detail"]))
EOF
)

########################################
# JSON
########################################

PAYLOAD=$(cat <<EOF
{
    "chapter_id":$CHAPTER_ID,
    "score":$SCORE,
    "duration":$DURATION,
    "status":"$STATUS",
    "detail":$DETAIL
}
EOF
)

########################################
# SUBMIT
########################################

echo "Mengirim hasil ke LMS..."
echo

HTTP_CODE=$(curl \
-s \
-o /tmp/lab_finish_response.json \
-w "%{http_code}" \
-X POST "$API_URL" \
-H "Authorization: Bearer $TOKEN" \
-H "Content-Type: application/json" \
-d "$PAYLOAD")

########################################
# RESPONSE
########################################

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]
then

    echo "========================================="
    echo "      SUBMIT BERHASIL"
    echo "========================================="
    echo

    cat /tmp/lab_finish_response.json

    echo

    rm -f "$TOKEN_FILE"
    rm -f "$START_FILE"
    rm -f "$RESULT_FILE"

    echo "Session berhasil ditutup."

else

    echo "========================================="
    echo "      SUBMIT GAGAL"
    echo "========================================="
    echo

    cat /tmp/lab_finish_response.json

    echo
    echo "Session masih disimpan."
    echo "Silakan submit kembali."

fi

rm -f /tmp/lab_finish_response.json

echo
