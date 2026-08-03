#!/bin/bash

clear

########################################
# SSH KEY CHALLENGE CHECKER
########################################

PROGRESS="$HOME/.sshkey_progress"

########################################
# INIT PROGRESS
########################################

if [ ! -f "$PROGRESS" ]
then

for i in {1..7}
do
echo "S${i}_ATTEMPT=0" >> "$PROGRESS"
echo "S${i}_BEST=0" >> "$PROGRESS"
echo "S${i}_LAST=0" >> "$PROGRESS"
done

fi

########################################
# ARGUMENT
########################################

if [ $# -ne 1 ]
then
echo
echo "Usage : ./check.sh <nomor_soal>"
echo
echo "Example :"
echo "./check.sh 1"
echo
exit
fi

SOAL=$1

########################################
# CONFIG
########################################

CLIENT_USER="developer"

CLIENT_IP="192.168.10.10"
SERVER_IP="192.168.10.2"

########################################
# CONFIG PER SOAL
########################################

case $SOAL in

1)

KEY_NAME="server-admin"
SERVER_USER="admin"

;;

2)

KEY_NAME="web-key"
SERVER_USER="webadmin"

;;

3)

KEY_NAME="db-key"
SERVER_USER="database"

;;

4)

KEY_NAME="backup-key"
SERVER_USER="backupadmin"

;;

5)

KEY_NAME="monitor-key"
SERVER_USER="monitor"

;;

6)

KEY_NAME="app-key"
SERVER_USER="developer"

;;

7)

KEY_NAME="security-key"
SERVER_USER="security"

;;

*)

echo
echo "Soal tidak tersedia."
echo
exit

;;

esac

########################################
# KEY LOCATION
########################################

CLIENT_KEY="$HOME/.ssh/$KEY_NAME"
CLIENT_PUB="$HOME/.ssh/$KEY_NAME.pub"

score=0

########################################
# LOAD PROGRESS
########################################

source "$PROGRESS"

eval ATTEMPT=\$S${SOAL}_ATTEMPT
eval BEST=\$S${SOAL}_BEST
eval LAST=\$S${SOAL}_LAST

########################################
# HEADER
########################################

clear

echo "========================================="
echo "      SSH KEY CHALLENGE CHECKER"
echo "========================================="
echo
echo "Soal      : $SOAL"
echo
echo "Attempt   : $ATTEMPT"
echo "Best Score: $BEST"
echo "Last Score: $LAST"
echo
echo "========================================="
echo

########################################
# REMOTE SSH
########################################

REMOTE(){

ssh \
-i "$CLIENT_KEY" \
-o BatchMode=yes \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
"$SERVER_USER@$SERVER_IP" "$1"

}

########################################
# PART 2
########################################
#
# Check:
# - User
# - Client IP
# - Private Key
# - Public Key
#
########################################

########################################
# CHECK USER
########################################

echo -n "Checking Current User............"

if [ "$(whoami)" = "$CLIENT_USER" ]
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
    echo "Jalankan checker menggunakan user $CLIENT_USER."
    exit
fi

########################################
# CHECK CLIENT IP
########################################

echo -n "Checking Client IP..............."

if ip -4 addr show | grep -qw "$CLIENT_IP"
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
    echo "Expected : $CLIENT_IP"
fi

########################################
# CHECK PRIVATE KEY
########################################

echo -n "Checking Private Key............"

if [ -f "$CLIENT_KEY" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
    echo "Expected : $CLIENT_KEY"
fi

########################################
# CHECK PUBLIC KEY
########################################

echo -n "Checking Public Key............."

if [ -f "$CLIENT_PUB" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
    echo "Expected : $CLIENT_PUB"
fi

########################################
# CHECK SSH LOGIN
########################################

echo -n "Checking SSH Login.............."

RESULT=$(REMOTE "echo OK" 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
    echo
    echo "Tidak dapat login menggunakan SSH Key."
    echo "Pastikan:"
    echo "- Private Key benar."
    echo "- ssh-copy-id sudah dijalankan."
    echo "- SSH Server aktif."
    exit
fi

########################################
# PART 3
########################################
#
# Check:
# - .ssh
# - authorized_keys
# - Registered Public Key
# - Permission
# - Ownership
#
########################################
########################################
# CHECK .SSH DIRECTORY
########################################

echo -n "Checking .ssh Directory.........."

if REMOTE "test -d ~/.ssh"
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK AUTHORIZED_KEYS
########################################

echo -n "Checking authorized_keys........."

if REMOTE "test -f ~/.ssh/authorized_keys"
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK REGISTERED PUBLIC KEY
########################################

echo -n "Checking Registered Public Key..."

PUB=$(cat "$CLIENT_PUB")

if REMOTE "grep -Fxq '$PUB' ~/.ssh/authorized_keys"
then
    echo "[PASS]"
    score=$((score+15))
else
    echo "[FAIL]"
    echo "Public Key belum terdaftar."
fi

########################################
# CHECK .SSH PERMISSION
########################################

echo -n "Checking .ssh Permission........."

PERM=$(REMOTE "stat -c %a ~/.ssh")

if [ "$PERM" = "700" ]
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
    echo "Current : $PERM"
fi

########################################
# CHECK AUTHORIZED_KEYS PERMISSION
########################################

echo -n "Checking authorized_keys Permission"

PERM=$(REMOTE "stat -c %a ~/.ssh/authorized_keys")

if [ "$PERM" = "600" ]
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
    echo "Current : $PERM"
fi

########################################
# CHECK OWNER
########################################

echo -n "Checking Ownership..............."

OWNER=$(REMOTE "stat -c %U ~/.ssh/authorized_keys")

if [ "$OWNER" = "$SERVER_USER" ]
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
    echo "Current : $OWNER"
fi

########################################
# PART 4
########################################
#
# Update Progress
# Final Score
# Summary
#
########################################

########################################
# UPDATE PROGRESS
########################################

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
# FINAL SCORE
########################################

echo
echo "========================================="
echo "Score : $score /100"
echo "========================================="

########################################
# RESULT
########################################

if [ "$score" -eq 100 ]
then

    echo
    echo "MISSION COMPLETE"
    echo
    echo "Congratulations!"
    echo "Semua konfigurasi SSH Key berhasil."

else

    echo
    echo "MISSION FAILED"
    echo
    echo "Perbaiki konfigurasi yang masih gagal,"
    echo "kemudian jalankan checker kembali."

fi

########################################
# PROGRESS
########################################

echo
echo "============== PROGRESS =============="

TOTAL_ATTEMPT=0
TOTAL_BEST=0

for i in {1..7}
do

    eval A=\$S${i}_ATTEMPT
    eval B=\$S${i}_BEST

    TOTAL_ATTEMPT=$((TOTAL_ATTEMPT+A))
    TOTAL_BEST=$((TOTAL_BEST+B))

    printf "Soal %-2s : Attempt %-3s Best %-3s\n" "$i" "$A" "$B"

done

echo "======================================"
echo "Total Attempt : $TOTAL_ATTEMPT"
echo "Total Best    : $TOTAL_BEST /700"
echo "======================================"

########################################
# FINISH
########################################

echo
