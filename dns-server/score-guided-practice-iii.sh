#!/bin/bash

clear

LAB_DIR="$HOME/.lab"
RESULT_FILE="$LAB_DIR/result.json"

SCORE=0

echo "========================================="
echo "        DNS REVERSE ZONE CHECKER"
echo "              CHAPTER 9"
echo "========================================="
echo

########################################
# CONFIG
########################################

ZONE="10.168.192.in-addr.arpa"
ZONE_FILE="/etc/bind/db.192.168.10"

C1="FAIL"
C2="FAIL"
C3="FAIL"
C4="FAIL"
C5="FAIL"
C6="FAIL"
C7="FAIL"
C8="FAIL"
C9="FAIL"
C10="FAIL"
C11="FAIL"

########################################
# 1. REVERSE ZONE
########################################

echo -n "Checking Reverse Zone............"

if grep -Eq \
"^[[:space:]]*zone[[:space:]]+\"10\.168\.192\.in-addr\.arpa\"" \
/etc/bind/named.conf.local 2>/dev/null
then
    echo "[PASS]"
    C1="PASS"
    SCORE=$((SCORE+15))
else
    echo "[FAIL]"
fi

########################################
# 2. ZONE FILE
########################################

echo -n "Checking Zone File................"

if [ -f "$ZONE_FILE" ]; then
    echo "[PASS]"
    C2="PASS"
    SCORE=$((SCORE+10))
else
    echo "[FAIL]"
fi

########################################
# 3. SOA
########################################

echo -n "Checking SOA Record..............."

if [ -f "$ZONE_FILE" ] &&
   grep -Eq \
   "^[[:space:]]*@.*IN.*SOA.*dns-server-primary\.sekolah\.lan\." \
   "$ZONE_FILE"
then
    echo "[PASS]"
    C3="PASS"
    SCORE=$((SCORE+10))
else
    echo "[FAIL]"
fi

########################################
# 4. NS
########################################

echo -n "Checking NS Record................"

if [ -f "$ZONE_FILE" ] &&
   grep -Eq \
   "^[[:space:]]*@.*IN.*NS.*dns-server-primary\.sekolah\.lan\." \
   "$ZONE_FILE"
then
    echo "[PASS]"
    C4="PASS"
    SCORE=$((SCORE+10))
else
    echo "[FAIL]"
fi

########################################
# 5. PTR 192.168.10.5
########################################

echo -n "Checking PTR 192.168.10.5........."

if grep -Eq \
'^[[:space:]]*5[[:space:]]+IN[[:space:]]+PTR[[:space:]]+dns-server-primary\.sekolah\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    C5="PASS"
    SCORE=$((SCORE+15))
else
    echo "[FAIL]"
fi


########################################
# 6. PTR 192.168.10.11
########################################

echo -n "Checking PTR 192.168.10.11........"

if grep -Eq \
'^[[:space:]]*11[[:space:]]+IN[[:space:]]+PTR[[:space:]]+www\.sekolah\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    C6="PASS"
    SCORE=$((SCORE+10))
else
    echo "[FAIL]"
fi


########################################
# 7. PTR 192.168.10.12
########################################

echo -n "Checking PTR 192.168.10.12........"

if grep -Eq \
'^[[:space:]]*12[[:space:]]+IN[[:space:]]+PTR[[:space:]]+lab\.sekolah\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    C7="PASS"
    SCORE=$((SCORE+10))
else
    echo "[FAIL]"
fi


########################################
# 8. NAMED CHECKCONF
########################################

echo -n "Checking named-checkconf.........."

if named-checkconf >/dev/null 2>&1; then
    echo "[PASS]"
    C8="PASS"
    SCORE=$((SCORE+5))
else
    echo "[FAIL]"
fi

########################################
# 9. NAMED CHECKZONE
########################################

echo -n "Checking named-checkzone.........."

if [ -f "$ZONE_FILE" ] &&
   named-checkzone "$ZONE" "$ZONE_FILE" >/dev/null 2>&1
then
    echo "[PASS]"
    C9="PASS"
    SCORE=$((SCORE+5))
else
    echo "[FAIL]"
fi

########################################
# 10. SERVICE
########################################

echo -n "Checking Bind9 Service............"

if systemctl is-active --quiet bind9; then
    echo "[PASS]"
    C10="PASS"
    SCORE=$((SCORE+5))
else
    echo "[FAIL]"
fi

########################################
# 11. REVERSE LOOKUP
########################################

echo -n "Checking Reverse DNS.............."

LOOKUP1=$(dig +short @192.168.10.5 -x 192.168.10.5)
LOOKUP2=$(dig +short @192.168.10.5 -x 192.168.10.11)
LOOKUP3=$(dig +short @192.168.10.5 -x 192.168.10.12)

if [ -n "$LOOKUP1" ] &&
   [ -n "$LOOKUP2" ] &&
   [ -n "$LOOKUP3" ]; then
    echo "[PASS]"
    C11="PASS"
    SCORE=$((SCORE+5))
else
    echo "[FAIL]"
fi

########################################
# STATUS
########################################

if [ "$SCORE" -eq 100 ]; then
    STATUS="done"
else
    STATUS="failed"
fi

########################################
# RESULT
########################################

cat > "$RESULT_FILE" <<EOF
{
    "chapter_id": 9,
    "score": $SCORE,
    "status": "$STATUS",
    "detail": {
        "ReverseZone": {
            "status": "$C1",
            "score": 15
        },
        "ZoneFile": {
            "status": "$C2",
            "score": 10
        },
        "SOA": {
            "status": "$C3",
            "score": 10
        },
        "NS": {
            "status": "$C4",
            "score": 10
        },
        "PTR_DNS": {
            "status": "$C5",
            "score": 15
        },
        "PTR_WWW": {
            "status": "$C6",
            "score": 10
        },
        "PTR_LAB": {
            "status": "$C7",
            "score": 10
        },
        "NamedCheckConf": {
            "status": "$C8",
            "score": 5
        },
        "NamedCheckZone": {
            "status": "$C9",
            "score": 5
        },
        "Service": {
            "status": "$C10",
            "score": 5
        },
        "ReverseLookup": {
            "status": "$C11",
            "score": 5
        }
    }
}
EOF

echo
echo "========================================="
echo "Score : $SCORE /100"
echo "========================================="
echo

if [ "$SCORE" -eq 100 ]; then
    echo "MISSION COMPLETE"
else
    echo "MISSION FAILED"
fi

echo
