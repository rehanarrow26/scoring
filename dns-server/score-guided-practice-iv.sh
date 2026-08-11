#!/usr/bin/env bash

# ================================================================
# DNS REVERSE ZONE CHECKER
# CHAPTER 10
# ================================================================

clear

ZONE_NAME="20.168.192.in-addr.arpa"
ZONE_FILE="/etc/bind/db.192.168.20"

DNS_IP="192.168.20.5"

DOMAIN="madinatulquran.lan"

score=0

echo "========================================="
echo "        DNS REVERSE ZONE CHECKER"
echo "             CHAPTER 10"
echo "========================================="
echo

########################################
# BIND9
########################################

echo -n "Checking Bind9 Installation......"

if dpkg -s bind9 >/dev/null 2>&1
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# SERVICE
########################################

echo -n "Checking Bind9 Service..........."

if systemctl is-active --quiet bind9
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# REVERSE ZONE
########################################

echo -n "Checking Reverse Zone............"

if grep -Eq \
'^[[:space:]]*zone[[:space:]]*"20\.168\.192\.in-addr\.arpa"' \
/etc/bind/named.conf.local
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# ZONE TYPE
########################################

echo -n "Checking Zone Type............"

if awk '
/zone "20\.168\.192\.in-addr\.arpa"/ {inside=1}
inside && /type[[:space:]]+master/ {found=1}
inside && /};/ {if(found) exit 0; inside=0}
END {if(found) exit 0; exit 1}
' /etc/bind/named.conf.local
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# ZONE FILE
########################################

echo -n "Checking Zone File................"

if [ -f "$ZONE_FILE" ]
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# SOA
########################################

echo -n "Checking SOA Record..............."

if grep -Eq \
'^[[:space:]]*@.*IN[[:space:]]+SOA[[:space:]]+dns\.madinatulquran\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# NS
########################################

echo -n "Checking NS Record................"

if grep -Eq \
'^[[:space:]]*@.*IN[[:space:]]+NS[[:space:]]+dns\.madinatulquran\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# PTR DNS SERVER
########################################

echo -n "Checking PTR 192.168.20.5........."

if grep -Eq \
'^[[:space:]]*5[[:space:]]+IN[[:space:]]+PTR[[:space:]]+dns\.madinatulquran\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    score=$((score+15))
else
    echo "[FAIL]"
fi

########################################
# PTR WEB
########################################

echo -n "Checking PTR 192.168.20.10........"

if grep -Eq \
'^[[:space:]]*10[[:space:]]+IN[[:space:]]+PTR[[:space:]]+web\.madinatulquran\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# PTR MAIL
########################################

echo -n "Checking PTR 192.168.20.20........"

if grep -Eq \
'^[[:space:]]*20[[:space:]]+IN[[:space:]]+PTR[[:space:]]+mail\.madinatulquran\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# NAMED CHECKCONF
########################################

echo -n "Checking named-checkconf.........."

if named-checkconf >/dev/null 2>&1
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# NAMED CHECKZONE
########################################

echo -n "Checking named-checkzone.........."

if named-checkzone \
    "$ZONE_NAME" \
    "$ZONE_FILE" >/dev/null 2>&1
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

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
    echo "Reverse DNS berhasil dikonfigurasi."
else
    echo
    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi Reverse DNS."
fi

echo

# result.json
cat > result.json <<EOF
{
    "chapter_id": 10,
    "score": $score,
    "status": "$([ "$score" -eq 100 ] && echo PASS || echo FAIL)"
}
EOF
