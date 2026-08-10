#!/bin/bash

clear

API_URL="https://lms.teknolojia.my.id/api/lab/start"
CHAPTER_ID=7

LAB_DIR="$HOME/.lab"
TOKEN_FILE="$LAB_DIR/token"
START_FILE="$LAB_DIR/start_time"

echo "========================================="
echo "        DNS SERVER - LAB START"
echo "========================================="
echo

mkdir -p "$LAB_DIR"

if ! command -v curl >/dev/null 2>&1; then
    echo "curl belum terinstall."
    echo "Install dengan: apt install curl -y"
    exit 1
fi

read -r -p "User Code : " USER_CODE
read -r -s -p "Password  : " PASSWORD
echo
echo

if command -v jq >/dev/null 2>&1; then
    PAYLOAD=$(jq -n \
        --arg u "$USER_CODE" \
        --arg p "$PASSWORD" \
        --argjson c "$CHAPTER_ID" \
        '{user_code:$u,password:$p,chapter_id:$c}')
else
    PAYLOAD=$(printf \
        '{"user_code":"%s","password":"%s","chapter_id":%s}' \
        "$USER_CODE" "$PASSWORD" "$CHAPTER_ID")
fi

RESPONSE_FILE="/tmp/lab_start_response.json"

HTTP_CODE=$(curl \
    -sS \
    -o "$RESPONSE_FILE" \
    -w "%{http_code}" \
    -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "201" ]; then
    echo
    echo "Login gagal."
    cat "$RESPONSE_FILE"
    rm -f "$RESPONSE_FILE"
    exit 1
fi

if command -v jq >/dev/null 2>&1; then
    SUCCESS=$(jq -r '.success // false' "$RESPONSE_FILE")
    TOKEN=$(jq -r '.token // empty' "$RESPONSE_FILE")
    MESSAGE=$(jq -r '.message // empty' "$RESPONSE_FILE")
else
    SUCCESS=$(grep -o '"success":[a-z]*' "$RESPONSE_FILE" | head -1 | cut -d: -f2)
    TOKEN=$(sed -n 's/.*"token":"\([^"]*\)".*/\1/p' "$RESPONSE_FILE")
    MESSAGE=$(sed -n 's/.*"message":"\([^"]*\)".*/\1/p' "$RESPONSE_FILE")
fi

if [ "$SUCCESS" != "true" ] || [ -z "$TOKEN" ]; then
    echo "Login gagal."
    echo "${MESSAGE:-User Code atau Password salah.}"
    rm -f "$RESPONSE_FILE"
    exit 1
fi

umask 077

echo "$TOKEN" > "$TOKEN_FILE"
date +%s > "$START_FILE"

rm -f "$RESPONSE_FILE"

echo "========================================="
echo "          LOGIN BERHASIL"
echo "========================================="
echo
echo "Chapter : $CHAPTER_ID"
echo "User    : $USER_CODE"
echo
echo "Session praktikum dimulai."
echo
