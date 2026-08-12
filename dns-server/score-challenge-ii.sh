#!/bin/bash

clear

########################################
# CONFIG
########################################

DNS_SERVER="192.168.10.5"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"

score=0

########################################
# HEADER
########################################

echo "========================================="
echo "       DNS REVERSE ZONE CHECKER"
echo "             CHAPTER 11"
echo "========================================="
echo

########################################
# HELPER
########################################

pass_check() {
    echo "[PASS]"
    score=$((score + $1))
}

fail_check() {
    echo "[FAIL]"
}

########################################
# CHECK BIND9
########################################

echo -n "Checking Bind9 Installation......"

if dpkg -s bind9 >/dev/null 2>&1
then
    pass_check 5
else
    fail_check
fi

########################################
# CHECK BIND9 SERVICE
########################################

echo -n "Checking Bind9 Service..........."

if systemctl is-active --quiet bind9
then
    pass_check 5
else
    fail_check
fi

echo

########################################
# CHALLENGE 1
########################################

echo "-----------------------------------------"
echo "Challenge 1 - Server Akademik"
echo "-----------------------------------------"

ZONE1="30.168.192.in-addr.arpa"
FILE1="/etc/bind/db.192.168.30"
IP1="192.168.30.10"
HOST1="server.akademik.lan."

echo -n "Checking Reverse Zone.............."

if grep -Eq "zone[[:space:]]+\"$ZONE1\"" /etc/bind/named.conf.local
then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if [ -f "$FILE1" ]
then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if [ -f "$FILE1" ] &&
   grep -Eq "^[[:space:]]*10[[:space:]]+IN[[:space:]]+PTR[[:space:]]+$HOST1"
then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 2
########################################

echo
echo "-----------------------------------------"
echo "Challenge 2 - Laboratorium"
echo "-----------------------------------------"

ZONE2="10.10.10.in-addr.arpa"
FILE2="/etc/bind/db.10.10.10"
IP2="10.10.10.20"
HOST2="server.lab.lan."

echo -n "Checking Reverse Zone.............."

if grep -Eq "zone[[:space:]]+\"$ZONE2\"" /etc/bind/named.conf.local
then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if [ -f "$FILE2" ]
then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if [ -f "$FILE2" ] &&
   grep -Eq "^[[:space:]]*20[[:space:]]+IN[[:space:]]+PTR[[:space:]]+$HOST2"
then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 3
########################################

echo
echo "-----------------------------------------"
echo "Challenge 3 - Perpustakaan"
echo "-----------------------------------------"

ZONE3="50.16.172.in-addr.arpa"
FILE3="/etc/bind/db.172.16.50"
IP3="172.16.50.15"
HOST3="library.perpus.lan."

echo -n "Checking Reverse Zone.............."

if grep -Eq "zone[[:space:]]+\"$ZONE3\"" /etc/bind/named.conf.local
then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if [ -f "$FILE3" ]
then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if [ -f "$FILE3" ] &&
   grep -Eq "^[[:space:]]*15[[:space:]]+IN[[:space:]]+PTR[[:space:]]+$HOST3"
then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 4
########################################

echo
echo "-----------------------------------------"
echo "Challenge 4 - E-Learning"
echo "-----------------------------------------"

ZONE4="40.168.192.in-addr.arpa"
FILE4="/etc/bind/db.192.168.40"
IP4="192.168.40.25"
HOST4="lms.elearning.lan."

echo -n "Checking Reverse Zone.............."

if grep -Eq "zone[[:space:]]+\"$ZONE4\"" /etc/bind/named.conf.local
then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if [ -f "$FILE4" ]
then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if [ -f "$FILE4" ] &&
   grep -Eq "^[[:space:]]*25[[:space:]]+IN[[:space:]]+PTR[[:space:]]+$HOST4"
then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 5
########################################

echo
echo "-----------------------------------------"
echo "Challenge 5 - Monitoring"
echo "-----------------------------------------"

ZONE5="50.168.192.in-addr.arpa"
FILE5="/etc/bind/db.192.168.50"
IP5="192.168.50.30"
HOST5="grafana.monitor.lan."

echo -n "Checking Reverse Zone.............."

if grep -Eq "zone[[:space:]]+\"$ZONE5\"" /etc/bind/named.conf.local
then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if [ -f "$FILE5" ]
then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if [ -f "$FILE5" ] &&
   grep -Eq "^[[:space:]]*30[[:space:]]+IN[[:space:]]+PTR[[:space:]]+$HOST5"
then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 6
########################################

echo
echo "-----------------------------------------"
echo "Challenge 6 - Web & Database"
echo "-----------------------------------------"

ZONE6="60.168.192.in-addr.arpa"
FILE6="/etc/bind/db.192.168.60"

echo -n "Checking Reverse Zone.............."

if grep -Eq "zone[[:space:]]+\"$ZONE6\"" /etc/bind/named.conf.local
then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if [ -f "$FILE6" ]
then
    pass_check 2
else
    fail_check
fi

echo -n "Checking Web PTR..................."

if [ -f "$FILE6" ] &&
   grep -Eq "^[[:space:]]*10[[:space:]]+IN[[:space:]]+PTR[[:space:]]+web\.sekolah60\.lan\."
then
    pass_check 5
else
    fail_check
fi

echo -n "Checking Database PTR.............."

if [ -f "$FILE6" ] &&
   grep -Eq "^[[:space:]]*20[[:space:]]+IN[[:space:]]+PTR[[:space:]]+database\.sekolah60\.lan\."
then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 7
########################################

