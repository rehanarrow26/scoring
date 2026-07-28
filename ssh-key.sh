#!/bin/bash

#############################################
# SSH KEY AUTO CHECKER
# Version : 1.0
#############################################

clear

PROGRESS="/root/.sshkey_progress"
KEY_DIR="/home/scorer/keys"

#############################################
# Create Progress File
#############################################

if [ ! -f "$PROGRESS" ]
then

    for i in {1..7}
    do
        echo "S${i}_ATTEMPT=0" >> "$PROGRESS"
        echo "S${i}_BEST=0" >> "$PROGRESS"
        echo "S${i}_LAST=0" >> "$PROGRESS"
    done

fi

#############################################
# Title
#############################################

echo "==========================================="
echo "        SSH KEY AUTO CHECKER"
echo "==========================================="
echo

#############################################
# Choose Question
#############################################

read -p "Nomor Soal (1-7) : " SOAL

case "$SOAL" in

1)
    USER_EXPECT="eko"
    IP_EXPECT="192.168.10.2"
    KEY_EXPECT="office-key"
;;

2)
    USER_EXPECT="database"
    IP_EXPECT="192.168.10.3"
    KEY_EXPECT="db-access"
;;

3)
    USER_EXPECT="operator"
    IP_EXPECT="192.168.10.4"
    KEY_EXPECT="ops-login"
;;

4)
    USER_EXPECT="webadmin"
    IP_EXPECT="192.168.10.5"
    KEY_EXPECT="web-prod"
;;

5)
    USER_EXPECT="security"
    IP_EXPECT="192.168.10.6"
    KEY_EXPECT="secure-login"
;;

6)
    USER_EXPECT="developer"
    IP_EXPECT="192.168.10.7"
    KEY_EXPECT="dev-server"
;;

7)
    USER_EXPECT="administrator"
    IP_EXPECT="192.168.10.8"
    KEY_EXPECT="production-key"
;;

*)
    echo
    echo "Nomor soal tidak valid."
    exit
;;

esac

#############################################
# Initial Score
#############################################

score=0

#############################################
# Load Progress
#############################################

source "$PROGRESS"

eval ATTEMPT=\$S${SOAL}_ATTEMPT
eval BEST=\$S${SOAL}_BEST
eval LAST=\$S${SOAL}_LAST

#############################################
# Information
#############################################

echo
echo "==========================================="
echo "User      : $USER_EXPECT"
echo "IP        : $IP_EXPECT"
echo "PrivateKey: $KEY_EXPECT"
echo "==========================================="
echo

#############################################
# Function
#############################################

pass(){

    echo "[PASS]"
}

fail(){

    echo "[FAIL]"
}

#############################################
# Function Progress
#############################################

save_progress(){

    ATTEMPT=$((ATTEMPT+1))

    if [ "$score" -gt "$BEST" ]
    then
        BEST=$score
    fi

    LAST=$score

    sed -i "s/^S${SOAL}_ATTEMPT=.*/S${SOAL}_ATTEMPT=$ATTEMPT/" "$PROGRESS"
    sed -i "s/^S${SOAL}_BEST=.*/S${SOAL}_BEST=$BEST/" "$PROGRESS"
    sed -i "s/^S${SOAL}_LAST=.*/S${SOAL}_LAST=$LAST/" "$PROGRESS"

}

#############################################
# Function Progress Viewer
#############################################

show_progress(){

source "$PROGRESS"

TOTAL=0

for i in {1..7}
do

    eval A=\$S${i}_ATTEMPT
    TOTAL=$((TOTAL+A))

done

echo
echo "==========================================="
echo "       SSH KEY PRACTICE PROGRESS"
echo "==========================================="
echo
echo "Total Attempt : $TOTAL"
echo

for i in {1..7}
do

    eval A=\$S${i}_ATTEMPT
    eval B=\$S${i}_BEST
    eval L=\$S${i}_LAST

    echo "-------------------------------------------"
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

}

#############################################
# PART 2
#############################################
#
# Check User
# Check IP
# Check .ssh
# Check authorized_keys
# Check Permission
# Check Ownership
#
#############################################

#############################################
# Check User
#############################################

check_user(){

    echo -n "Checking User......................."

    if id "$USER_EXPECT" >/dev/null 2>&1
    then
        pass
        score=$((score+10))
        return 0
    else
        fail
        return 1
    fi

}

#############################################
# Check IP Address
#############################################

check_ip(){

    echo -n "Checking IP Address................."

    if ip -4 addr show | grep -qw "$IP_EXPECT"
    then
        pass
        score=$((score+10))
        return 0
    else
        fail
        return 1
    fi

}

#############################################
# Check .ssh Directory
#############################################

check_ssh_dir(){

    echo -n "Checking .ssh Directory............"

    SSH_DIR=$(eval echo "~$USER_EXPECT")/.ssh

    if [ -d "$SSH_DIR" ]
    then
        pass
        score=$((score+10))
        return 0
    else
        fail
        return 1
    fi

}

#############################################
# Check authorized_keys
#############################################

check_authorized_keys(){

    echo -n "Checking authorized_keys..........."

    AUTH_FILE=$(eval echo "~$USER_EXPECT")/.ssh/authorized_keys

    if [ -f "$AUTH_FILE" ]
    then
        pass
        score=$((score+10))
        return 0
    else
        fail
        return 1
    fi

}

#############################################
# Check .ssh Permission
#############################################

check_ssh_permission(){

    echo -n "Checking .ssh Permission..........."

    SSH_DIR=$(eval echo "~$USER_EXPECT")/.ssh

    PERM=$(stat -c %a "$SSH_DIR" 2>/dev/null)

    if [ "$PERM" = "700" ]
    then
        pass
        score=$((score+10))
        return 0
    else
        fail
        echo "    Expected : 700"
        echo "    Current  : ${PERM:-Not Found}"
        return 1
    fi

}

