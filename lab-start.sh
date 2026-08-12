#!/usr/bin/env bash

set -u

########################################
# CONFIG
########################################

API_URL="${LAB_API_URL:-https://lms.teknolojia.my.id/api/lab/start}"

LAB_DIR="$HOME/.lab"

TOKEN_FILE="$LAB_DIR/token"
START_FILE="$LAB_DIR/start_time"

########################################
# CHECK ARGUMENT
########################################

if [ $# -ne 1 ]; then
    echo "Usage:"
    echo
    echo "  bash lab-start.sh <chapter_id>"
    echo
    echo "Example:"
    echo "  bash lab-start.sh 10"
    exit 1
fi

CHAPTER_ID="$1"

########################################
# VALIDATE CHAPTER ID
########################################

if ! [[ "$CHAPTER_ID" =~ ^[0-9]+$ ]]; then
    echo "Chapter ID harus berupa angka."
    exit 1
fi

########################################
# PREPARE
########################################

mkdir -p "$LAB_DIR"

########################################
# HEADER
########################################

clear

echo "========================================="
echo "             LAB START"
echo "========================================="
echo
echo "Chapter : $CHAPTER_ID"
echo

########################################
# LOGIN
########################################

read -r -p "User Code: " USER_CODE
read -r -s -p "Password: " PASSWORD
echo

########################################
# API REQUEST
########################################

RESP=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{\"user_code\":\"$USER_CODE\",\"password\":\"$PASSWORD\",\"chapter_id\":$CHAPTER_ID}")

########################################
# GET TOKEN
########################################

TOKEN=$(echo "$RESP" |
    sed -n 's/.*"token":"\([^"]*\)".*/\1/p')

########################################
# LOGIN FAILED
########################################

if [ -z "$TOKEN" ]; then

    echo
    echo "========================================="
    echo "             LOGIN GAGAL"
    echo "========================================="
    echo
    echo "$RESP"
    exit 1

fi

########################################
# SAVE SESSION
########################################

umask 077

echo "$TOKEN" > "$TOKEN_FILE"

date +%s > "$START_FILE"

########################################
# SUCCESS
########################################

echo
echo "========================================="
echo "             LOGIN BERHASIL"
echo "========================================="
echo
echo "Chapter : $CHAPTER_ID"
echo
echo "Waktu pengerjaan mulai dihitung."
echo
echo "Silakan mulai mengerjakan lab."
echo
