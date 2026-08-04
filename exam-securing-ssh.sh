#!/bin/bash

clear

########################################
# CONFIG
########################################

SERVER_IP="192.168.10.2"

ROOT_USER="root"

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
    echo
    echo "apt install sshpass"
    echo
    exit
fi

########################################
# CREATE PROGRESS FILE
########################################

if [ ! -f "$PROGRESS" ]
then

cat > "$PROGRESS" <<EOF
S1_ATTEMPT=0
S1_BEST=0
S1_LAST=0

S2_ATTEMPT=0
S2_BEST=0
S2_LAST=0

S3_ATTEMPT=0
S3_BEST=0
S3_LAST=0

S4_ATTEMPT=0
S4_BEST=0
S4_LAST=0

S5_ATTEMPT=0
S5_BEST=0
S5_LAST=0

S6_ATTEMPT=0
S6_BEST=0
S6_LAST=0

S7_ATTEMPT=0
S7_BEST=0
S7_LAST=0
EOF

fi

########################################
# ARGUMENT
########################################

if [ $# -ne 1 ]
then

echo
echo "Usage : ./exam-securing-ssh.sh <nomor_soal>"
echo
echo "Example :"
echo "./exam-securing-ssh.sh 1"
echo
exit

fi

SOAL="$1"

########################################
# LOAD PROGRESS
########################################

source "$PROGRESS"

########################################
# HEADER
########################################

echo "=========================================="
echo "      SECURING SSH EXAM CHECKER"
echo "=========================================="
echo
echo "Server : $SERVER_IP"
echo "Question : $SOAL"
echo

########################################
# LOAD QUESTION
########################################

case "$SOAL" in

1)

USER_NAME="adminweb"
PASSWORD="$DEFAULT_PASSWORD"

KEY_NAME="adminweb-key"

SSH_PORT="2200"

MODE="KEY_ONLY"

;;

2)

USER_NAME="programmer"
PASSWORD="$DEFAULT_PASSWORD"

KEY_NAME="programmer-key"

SSH_PORT="2222"

MODE="PASSWORD_ONLY"

;;

3)

USER_NAME="devops"
PASSWORD="$DEFAULT_PASSWORD"

KEY_NAME="devops-key"

SSH_PORT="2022"

MODE="KEY_ONLY"

;;

4)

USER_NAME="support"
PASSWORD="$DEFAULT_PASSWORD"

KEY_NAME="support-key"

SSH_PORT="10022"

MODE="PASSWORD_ONLY"

;;

5)

USER_NAME="backupadmin"
PASSWORD="$DEFAULT_PASSWORD"

KEY_NAME="backup-key"

SSH_PORT="5022"

MODE="KEY_ONLY"

;;

6)

USER_NAME="noc"
PASSWORD="$DEFAULT_PASSWORD"

KEY_NAME="noc-key"

SSH_PORT="8022"

MODE="PASSWORD_ONLY"

;;

7)

USER_NAME="security"
PASSWORD="$DEFAULT_PASSWORD"

KEY_NAME="security-key"

SSH_PORT="9000"

MODE="KEY_ONLY"

;;

*)

echo
echo "Nomor soal tidak valid."
echo
exit

;;

esac

########################################
# VARIABLE
########################################

PRIVATE_KEY="$HOME/.ssh/$KEY_NAME"
PUBLIC_KEY="$HOME/.ssh/$KEY_NAME.pub"

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
# CHECK PASSWORD AUTHENTICATION
########################################

CHECK_PASSWORD_AUTH(){

REMOTE_KEY \
"sshd -T -C user=$USER_NAME | awk '/^passwordauthentication /{print \$2}'"

}

########################################
# CHECK PUBKEY AUTHENTICATION
########################################

CHECK_PUBKEY_AUTH(){

REMOTE_KEY \
"sshd -T -C user=$USER_NAME | awk '/^pubkeyauthentication /{print \$2}'"

}

########################################
# CHECK PERMIT ROOT LOGIN
########################################

CHECK_ROOT_CONFIG(){

REMOTE_KEY \
"sshd -T -C user=$USER_NAME | awk '/^permitrootlogin /{print \$2}'"

}

########################################
# CHECK SSH SERVICE
########################################

echo -n "Checking SSH Service.............."

STATUS=$(CHECK_SERVICE)

