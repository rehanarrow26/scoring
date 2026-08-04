#!/bin/bash

clear

########################################
# CONFIG
########################################

SERVER_IP="192.168.10.2"
SERVER_USER="developer"

SSH_PORT="2222"

KEY_NAME="dev-server"

CLIENT_KEY="$HOME/.ssh/$KEY_NAME"

score=0

########################################
# REMOTE
########################################

REMOTE(){

ssh \
-i "$CLIENT_KEY" \
-p "$SSH_PORT" \
-o BatchMode=yes \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
"$SERVER_USER@$SERVER_IP" "$1"

}

########################################
# HEADER
########################################

echo "========================================="
echo " PASSWORD AUTHENTICATION CHECKER"
echo "========================================="
echo

########################################
# CHECK PasswordAuthentication
########################################

echo -n "Checking PasswordAuthentication..."

VALUE=$(REMOTE "grep -Ei '^[[:space:]]*PasswordAuthentication' /etc/ssh/sshd_config | tail -1 | awk '{print tolower(\$2)}'")

if [ "$VALUE" = "no" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
    echo "Current : ${VALUE:-Unknown}"
fi

########################################
# CHECK PubkeyAuthentication
########################################

echo -n "Checking PubkeyAuthentication....."

VALUE=$(REMOTE "grep -Ei '^[[:space:]]*PubkeyAuthentication' /etc/ssh/sshd_config | tail -1 | awk '{print tolower(\$2)}'")

if [ "$VALUE" = "yes" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
    echo "Current : ${VALUE:-Unknown}"
fi

########################################
# CHECK SSH SERVICE
########################################

echo -n "Checking SSH Service.............."

STATUS=$(REMOTE "systemctl is-active ssh")

if [ "$STATUS" = "active" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK SSH KEY LOGIN
########################################

echo -n "Checking SSH Key Login..........."

RESULT=$(REMOTE "echo OK" 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[PASS]"
    score=$((score+25))
else
    echo "[FAIL]"
fi

########################################
# CHECK PASSWORD LOGIN
########################################

echo -n "Checking Password Login.........."

if ! command -v sshpass >/dev/null 2>&1
then
    echo "[FAIL]"
    echo "sshpass belum terinstall."
else

RESULT=$(sshpass -p "123" ssh \
-p "$SSH_PORT" \
-o PubkeyAuthentication=no \
-o PreferredAuthentications=password \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
"$SERVER_USER@$SERVER_IP" \
echo OK 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[FAIL]"
    echo "Password Authentication masih aktif."
else
    echo "[PASS]"
    score=$((score+25))
fi

fi

########################################
# FINAL
########################################

echo
echo "========================================="
echo "Score : $score /100"
echo "========================================="

if [ "$score" -eq 100 ]
then

    echo
    echo "MISSION COMPLETE"
    echo
    echo "Password Authentication berhasil dinonaktifkan."

else

    echo
    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi SSH."

fi

echo