echo
echo "-----------------------------------------"
echo "Challenge 7 - Infrastruktur"
echo "-----------------------------------------"

ZONE7="30.20.10.in-addr.arpa"
FILE7="/etc/bind/db.10.20.30"

echo -n "Checking Reverse Zone.............."

if grep -Eq "zone[[:space:]]+\"$ZONE7\"" /etc/bind/named.conf.local
then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if [ -f "$FILE7" ]
then
    pass_check 2
else
    fail_check
fi

echo -n "Checking Web PTR..................."

if [ -f "$FILE7" ] &&
   grep -Eq "^[[:space:]]*10[[:space:]]+IN[[:space:]]+PTR[[:space:]]+web\.infra\.lan\."
then
    pass_check 4
else
    fail_check
fi

echo -n "Checking Mail PTR.................."

if [ -f "$FILE7" ] &&
   grep -Eq "^[[:space:]]*20[[:space:]]+IN[[:space:]]+PTR[[:space:]]+mail\.infra\.lan\."
then
    pass_check 4
else
    fail_check
fi

echo -n "Checking Backup PTR................"

if [ -f "$FILE7" ] &&
   grep -Eq "^[[:space:]]*30[[:space:]]+IN[[:space:]]+PTR[[:space:]]+backup\.infra\.lan\."
then
    pass_check 4
else
    fail_check
fi

########################################
# BIND VALIDATION
########################################

echo
echo "-----------------------------------------"
echo "DNS Validation"
echo "-----------------------------------------"

echo -n "Checking named-checkconf.........."

if named-checkconf >/dev/null 2>&1
then
    pass_check 5
else
    fail_check
fi

echo -n "Checking named-checkzone.........."

ZONE_OK=0

for ZONE_FILE in \
    "$FILE1" \
    "$FILE2" \
    "$FILE3" \
    "$FILE4" \
    "$FILE5" \
    "$FILE6" \
    "$FILE7"
do
    if [ -f "$ZONE_FILE" ]
    then
        case "$ZONE_FILE" in

            "$FILE1")
                named-checkzone "$ZONE1" "$ZONE_FILE" >/dev/null 2>&1 && ZONE_OK=$((ZONE_OK+1))
                ;;

            "$FILE2")
                named-checkzone "$ZONE2" "$ZONE_FILE" >/dev/null 2>&1 && ZONE_OK=$((ZONE_OK+1))
                ;;

            "$FILE3")
                named-checkzone "$ZONE3" "$ZONE_FILE" >/dev/null 2>&1 && ZONE_OK=$((ZONE_OK+1))
                ;;

            "$FILE4")
                named-checkzone "$ZONE4" "$ZONE_FILE" >/dev/null 2>&1 && ZONE_OK=$((ZONE_OK+1))
                ;;

            "$FILE5")
                named-checkzone "$ZONE5" "$ZONE_FILE" >/dev/null 2>&1 && ZONE_OK=$((ZONE_OK+1))
                ;;

            "$FILE6")
                named-checkzone "$ZONE6" "$ZONE_FILE" >/dev/null 2>&1 && ZONE_OK=$((ZONE_OK+1))
                ;;

            "$FILE7")
                named-checkzone "$ZONE7" "$ZONE_FILE" >/dev/null 2>&1 && ZONE_OK=$((ZONE_OK+1))
                ;;

        esac
    fi
done

if [ "$ZONE_OK" -eq 7 ]
then
    pass_check 10
else
    fail_check
    echo "Valid zones : $ZONE_OK / 7"
fi

########################################
# DNS FUNCTIONAL TEST
########################################

echo
echo "-----------------------------------------"
echo "Reverse DNS Functional Test"
echo "-----------------------------------------"

check_ptr() {

    IP="$1"
    EXPECTED="$2"

    RESULT=$(dig @"$DNS_SERVER" -x "$IP" +short 2>/dev/null |
        sed 's/[[:space:]]*$//')

    if [ "$RESULT" = "$EXPECTED" ]
    then
        echo "Checking PTR $IP.................[PASS]"
        return 0
    else
        echo "Checking PTR $IP.................[FAIL]"
        echo "Expected : $EXPECTED"
        echo "Result   : ${RESULT:-No Answer}"
        return 1
    fi
}

########################################
# FUNCTIONAL SCORE
########################################

check_ptr "$IP1" "$HOST1" && score=$((score+2))
check_ptr "$IP2" "$HOST2" && score=$((score+2))
check_ptr "$IP3" "$HOST3" && score=$((score+2))
check_ptr "$IP4" "$HOST4" && score=$((score+2))
check_ptr "$IP5" "$HOST5" && score=$((score+2))
check_ptr "192.168.60.10" "web.sekolah60.lan." && score=$((score+2))
check_ptr "192.168.60.20" "database.sekolah60.lan." && score=$((score+2))
check_ptr "10.20.30.10" "web.infra.lan." && score=$((score+2))
check_ptr "10.20.30.20" "mail.infra.lan." && score=$((score+2))
check_ptr "10.20.30.30" "backup.infra.lan." && score=$((score+2))

########################################
# LIMIT SCORE
########################################

if [ "$score" -gt 100 ]
then
    score=100
fi

########################################
# STATUS
########################################

if [ "$score" -eq 100 ]
then
    STATUS="PASS"
else
    STATUS="FAIL"
fi

########################################
# RESULT JSON
########################################

cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": 11,
  "score": $score,
  "status": "$STATUS"
}
EOF

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
    echo "DNS Reverse Zone berhasil dikonfigurasi."
else
    echo
    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi Reverse DNS."
fi

echo
