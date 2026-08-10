#!/bin/bash

clear

CHAPTER_ID=7

LAB_DIR="$HOME/.lab"
RESULT_FILE="$LAB_DIR/result.json"

score=0
DETAIL=""

echo "========================================="
echo "        DNS PRIMARY CHECKER"
echo "        CHAPTER 7"
echo "========================================="
echo

add_result() {

    local NAME="$1"
    local STATUS="$2"
    local POINT="$3"
    local MESSAGE="$4"

    if [ "$STATUS" = "PASS" ]; then
        score=$((score+POINT))
    fi

    if [ -n "$DETAIL" ]; then
        DETAIL="$DETAIL,"
    fi

    DETAIL="$DETAIL\"$NAME\":{\"status\":\"$STATUS\",\"score\":$POINT"

    if [ -n "$MESSAGE" ]; then
        MESSAGE=$(echo "$MESSAGE" | sed 's/"/\\"/g')
        DETAIL="$DETAIL,\"message\":\"$MESSAGE\""
    fi

    DETAIL="$DETAIL}"
}

########################################
# BIND9
########################################

echo -n "Checking Bind9 Installation......"

if dpkg -s bind9 >/dev/null 2>&1; then
    echo "[PASS]"
    add_result "Bind9" "PASS" 10 ""
else
    echo "[FAIL]"
    add_result "Bind9" "FAIL" 10 "Bind9 belum terinstall."
fi

########################################
# SERVICE
########################################

echo -n "Checking Bind9 Service..........."

if systemctl is-active --quiet bind9; then
    echo "[PASS]"
    add_result "Service" "PASS" 10 ""
else
    echo "[FAIL]"
    add_result "Service" "FAIL" 10 "Bind9 tidak aktif."
fi

echo
echo "Current Score : $score"
echo

########################################
# ZONE
########################################

echo -n "Checking DNS Zone................."

if grep -Eq 'zone[[:space:]]+"sekolah\.lan"' \
    /etc/bind/named.conf.local; then

    echo "[PASS]"
    add_result "Zone" "PASS" 15 ""

else

    echo "[FAIL]"
    add_result "Zone" "FAIL" 15 "Zone sekolah.lan tidak ditemukan."

fi

########################################
# TYPE MASTER
########################################

echo -n "Checking Zone Type..............."

if grep -A4 -Eq 'zone[[:space:]]+"sekolah\.lan"' \
    /etc/bind/named.conf.local &&
   grep -A4 -Eq 'type[[:space:]]+master' \
    /etc/bind/named.conf.local; then

    echo "[PASS]"
    add_result "TypeMaster" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "TypeMaster" "FAIL" 5 "Zone bukan master."

fi

########################################
# ZONE FILE
########################################

echo -n "Checking Zone File..............."

if grep -A5 -Eq 'zone[[:space:]]+"sekolah\.lan"' \
    /etc/bind/named.conf.local &&
   grep -Eq 'file[[:space:]]+"/etc/bind/db\.sekolah"' \
    /etc/bind/named.conf.local; then

    echo "[PASS]"
    add_result "ZoneFile" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "ZoneFile" "FAIL" 5 "Zone file salah."

fi

########################################
# DB FILE
########################################

echo -n "Checking db.sekolah............"

if [ -f /etc/bind/db.sekolah ]; then

    echo "[PASS]"
    add_result "db.sekolah" "PASS" 10 ""

else

    echo "[FAIL]"
    add_result "db.sekolah" "FAIL" 10 "File db.sekolah tidak ditemukan."

fi

echo
echo "Current Score : $score"
echo

########################################
# SOA
########################################

echo -n "Checking SOA Record.............."

if grep -Eq \
'^[[:space:]]*@.*IN[[:space:]]+SOA[[:space:]]+sekolah\.lan\.' \
/etc/bind/db.sekolah; then

    echo "[PASS]"
    add_result "SOA" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "SOA" "FAIL" 5 "SOA salah."

