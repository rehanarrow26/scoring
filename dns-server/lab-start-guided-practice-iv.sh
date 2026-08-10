#!/usr/bin/env bash

set -u

API_URL="${LAB_API_URL:-https://lms.teknolojia.my.id/api/lab/start}"

CHAPTER_ID=10

LAB_DIR="$HOME/.lab"

TOKEN_FILE="$LAB_DIR/token"
START_FILE="$LAB_DIR/start_time"

mkdir -p "$LAB_DIR"

echo "========================================="
echo "        LAB START - DNS REVERSE"
echo "              CHAPTER 10"
echo "========================================="
echo

read -r -p "User Code: " USER_CODE
read -r -s -p "Password: " PASSWORD
echo

RESP=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{\"user_code\":\"$USER_CODE\",\"password\":\"$PASSWORD\",\"chapter_id\":$CHAPTER_ID}")

TOKEN=$(echo "$RESP" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

if [ -z "$TOKEN" ]; then
    echo
    echo "Login gagal."
    echo "$RESP"
    exit 1
fi

umask 077
echo "$TOKEN" > "$TOKEN_FILE"

date +%s > "$START_FILE"

echo
echo "Login berhasil."
echo "Chapter : $CHAPTER_ID"
echo
echo "Waktu pengerjaan mulai dihitung."
echo
echo "Silakan mulai mengerjakan lab."
