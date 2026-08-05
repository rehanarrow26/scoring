#!/bin/bash

clear

########################################
# CONFIG
########################################

API_URL="http://192.168.10.5:8000/api/lab/start"

CHAPTER_ID=6

LAB_DIR="$HOME/.lab"

TOKEN_FILE="$LAB_DIR/token"

START_FILE="$LAB_DIR/start_time"

########################################
# HEADER
########################################

echo "========================================="
echo "          LAB START - DNS SERVER"
echo "========================================="
echo

########################################
# PREPARE
########################################

mkdir -p "$LAB_DIR"

chmod 700 "$LAB_DIR"

########################################
# INPUT
########################################

read -p "User Code : " USER_CODE

read -s -p "Password  : " PASSWORD

echo
echo

########################################
# JSON PAYLOAD
########################################

PAYLOAD=$(cat <<EOF
{
    "user_code":"$USER_CODE",
    "password":"$PASSWORD",
    "chapter_id":$CHAPTER_ID
}
EOF
)

########################################
# LOGIN
########################################

RESPONSE=$(curl -s \
-X POST "$API_URL" \
-H "Content-Type: application/json" \
-d "$PAYLOAD")

########################################
# PARSE
########################################

SUCCESS=$(echo "$RESPONSE" | sed -n 's/.*"success":\([^,}]*\).*/\1/p')

TOKEN=$(echo "$RESPONSE" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

MESSAGE=$(echo "$RESPONSE" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')

NAME=$(echo "$RESPONSE" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')

TITLE=$(echo "$RESPONSE" | sed -n 's/.*"title":"\([^"]*\)".*/\1/p')

########################################
# FAILED
########################################

if [ "$SUCCESS" != "true" ]
then

    echo "========================================="
    echo "LOGIN FAILED"
    echo "========================================="
    echo

    echo "${MESSAGE:-Tidak dapat terhubung ke server.}"

    echo

    exit 1

fi

########################################
# SAVE SESSION
########################################

echo "$TOKEN" > "$TOKEN_FILE"

chmod 600 "$TOKEN_FILE"

date +%s > "$START_FILE"

chmod 600 "$START_FILE"

########################################
# SUCCESS
########################################

echo "========================================="
echo "LOGIN SUCCESS"
echo "========================================="
echo

echo "Nama     : $NAME"

echo "Chapter  : $TITLE"

echo

echo "Session berhasil dibuat."

echo "Silakan kerjakan praktikum DNS."

echo
