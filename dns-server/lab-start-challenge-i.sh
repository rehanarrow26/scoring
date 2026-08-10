#!/bin/bash

clear

API_URL="https://lms.teknolojia.my.id/api/lab/start"
CHAPTER_ID=8

LAB_DIR="$HOME/.lab"

TOKEN_FILE="$LAB_DIR/token"
START_FILE="$LAB_DIR/start_time"

mkdir -p "$LAB_DIR"

echo "========================================="
echo "       DNS FORWARD ZONE CHALLENGE"
echo "              CHAPTER 8"
echo "========================================="
echo

read -r -p "User Code : " USER_CODE
read -r -s -p "Password  : " PASSWORD
echo
echo

PAYLOAD=$(jq -n \
    --arg u "$USER_CODE" \
    --arg p "$PASSWORD" \
    --argjson c "$CHAPTER_ID" \
    '{
        user_code:$u,
        password:$p,
        chapter_id:$c
    }')

RESPONSE=$(curl -sS \
    -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success // false')
TOKEN=$(echo "$RESPONSE" | jq -r '.token // empty')
MESSAGE=$(echo "$RESPONSE" | jq -r '.message // empty')

if [ "$SUCCESS" != "true" ] || [ -z "$TOKEN" ]; then

    echo
    echo "Login gagal."
    echo "${MESSAGE:-Tidak dapat login.}"
    exit 1

fi

umask 077

echo "$TOKEN" > "$TOKEN_FILE"
date +%s > "$START_FILE"

echo
echo "========================================="
echo "          LOGIN BERHASIL"
echo "========================================="
echo
echo "Chapter : 8"
echo
echo "Session praktikum dimulai."
echo