if [ "$STATUS" = "active" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK SSH PORT
########################################

echo -n "Checking SSH Port................."

PORT=$(CHECK_PORT)

if [ "$PORT" = "OPEN" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK PERMIT ROOT LOGIN
########################################

echo -n "Checking PermitRootLogin.........."

VALUE=$(CHECK_ROOT_CONFIG)

if [ "$VALUE" = "no" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
    echo "Current : $VALUE"
fi

########################################
# CHECK PasswordAuthentication
########################################

echo -n "Checking PasswordAuthentication..."

VALUE=$(CHECK_PASSWORD_AUTH)

if [ "$MODE" = "KEY_ONLY" ]
then
    EXPECTED="no"
else
    EXPECTED="yes"
fi

if [ "$VALUE" = "$EXPECTED" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
    echo "Expected : $EXPECTED"
    echo "Current  : $VALUE"
fi

########################################
# CHECK PubkeyAuthentication
########################################

echo -n "Checking PubkeyAuthentication....."

VALUE=$(CHECK_PUBKEY_AUTH)

if [ "$MODE" = "KEY_ONLY" ]
then
    EXPECTED="yes"
else
    EXPECTED="no"
fi

if [ "$VALUE" = "$EXPECTED" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
    echo "Expected : $EXPECTED"
    echo "Current  : $VALUE"
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
        score=$((score+20))
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
        score=$((score+20))
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
        score=$((score+20))
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
        score=$((score+20))
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
# CHECK PERMIT ROOT LOGIN
########################################

echo -n "Checking PermitRootLogin.........."

VALUE=$(CHECK_ROOT_CONFIG)

if [ "$VALUE" = "no" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
    echo "Current : $VALUE"
fi

########################################
# CHECK PasswordAuthentication
########################################

echo -n "Checking PasswordAuthentication..."

VALUE=$(CHECK_PASSWORD_AUTH)

if [ "$MODE" = "KEY_ONLY" ]
then
    EXPECTED="no"
else
    EXPECTED="yes"
fi

if [ "$VALUE" = "$EXPECTED" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
    echo "Expected : $EXPECTED"
    echo "Current  : $VALUE"
fi

########################################
# CHECK PubkeyAuthentication
########################################

echo -n "Checking PubkeyAuthentication....."

VALUE=$(CHECK_PUBKEY_AUTH)

if [ "$MODE" = "KEY_ONLY" ]
then
    EXPECTED="yes"
else
    EXPECTED="no"
fi

if [ "$VALUE" = "$EXPECTED" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
    echo "Expected : $EXPECTED"
    echo "Current  : $VALUE"
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
        score=$((score+20))
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
        score=$((score+20))
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
        score=$((score+20))
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
        score=$((score+20))
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
# UPDATE PROGRESS
########################################

ATTEMPT_VAR="S${SOAL}_ATTEMPT"
BEST_VAR="S${SOAL}_BEST"
LAST_VAR="S${SOAL}_LAST"

CURRENT_ATTEMPT=$(eval echo \$$ATTEMPT_VAR)
CURRENT_BEST=$(eval echo \$$BEST_VAR)

CURRENT_ATTEMPT=$((CURRENT_ATTEMPT+1))

if [ "$score" -gt "$CURRENT_BEST" ]
then
    CURRENT_BEST=$score
fi

eval "$ATTEMPT_VAR=$CURRENT_ATTEMPT"
eval "$BEST_VAR=$CURRENT_BEST"
eval "$LAST_VAR=$score"

cat > "$PROGRESS" <<EOF
S1_ATTEMPT=$S1_ATTEMPT
S1_BEST=$S1_BEST
S1_LAST=$S1_LAST

S2_ATTEMPT=$S2_ATTEMPT
S2_BEST=$S2_BEST
S2_LAST=$S2_LAST

S3_ATTEMPT=$S3_ATTEMPT
S3_BEST=$S3_BEST
S3_LAST=$S3_LAST

S4_ATTEMPT=$S4_ATTEMPT
S4_BEST=$S4_BEST
S4_LAST=$S4_LAST

S5_ATTEMPT=$S5_ATTEMPT
S5_BEST=$S5_BEST
S5_LAST=$S5_LAST

S6_ATTEMPT=$S6_ATTEMPT
S6_BEST=$S6_BEST
S6_LAST=$S6_LAST

S7_ATTEMPT=$S7_ATTEMPT
S7_BEST=$S7_BEST
S7_LAST=$S7_LAST
EOF

########################################
# FINAL SCORE
########################################

echo
echo "========================================="
echo "           FINAL RESULT"
echo "========================================="
echo

echo "Question : $SOAL"
echo "Attempt  : $CURRENT_ATTEMPT"
echo "Last     : $score /100"
echo "Best     : $CURRENT_BEST /100"

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
