#!/usr/bin/env bash

# ================================================================
# DNS MASTER & SLAVE CHECKER
# CHAPTER 13 (UPDATED SLAVE IP: 192.168.10.12)
# ================================================================

clear

CHAPTER_ID=13
DOMAIN="labnet.lan"
ZONE_FILE="/etc/bind/db.labnet.lan"
MASTER_IP="192.168.10.10"
SLAVE_IP="192.168.10.12"

score=0

echo "========================================="
echo "       DNS MASTER & SLAVE CHECKER"
echo "               CHAPTER 13"
echo "========================================="
echo

########################################
# BIND9 INSTALLATION
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
# SERVICE STATUS
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
# MASTER ZONE CONFIG
########################################

echo -n "Checking Master Zone Config......"

if grep -Eq \
'^[[:space:]]*zone[[:space:]]*"labnet\.lan"' \
/etc/bind/named.conf.local
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# ZONE TYPE MASTER
########################################

echo -n "Checking Zone Type Master........"

if awk '
/zone "labnet\.lan"/ {inside=1}
inside && /type[[:space:]]+master;/ {found=1}
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
# ALLOW TRANSFER CONFIG (FIXED MULTI-LINE)
########################################

echo -n "Checking Allow Transfer Config..."

if awk -v slave="$SLAVE_IP" '
/zone "labnet\.lan"/ { inside=1 }
inside && /allow-transfer/ { in_trans=1 }
in_trans && $0 ~ slave { found=1 }
in_trans && /;/ { in_trans=0 }
inside && /};/ { if(found) exit 0; inside=0 }
END { if(found) exit 0; exit 1 }
' /etc/bind/named.conf.local
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# ZONE FILE EKSISTENSI
########################################

echo -n "Checking Zone File Existence....."

if [ -f "$ZONE_FILE" ]
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# SOA RECORD
########################################

echo -n "Checking SOA Record.............."

if grep -Eq \
'^[[:space:]]*@.*IN[[:space:]]+SOA[[:space:]]+dns-master\.labnet\.lan\.' \
"$ZONE_FILE"
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# DUAL NS RECORDS
########################################

echo -n "Checking Dual NS Records........."

if grep -Eq '^[[:space:]]*@.*IN[[:space:]]+NS[[:space:]]+dns-master\.labnet\.lan\.' "$ZONE_FILE" && \
   grep -Eq '^[[:space:]]*@.*IN[[:space:]]+NS[[:space:]]+dns-slave\.labnet\.lan\.' "$ZONE_FILE"
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# A RECORDS (www, mail, ftp)
########################################

echo -n "Checking Core A Records.........."

if grep -Eq '^[[:space:]]*www[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.168\.10\.20' "$ZONE_FILE" && \
   grep -Eq '^[[:space:]]*mail[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.168\.10\.21' "$ZONE_FILE" && \
   grep -Eq '^[[:space:]]*ftp[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.168\.10\.22' "$ZONE_FILE"
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# NAMED CHECKCONF
########################################

echo -n "Checking named-checkconf........."

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

echo -n "Checking named-checkzone........."

if named-checkzone "$DOMAIN" "$ZONE_FILE" >/dev/null 2>&1
then
    echo "[PASS]"
    score=$((score+5))
else
    echo "[FAIL]"
fi

########################################
# MASTER QUERY TEST
########################################

echo -n "Testing Query to Master.........."

if dig +short @127.0.0.1 www.labnet.lan 2>/dev/null | grep -q "192.168.10.20"
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# SLAVE QUERY TEST (ZONE TRANSFER CHECK)
########################################

echo -n "Testing Query to Slave (Replication)..."

if dig +short @"$SLAVE_IP" www.labnet.lan 2>/dev/null | grep -q "192.168.10.20"
then
    echo "[PASS]"
    score=$((score+10))
else
    echo "[FAIL]"
fi

########################################
# FINAL EVALUATION & RESULT
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
    echo "DNS Master & Slave Zone Transfer berhasil dikonfigurasi."
else
    echo
    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi Master, Slave, atau akses Zone Transfer."
fi

echo

# Export JSON Output
cat > result.json <<EOF
{
    "chapter_id": $CHAPTER_ID,
    "score": $score,
    "status": "$([ "$score" -eq 100 ] && echo PASS || echo FAIL)"
}
EOF
