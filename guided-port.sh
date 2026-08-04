#!/bin/bash

clear

########################################
# CONFIG
########################################

SERVER_IP="192.168.10.2"
SERVER_USER="developer"
SERVER_PASSWORD="123"

OLD_PORT="22"
NEW_PORT="2222"

score=0

########################################
# CHECK SSHPASS
########################################

if ! command -v sshpass >/dev/null 2>&1
then
    echo
    echo "sshpass belum terinstall."
    echo
    echo "Install terlebih dahulu:"
    echo
    echo "apt install sshpass -y"
    echo
    exit
fi

########################################
# HEADER
########################################

echo "========================================="
echo "         SSH PORT CHECKER"
echo "========================================="
echo

########################################
# CHECK CONFIG
########################################

echo -n "Checking SSH Port Config........."

PORT=$(grep -E "^[[:space:]]*Port" /etc/ssh/sshd_config | awk '{print $2}')

if [ "$PORT" = "$NEW_PORT" ]
then
    echo "[PASS]"
    score=$((score+25))
else
    echo "[FAIL]"
    echo "Current : ${PORT:-Default(22)}"
fi

########################################
# CHECK SSH SERVICE
########################################

echo -n "Checking SSH Service............."

if systemctl is-active --quiet ssh
then
    echo "[PASS]"
    score=$((score+15))
else
    echo "[FAIL]"
fi

########################################
# CHECK OLD PORT
########################################

echo -n "Checking Old Port................."

if timeout 3 bash -c "</dev/tcp/$SERVER_IP/$OLD_PORT" 2>/dev/null
then
    echo "[FAIL]"
    echo "Port $OLD_PORT masih terbuka."
else
    echo "[PASS]"
    score=$((score+20))
fi

########################################
# CHECK NEW PORT
########################################

echo -n "Checking New Port................."

if timeout 3 bash -c "</dev/tcp/$SERVER_IP/$NEW_PORT" 2>/dev/null
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
fi

########################################
# CHECK SSH LOGIN
########################################

echo -n "Checking SSH Login..............."

RESULT=$(sshpass -p "$SERVER_PASSWORD" ssh \
-p "$NEW_PORT" \
-o PubkeyAuthentication=no \
-o PreferredAuthentications=password \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
"$SERVER_USER@$SERVER_IP" \
echo OK 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
    echo
    echo "Tidak dapat login melalui port $NEW_PORT."
fi

########################################
# FINAL SCORE
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
    echo "Konfigurasi port SSH berhasil."

else

    echo
    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi SSH."

fi

echo
