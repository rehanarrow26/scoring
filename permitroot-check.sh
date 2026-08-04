#!/bin/bash

clear

########################################
# CONFIG
########################################

SERVER_IP="192.168.10.2"

ROOT_USER="root"
NORMAL_USER="developer"

score=0

########################################
# HEADER
########################################

echo "========================================="
echo "      PERMIT ROOT LOGIN CHECKER"
echo "========================================="
echo

########################################
# CHECK SSH CONFIG
########################################

echo -n "Checking PermitRootLogin........."

VALUE=$(grep -Ei "^[[:space:]]*PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')

if [ "$VALUE" = "no" ]
then
    echo "[PASS]"
    score=$((score+40))
else
    echo "[FAIL]"
    echo "Current : ${VALUE:-Not Set}"
fi

########################################
# CHECK SSH SERVICE
########################################

echo -n "Checking SSH Service............."

if systemctl is-active --quiet ssh
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
fi

########################################
# CHECK ROOT LOGIN
########################################

echo -n "Checking Root Login.............."

RESULT=$(ssh \
-o BatchMode=yes \
-o PreferredAuthentications=password \
-o PubkeyAuthentication=no \
-o StrictHostKeyChecking=no \
-o ConnectTimeout=5 \
${ROOT_USER}@${SERVER_IP} exit 2>&1)

if echo "$RESULT" | grep -qi "Permission denied"
then
    echo "[PASS]"
    score=$((score+40))
else
    echo "[FAIL]"
    echo
    echo "Root masih dapat mencoba login."
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
    echo "PermitRootLogin berhasil dinonaktifkan."

else

    echo
    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi SSH."

fi

echo
