#!/bin/bash

#===========================================
# SSH PRACTICE CHECKER v1.0
# Author : ChatGPT & Raihan
#===========================================

clear

PROGRESS="$HOME/.ssh_progress"

if [ ! -f "$PROGRESS" ]; then
    for i in {1..7}
    do
        echo "S${i}_ATTEMPT=0" >> "$PROGRESS"
        echo "S${i}_BEST=0" >> "$PROGRESS"
        echo "S${i}_LAST=0" >> "$PROGRESS"
    done
fi

echo "=============================================="
echo "          SSH PRACTICE CHECKER"
echo "=============================================="
echo
echo "[1] Soal 1"
echo "[2] Soal 2"
echo "[3] Soal 3"
echo "[4] Soal 4"
echo "[5] Soal 5"
echo "[6] Soal 6"
echo "[7] Soal 7"
echo

read -p "Pilih nomor soal : " SOAL

case $SOAL in

1)
USER_EXPECT="eko"
IP_EXPECT="192.168.10.2"
;;

2)
USER_EXPECT="database"
IP_EXPECT="192.168.20.2"
;;

3)
USER_EXPECT="backup"
IP_EXPECT="172.16.10.2"
;;

4)
USER_EXPECT="webadmin"
IP_EXPECT="10.10.10.2"
;;

5)
USER_EXPECT="security"
IP_EXPECT="172.20.30.2"
;;

6)
USER_EXPECT="developer"
IP_EXPECT="192.168.100.2"
;;

7)
USER_EXPECT="administrator"
IP_EXPECT="10.100.50.2"
;;

*)
echo "Nomor soal tidak valid."
exit
;;

esac

PASSWORD="123"

echo
read -p "Masukkan perintah SSH : " CMD

SSH_CMD=$(echo "$CMD" | awk '{print $1}')
SSH_USER=$(echo "$CMD" | awk '{print $2}' | cut -d@ -f1)
SSH_HOST=$(echo "$CMD" | awk '{print $2}' | cut -d@ -f2)

score=0

echo
echo "Checking User..............."

if id "$USER_EXPECT" >/dev/null 2>&1
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
fi

echo
echo "Checking IP Address........."

if ip a | grep -qw "$IP_EXPECT"
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
fi

echo
echo "Checking SSH Command........"

if [ "$SSH_CMD" = "ssh" ] &&
   [ "$SSH_USER" = "$USER_EXPECT" ] &&
   [ "$SSH_HOST" = "$IP_EXPECT" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
fi

echo
printf "%-35s" "Checking SSH Login..."

RESULT=$(sshpass -p "$PASSWORD" ssh \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o BatchMode=no \
-o ConnectTimeout=5 \
${USER_EXPECT}@${IP_EXPECT} exit 2>&1)

STATUS=$?

if [ $STATUS -eq 0 ]
then
    echo "[PASS]"
    score=$((score+40))
else
    echo "[FAIL]"
    echo
    echo "Reason :"
    echo "$RESULT"
fi
########################################
# Update Progress
########################################

source "$PROGRESS"

eval ATTEMPT=\$S${SOAL}_ATTEMPT
eval BEST=\$S${SOAL}_BEST

ATTEMPT=$((ATTEMPT+1))
LAST=$score

if [ "$score" -gt "$BEST" ]
then
    BEST=$score
fi

sed -i "s/^S${SOAL}_ATTEMPT=.*/S${SOAL}_ATTEMPT=$ATTEMPT/" "$PROGRESS"
sed -i "s/^S${SOAL}_BEST=.*/S${SOAL}_BEST=$BEST/" "$PROGRESS"
sed -i "s/^S${SOAL}_LAST=.*/S${SOAL}_LAST=$LAST/" "$PROGRESS"
########################################
# Score
########################################

echo
echo "======================================="
echo "Score : $score /100"
echo "======================================="

########################################
# Progress
########################################

source "$PROGRESS"

TOTAL=0

for i in {1..7}
do
    eval A=\$S${i}_ATTEMPT
    TOTAL=$((TOTAL+A))
done

echo "=============================================="
echo "          SSH PRACTICE PROGRESS"
echo "=============================================="
echo
echo "Total Attempt : $TOTAL"
echo

for i in {1..7}
do

eval A=\$S${i}_ATTEMPT
eval B=\$S${i}_BEST
eval L=\$S${i}_LAST

echo "----------------------------------------------"
echo "Soal $i"
echo
echo "Attempt    : $A"

if [ "$A" -eq 0 ]
then
    echo "Best Score : -"
    echo "Last Score : -"
else
    echo "Best Score : $B"
    echo "Last Score : $L"
fi

echo

done

echo "=============================================="
