#!/bin/bash

clear

########################################
# CONFIG
########################################

SERVER_IP="192.168.10.2"
SSH_PORT="2222"

DEV_USER="developer"
DEV_PASS="123"
DEV_KEY="$HOME/.ssh/dev-server"

OP_USER="operator"
OP_PASS="123"
OP_KEY="$HOME/.ssh/operator-key"

score=0

########################################
# HEADER
########################################

echo "========================================="
echo "        MATCH USER CHECKER"
echo "========================================="
echo

########################################
# CHECK SSHPASS
########################################

if ! command -v sshpass >/dev/null
then
    echo "sshpass belum terinstall."
    exit
fi

########################################
# CHECK SSH SERVICE
########################################

echo -n "Checking SSH Service.............."

if systemctl is-active --quiet ssh
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK Match User
########################################

echo -n "Checking Match User..............."

MATCH=$(sshd -T -C user=$DEV_USER | grep passwordauthentication | awk '{print $2}')

if [ "$MATCH" = "no" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# DEVELOPER SSH KEY
########################################

echo -n "Checking developer SSH Key........"

RESULT=$(ssh \
-i "$DEV_KEY" \
-p "$SSH_PORT" \
-o BatchMode=yes \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
$DEV_USER@$SERVER_IP \
echo OK 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
fi

########################################
# DEVELOPER PASSWORD
########################################

echo -n "Checking developer Password......."

RESULT=$(sshpass -p "$DEV_PASS" ssh \
-p "$SSH_PORT" \
-o PubkeyAuthentication=no \
-o PreferredAuthentications=password \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
$DEV_USER@$SERVER_IP \
echo OK 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[FAIL]"
else
    echo "[PASS]"
    score=$((score+20))
fi

########################################
# OPERATOR PASSWORD
########################################

echo -n "Checking operator Password........"

RESULT=$(sshpass -p "$OP_PASS" ssh \
-p "$SSH_PORT" \
-o PubkeyAuthentication=no \
-o PreferredAuthentications=password \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
$OP_USER@$SERVER_IP \
echo OK 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
fi

########################################
# OPERATOR SSH KEY
########################################

echo -n "Checking operator SSH Key........."

RESULT=$(ssh \
-i "$OP_KEY" \
-p "$SSH_PORT" \
-o BatchMode=yes \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
$OP_USER@$SERVER_IP \
echo OK 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[FAIL]"
else
    echo "[PASS]"
    score=$((score+20))
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
    echo "Konfigurasi Match User berhasil."

else

    echo
    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi SSH."

fi

echo
