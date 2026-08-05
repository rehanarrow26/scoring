#!/bin/bash

clear

########################################
# CONFIG
########################################

SERVER_IP="192.168.10.2"

DEFAULT_PASSWORD="123"

PROGRESS="$HOME/.ssh_secure_progress"

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
    echo "apt install sshpass -y"
    echo
    exit
fi

########################################
# ARGUMENT
########################################

if [ $# -ne 1 ]
then
    echo
    echo "Usage : ./exam-securing-ssh.sh <nomor_soal>"
    echo
    echo "Example : ./exam-securing-ssh.sh 1"
    echo
    exit
fi

SOAL="$1"

########################################
# HEADER
########################################

echo "=========================================="
echo "      SECURING SSH EXAM CHECKER"
echo "=========================================="
echo

case "$SOAL" in

1)
USER_NAME="adminweb"
KEY_NAME="adminweb-key"
SSH_PORT="2200"
MODE="KEY_ONLY"
;;

2)
USER_NAME="programmer"
KEY_NAME="programmer-key"
SSH_PORT="2222"
MODE="PASSWORD_ONLY"
;;

3)
USER_NAME="devops"
KEY_NAME="devops-key"
SSH_PORT="2022"
MODE="KEY_ONLY"
;;

4)
USER_NAME="support"
KEY_NAME="support-key"
SSH_PORT="10022"
MODE="PASSWORD_ONLY"
;;

5)
USER_NAME="backupadmin"
KEY_NAME="backup-key"
SSH_PORT="5022"
MODE="KEY_ONLY"
;;

6)
USER_NAME="noc"
KEY_NAME="noc-key"
SSH_PORT="8022"
MODE="PASSWORD_ONLY"
;;

7)
USER_NAME="security"
KEY_NAME="security-key"
SSH_PORT="9000"
MODE="KEY_ONLY"
;;

*)
echo "Nomor soal tidak valid."
exit
;;
esac

PASSWORD="$DEFAULT_PASSWORD"
PRIVATE_KEY="$HOME/.ssh/$KEY_NAME"
PUBLIC_KEY="$HOME/.ssh/$KEY_NAME.pub"

echo "Question : $SOAL"
echo "User     : $USER_NAME"
echo "Port     : $SSH_PORT"
echo "Mode     : $MODE"
echo

########################################
# REMOTE VIA SSH KEY
########################################

REMOTE_KEY(){

ssh \
-i "$PRIVATE_KEY" \
-p "$SSH_PORT" \
-o BatchMode=yes \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
"$USER_NAME@$SERVER_IP" "$1"

}

########################################
# REMOTE VIA PASSWORD
########################################

REMOTE_PASSWORD(){

sshpass -p "$PASSWORD" ssh \
-p "$SSH_PORT" \
-o PubkeyAuthentication=no \
-o PreferredAuthentications=password \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
"$USER_NAME@$SERVER_IP" "$1"

}

########################################
# CHECK ROOT LOGIN
########################################

CHECK_ROOT(){

sshpass -p "$PASSWORD" ssh \
-p "$SSH_PORT" \
-o PubkeyAuthentication=no \
-o PreferredAuthentications=password \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
root@$SERVER_IP \
echo OK 2>/dev/null

}

########################################
# CHECK SSH PORT
########################################

CHECK_PORT(){

timeout 3 bash -c "</dev/tcp/$SERVER_IP/$SSH_PORT" >/dev/null 2>&1

if [ $? -eq 0 ]
then
    echo OPEN
else
    echo CLOSED
fi

}

########################################
# CHECK SSH PORT
########################################

echo -n "Checking SSH Port................."

PORT=$(CHECK_PORT)

if [ "$PORT" = "OPEN" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
fi

########################################
# CHECK SSH KEY LOGIN
########################################

echo -n "Checking SSH Key Login............"

RESULT=$(REMOTE_KEY "echo OK" 2>/dev/null)

if [ "$MODE" = "KEY_ONLY" ]
then

    if [ "$RESULT" = "OK" ]
    then
        echo "[PASS]"
        score=$((score+40))
    else
        echo "[FAIL]"
    fi

else

    if [ "$RESULT" = "OK" ]
    then
        echo "[FAIL]"
        echo "SSH Key seharusnya ditolak."
    else
        echo "[PASS]"
        score=$((score+40))
    fi

fi

########################################
# CHECK PASSWORD LOGIN
########################################

echo -n "Checking Password Login..........."

RESULT=$(REMOTE_PASSWORD "echo OK" 2>/dev/null)

if [ "$MODE" = "PASSWORD_ONLY" ]
then

    if [ "$RESULT" = "OK" ]
    then
        echo "[PASS]"
        score=$((score+30))
    else
        echo "[FAIL]"
    fi

else

    if [ "$RESULT" = "OK" ]
    then
        echo "[FAIL]"
        echo "Password Authentication masih aktif."
    else
        echo "[PASS]"
        score=$((score+30))
    fi

fi

########################################
# CHECK ROOT LOGIN
########################################

echo -n "Checking Root Login..............."

ROOT=$(CHECK_ROOT)

if [ "$ROOT" = "OK" ]
then
    echo "[FAIL]"
    echo "Root masih dapat login."
else
    echo "[PASS]"
    score=$((score+10))
fi

########################################
# FINAL SCORE
########################################

echo
echo "========================================="
echo "           FINAL RESULT"
echo "========================================="
echo

echo "Question : $SOAL"
echo "Score    : $score /100"

echo
echo "========================================="

if [ "$score" -eq 100 ]
then

    echo
    echo "MISSION COMPLETE"
    echo
    echo "Excellent!"
    echo "Seluruh konfigurasi SSH telah sesuai."
    echo

else

    echo
    echo "MISSION FAILED"
    echo
    echo "Masih ada konfigurasi yang belum sesuai."
    echo "Periksa kembali output checker di atas."
    echo

fi