#############################################
# Check authorized_keys Permission
#############################################

check_auth_permission(){

    echo -n "Checking authorized_keys Permission"

    AUTH_FILE=$(eval echo "~$USER_EXPECT")/.ssh/authorized_keys

    PERM=$(stat -c %a "$AUTH_FILE" 2>/dev/null)

    if [ "$PERM" = "600" ]
    then
        pass
        score=$((score+10))
        return 0
    else
        fail
        echo "    Expected : 600"
        echo "    Current  : ${PERM:-Not Found}"
        return 1
    fi

}

#############################################
# Check Ownership
#############################################

check_owner(){

    echo -n "Checking Ownership................."

    AUTH_FILE=$(eval echo "~$USER_EXPECT")/.ssh/authorized_keys

    OWNER=$(stat -c %U "$AUTH_FILE" 2>/dev/null)
    GROUP=$(stat -c %G "$AUTH_FILE" 2>/dev/null)

    if [ "$OWNER" = "$USER_EXPECT" ] && [ "$GROUP" = "$USER_EXPECT" ]
    then
        pass
        score=$((score+10))
        return 0
    else
        fail
        echo "    Expected : ${USER_EXPECT}:${USER_EXPECT}"
        echo "    Current  : ${OWNER:-Unknown}:${GROUP:-Unknown}"
        return 1
    fi

}

#############################################
# Run Linux Configuration Checks
#############################################

echo
echo "========== Linux Configuration =========="
echo

check_user
check_ip
check_ssh_dir
check_authorized_keys
check_ssh_permission
check_auth_permission
check_owner

#############################################
# PART 3
#############################################
#
# Check Private Key Upload
# Check SSH Login
# Cleanup Uploaded Key
#
#############################################

#############################################
# Check Private Key Upload
#############################################

check_private_key(){

    echo -n "Checking Private Key Upload........"

    KEY_FILE="$KEY_DIR/$KEY_EXPECT"

    if [ -f "$KEY_FILE" ]
    then
        pass
        score=$((score+10))
        return 0
    else
        fail
        echo "    Expected : $KEY_FILE"
        return 1
    fi

}

#############################################
# Check SSH Login
#############################################

check_ssh_login(){

    echo -n "Checking SSH Login................"

    KEY_FILE="$KEY_DIR/$KEY_EXPECT"

    RESULT=$(ssh \
        -i "$KEY_FILE" \
        -o BatchMode=yes \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=5 \
        ${USER_EXPECT}@${IP_EXPECT} \
        "echo OK" 2>&1)

    if echo "$RESULT" | grep -q "^OK$"
    then
        pass
        score=$((score+20))
        return 0
    else
        fail
        echo
        echo "Reason :"
        echo "$RESULT"
        return 1
    fi

}

#############################################
# Cleanup Uploaded Key
#############################################

cleanup_key(){

    KEY_FILE="$KEY_DIR/$KEY_EXPECT"

    if [ -f "$KEY_FILE" ]
    then
        rm -f "$KEY_FILE"
    fi

}

#############################################
# Run SSH Key Checks
#############################################

echo
echo "========== SSH Key Verification =========="
echo

check_private_key
check_ssh_login

#############################################
# Cleanup
#############################################

cleanup_key

#############################################
# PART 4
#############################################
#
# Save Progress
# Rank
# Title
# Final Score
# Show Progress
#
#############################################

#############################################
# Save Progress
#############################################

save_progress

#############################################
# Rank & Title
#############################################

if [ "$score" -ge 100 ]
then
    RANK="S"
    TITLE="SSH Key Master"

elif [ "$score" -ge 90 ]
then
    RANK="A"
    TITLE="Senior Linux Administrator"

elif [ "$score" -ge 80 ]
then
    RANK="B"
    TITLE="Linux Administrator"

elif [ "$score" -ge 70 ]
then
    RANK="C"
    TITLE="Junior Administrator"

elif [ "$score" -ge 60 ]
then
    RANK="D"
    TITLE="Linux Operator"

else
    RANK="E"
    TITLE="Linux Beginner"

fi

#############################################
# Mission Status
#############################################

if [ "$score" -eq 100 ]
then

    STATUS="COMPLETE"

else

    STATUS="INCOMPLETE"

fi

#############################################
# Remove Uploaded Key
#############################################

if [ "$score" -eq 100 ]
then

    cleanup_key

fi

#############################################
# Final Score
#############################################

echo
echo "==========================================="
echo "Score : $score /100"
echo "==========================================="
echo
echo "Rank            : $RANK"
echo "Title           : $TITLE"
echo
echo "Mission Status  : $STATUS"

#############################################
# Hint
#############################################

if [ "$score" -ne 100 ]
then

echo
echo "Hint :"
echo "- Pastikan user sesuai dengan soal."
echo "- Pastikan alamat IP sesuai."
echo "- Pastikan direktori ~/.ssh sudah dibuat."
echo "- Pastikan file authorized_keys tersedia."
echo "- Pastikan permission ~/.ssh = 700."
echo "- Pastikan permission authorized_keys = 600."
echo "- Pastikan owner file adalah user yang benar."
echo "- Pastikan Private Key sudah dikirim ke /home/scorer/keys."
echo "- Pastikan login menggunakan SSH Key berhasil."

fi

#############################################
# Progress
#############################################

show_progress

echo
echo "==========================================="
echo "SSH KEY AUTO CHECKER FINISHED"
echo "==========================================="
