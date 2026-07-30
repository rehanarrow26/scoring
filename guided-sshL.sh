########################################
# CONFIG
########################################

CLIENT_USER="developer"
SERVER_USER="admin"

CLIENT_IP="192.168.10.10"
SERVER_IP="192.168.10.2"

KEY_NAME="dev-server"

CLIENT_KEY="/home/$CLIENT_USER/.ssh/$KEY_NAME"
CLIENT_PUB="/home/$CLIENT_USER/.ssh/$KEY_NAME.pub"

score=0

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
# CHECK USER
########################################

echo -n "Checking User......................."

if id "$CLIENT_USER" &>/dev/null
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# CHECK CLIENT IP
########################################

echo -n "Checking Client IP................."

if ip a | grep -qw "$CLIENT_IP"
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

echo -n "Checking Private Key..............."

if [ -f "$CLIENT_KEY" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK PUBLIC KEY
########################################

echo -n "Checking Public Key................"

if [ -f "$CLIENT_PUB" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK SSH LOGIN
########################################

echo -n "Checking SSH Login................"

RESULT=$(REMOTE "echo OK" 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
    echo
    echo "Tidak dapat login menggunakan SSH Key."
    echo "Pastikan ssh-copy-id telah berhasil."
    exit
fi

########################################
# CHECK .SSH DIRECTORY
########################################

echo -n "Checking .ssh Directory............"

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

echo -n "Checking authorized_keys..........."

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

echo -n "Checking Registered Public Key....."

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

echo -n "Checking .ssh Permission..........."

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

echo -n "Checking Ownership................."

OWNER=$(REMOTE "stat -c %U ~/.ssh/authorized_keys")

if [ "$OWNER" = "$SERVER_USER" ]
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# FINAL SCORE
########################################

echo
echo "========================================="
echo "Final Score : $score /100"
echo "========================================="

if [ "$score" -eq 100 ]
then
    echo
    echo "MISSION COMPLETE"
    echo
    echo "Congratulations!"
    echo "SSH Key Authentication berhasil dikonfigurasi."
else
    echo
    echo "MISSION FAILED"
    echo
    echo "Perbaiki konfigurasi yang masih gagal,"
    echo "kemudian jalankan checker kembali."
fi1~########################################
# CONFIG
########################################

CLIENT_USER="developer"
SERVER_USER="admin"

CLIENT_IP="192.168.10.10"
SERVER_IP="192.168.10.2"

KEY_NAME="dev-server"

CLIENT_KEY="/home/$CLIENT_USER/.ssh/$KEY_NAME"
CLIENT_PUB="/home/$CLIENT_USER/.ssh/$KEY_NAME.pub"

score=0

########################################
# REMOTE SSH
########################################

REMOTE(){

sudo -u "$CLIENT_USER" ssh \
-i "$CLIENT_KEY" \
-o BatchMode=yes \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-o ConnectTimeout=5 \
"$SERVER_USER@$SERVER_IP" "$1"

}

########################################
# CHECK USER
########################################

echo -n "Checking User......................."

if id "$CLIENT_USER" &>/dev/null
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# CHECK CLIENT IP
########################################

echo -n "Checking Client IP................."

if ip a | grep -qw "$CLIENT_IP"
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

echo -n "Checking Private Key..............."

if [ -f "$CLIENT_KEY" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK PUBLIC KEY
########################################

echo -n "Checking Public Key................"

if [ -f "$CLIENT_PUB" ]
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# CHECK SSH LOGIN
########################################

echo -n "Checking SSH Login................"

RESULT=$(REMOTE "echo OK" 2>/dev/null)

if [ "$RESULT" = "OK" ]
then
    echo "[PASS]"
    score=$((score+20))
else
    echo "[FAIL]"
    echo
    echo "Tidak dapat login menggunakan SSH Key."
    echo "Pastikan ssh-copy-id telah berhasil."
    exit
fi

########################################
# CHECK .SSH DIRECTORY
########################################

echo -n "Checking .ssh Directory............"

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

echo -n "Checking authorized_keys..........."

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

echo -n "Checking Registered Public Key....."

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

echo -n "Checking .ssh Permission..........."

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

echo -n "Checking Ownership................."

OWNER=$(REMOTE "stat -c %U ~/.ssh/authorized_keys")

if [ "$OWNER" = "$SERVER_USER" ]
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# FINAL SCORE
########################################

echo
echo "========================================="
echo "Final Score : $score /100"
echo "========================================="

if [ "$score" -eq 100 ]
then
    echo
    echo "MISSION COMPLETE"
    echo
    echo "Congratulations!"
    echo "SSH Key Authentication berhasil dikonfigurasi."
else
    echo
    echo "MISSION FAILED"
    echo
    echo "Perbaiki konfigurasi yang masih gagal,"
    echo "kemudian jalankan checker kembali."
fi