fi

########################################
# NS
########################################

echo -n "Checking NS Record..............."

if grep -Eq \
'^[[:space:]]*@.*IN[[:space:]]+NS[[:space:]]+ns1\.sekolah\.lan\.' \
/etc/bind/db.sekolah; then

    echo "[PASS]"
    add_result "NS" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "NS" "FAIL" 5 "NS salah."

fi

########################################
# NS1
########################################

echo -n "Checking ns1 Record.............."

if grep -Eq \
'^[[:space:]]*ns1[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.168\.10\.5' \
/etc/bind/db.sekolah; then

    echo "[PASS]"
    add_result "NS1" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "NS1" "FAIL" 5 "Record ns1 salah."

fi

########################################
# NS2
########################################

echo -n "Checking ns2 Record.............."

if grep -Eq \
'^[[:space:]]*ns2[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.168\.10\.5' \
/etc/bind/db.sekolah; then

    echo "[PASS]"
    add_result "NS2" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "NS2" "FAIL" 5 "Record ns2 salah."

fi

########################################
# WWW
########################################

echo -n "Checking WWW Record.............."

if grep -Eq \
'^[[:space:]]*www[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.168\.10\.5' \
/etc/bind/db.sekolah; then

    echo "[PASS]"
    add_result "WWW" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "WWW" "FAIL" 5 "Record www salah."

fi

########################################
# MAIL
########################################

echo -n "Checking Mail Record............."

if grep -Eq \
'^[[:space:]]*mail[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.168\.10\.5' \
/etc/bind/db.sekolah; then

    echo "[PASS]"
    add_result "MAIL" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "MAIL" "FAIL" 5 "Record mail salah."

fi

########################################
# MX
########################################

echo -n "Checking MX Record..............."

if grep -Eq \
'^[[:space:]]*@.*IN[[:space:]]+MX[[:space:]]+10[[:space:]]+mail\.sekolah\.lan\.' \
/etc/bind/db.sekolah; then

    echo "[PASS]"
    add_result "MX" "PASS" 5 ""

else

    echo "[FAIL]"
    add_result "MX" "FAIL" 5 "MX record salah."

fi

echo
echo "Current Score : $score"
echo

########################################
# CHECKCONF
########################################

echo -n "Checking named-checkconf........."

if named-checkconf >/dev/null 2>&1; then

    echo "[PASS]"
    add_result "named-checkconf" "PASS" 5 "Configuration OK"

else

    echo "[FAIL]"
    add_result "named-checkconf" "FAIL" 5 "Configuration error."

fi

########################################
# CHECKZONE
########################################

echo -n "Checking named-checkzone........."

if named-checkzone \
    sekolah.lan \
    /etc/bind/db.sekolah >/dev/null 2>&1; then

    echo "[PASS]"
    add_result "named-checkzone" "PASS" 5 "Zone OK"

else

    echo "[FAIL]"
    add_result "named-checkzone" "FAIL" 5 "Zone error."

fi

########################################
# STATUS
########################################

if [ "$score" -eq 100 ]; then
    STATUS="done"
else
    STATUS="failed"
fi

########################################
# RESULT
########################################

mkdir -p "$LAB_DIR"

cat > "$RESULT_FILE" <<EOF
{
    "chapter_id": $CHAPTER_ID,
    "score": $score,
    "status": "$STATUS",
    "detail": {
        $DETAIL
    }
}
EOF

########################################
# FINAL
########################################

echo
echo "========================================="
echo "Score : $score /100"
echo "========================================="
echo

if [ "$score" -eq 100 ]; then

    echo "MISSION COMPLETE"
    echo
    echo "DNS Primary Server sekolah.lan berhasil dikonfigurasi."

else

    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi DNS."

fi

echo
echo "Result saved to:"
echo "$RESULT_FILE"
echo
