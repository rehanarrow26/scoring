#!/bin/bash

clear

CHAPTER_ID=8

LAB_DIR="$HOME/.lab"
RESULT_FILE="$LAB_DIR/result.json"

SCORE=0

C1_STATUS="FAIL"
C2_STATUS="FAIL"
C3_STATUS="FAIL"
C4_STATUS="FAIL"
C5_STATUS="FAIL"
C6_STATUS="FAIL"
C7_STATUS="FAIL"

echo "========================================="
echo "       DNS FORWARD ZONE CHALLENGE"
echo "              CHAPTER 8"
echo "========================================="
echo

########################################
# HELPER
########################################

zone_exists() {
    local zone="$1"

    grep -Eq \
        "^[[:space:]]*zone[[:space:]]+\"${zone}\"[[:space:]]*\{" \
        /etc/bind/named.conf.local
}

zone_valid() {
    local zone="$1"
    local file="$2"

    [ -f "$file" ] || return 1

    named-checkzone "$zone" "$file" >/dev/null 2>&1
}

dns_a() {
    local host="$1"

    dig +short @127.0.0.1 "$host" A 2>/dev/null |
        grep -Fxq "$2"
}

dns_cname() {
    local host="$1"
    local target="$2"

    dig +short @127.0.0.1 "$host" CNAME 2>/dev/null |
        sed 's/\.$//' |
        grep -Fxq "$target"
}

########################################
# CHALLENGE 1
########################################

echo -n "Challenge 1......................"

C1=false

if zone_exists "perpus.lan" &&
   zone_valid "perpus.lan" "/etc/bind/db.perpus"; then

    if dns_a "www.perpus.lan" "192.168.10.11"; then
        C1=true
    fi
fi

if [ "$C1" = true ]; then
    echo "[PASS]"
    C1_STATUS="PASS"
    SCORE=$((SCORE+14))
else
    echo "[FAIL]"
fi

########################################
# CHALLENGE 2
########################################

echo -n "Challenge 2......................"

C2=false

if zone_exists "labkom.lan" &&
   zone_valid "labkom.lan" "/etc/bind/db.labkom"; then

    WWW_OK=false
    NS_OK=false

    if dns_a "www.labkom.lan" "192.168.10.12"; then
        WWW_OK=true
    fi

    if dns_a "ns1.labkom.lan" "192.168.10.5"; then
        NS_OK=true
    fi

    if [ "$WWW_OK" = true ] &&
       [ "$NS_OK" = true ]; then
        C2=true
    fi
fi

if [ "$C2" = true ]; then
    echo "[PASS]"
    C2_STATUS="PASS"
    SCORE=$((SCORE+14))
else
    echo "[FAIL]"
fi

########################################
# CHALLENGE 3
########################################

echo -n "Challenge 3......................"

C3=false

if zone_exists "akademik.lan" &&
   zone_valid "akademik.lan" "/etc/bind/db.akademik"; then

    WWW_OK=false
    PORTAL_OK=false

    if dns_a "www.akademik.lan" "192.168.10.13"; then
        WWW_OK=true
    fi

    if dns_a "portal.akademik.lan" "192.168.10.13"; then
        PORTAL_OK=true
    fi

    if [ "$WWW_OK" = true ] &&
       [ "$PORTAL_OK" = true ]; then
        C3=true
    fi
fi

if [ "$C3" = true ]; then
    echo "[PASS]"
    C3_STATUS="PASS"
    SCORE=$((SCORE+14))
else
    echo "[FAIL]"
fi

########################################
# CHALLENGE 4
########################################

echo -n "Challenge 4......................"

C4=false

if zone_exists "keuangan.lan" &&
   zone_valid "keuangan.lan" "/etc/bind/db.keuangan"; then

    WWW_OK=false
    MAIL_OK=false
    MX_OK=false

    if dns_a "www.keuangan.lan" "192.168.10.14"; then
        WWW_OK=true
    fi

    if dns_a "mail.keuangan.lan" "192.168.10.14"; then
        MAIL_OK=true
    fi

    MX_TARGET=$(dig +short @127.0.0.1 keuangan.lan MX 2>/dev/null |
        awk '{print $2}' |
        sed 's/\.$//')

    if [ "$MX_TARGET" = "mail.keuangan.lan" ]; then
        MX_OK=true
    fi

    if [ "$WWW_OK" = true ] &&
       [ "$MAIL_OK" = true ] &&
       [ "$MX_OK" = true ]; then
        C4=true
    fi
fi

if [ "$C4" = true ]; then
    echo "[PASS]"
    C4_STATUS="PASS"
    SCORE=$((SCORE+14))
else
    echo "[FAIL]"
fi

########################################
# CHALLENGE 5
########################################

echo -n "Challenge 5......................"

C5=false

if zone_exists "yayasan.lan" &&
   zone_valid "yayasan.lan" "/etc/bind/db.yayasan"; then

    NS1_OK=false
    NS2_OK=false
    WWW_OK=false
    MAIL_OK=false
    MX_OK=false

    if dns_a "ns1.yayasan.lan" "192.168.10.5"; then
        NS1_OK=true
    fi

    if dns_a "ns2.yayasan.lan" "192.168.10.5"; then
        NS2_OK=true
    fi

    if dns_a "www.yayasan.lan" "192.168.10.15"; then
        WWW_OK=true
    fi

    if dns_a "mail.yayasan.lan" "192.168.10.15"; then
        MAIL_OK=true
    fi

    MX_TARGET=$(dig +short @127.0.0.1 yayasan.lan MX 2>/dev/null |
        awk '{print $2}' |
        sed 's/\.$//')

    if [ "$MX_TARGET" = "mail.yayasan.lan" ]; then
        MX_OK=true
    fi

    if [ "$NS1_OK" = true ] &&
       [ "$NS2_OK" = true ] &&
       [ "$WWW_OK" = true ] &&
       [ "$MAIL_OK" = true ] &&
       [ "$MX_OK" = true ]; then
        C5=true
    fi
fi

if [ "$C5" = true ]; then
    echo "[PASS]"
    C5_STATUS="PASS"
    SCORE=$((SCORE+14))
else
    echo "[FAIL]"
fi

########################################
# CHALLENGE 6
########################################

echo -n "Challenge 6......................"

C6=false

if [ "$C5" = true ]; then

    PORTAL_OK=false
    FTP_OK=false

    if dns_a "portal.yayasan.lan" "192.168.10.15"; then
        PORTAL_OK=true
    fi

    if dns_a "ftp.yayasan.lan" "192.168.10.15"; then
        FTP_OK=true
    fi

    if [ "$PORTAL_OK" = true ] &&
       [ "$FTP_OK" = true ]; then
        C6=true
    fi
fi

if [ "$C6" = true ]; then
    echo "[PASS]"
    C6_STATUS="PASS"
    SCORE=$((SCORE+15))
else
    echo "[FAIL]"
fi

########################################
# CHALLENGE 7
########################################

echo -n "Challenge 7......................"

C7=false

CONFIG_OK=false
ZONES_OK=false
RESOLVE_OK=false
SERVICE_OK=false

########################################
# BIND CONFIG
########################################

if named-checkconf >/dev/null 2>&1; then
    CONFIG_OK=true
fi

########################################
# ALL ZONES
########################################

ZONE_COUNT=0

if zone_valid "perpus.lan" "/etc/bind/db.perpus"; then
    ZONE_COUNT=$((ZONE_COUNT+1))
fi

if zone_valid "labkom.lan" "/etc/bind/db.labkom"; then
    ZONE_COUNT=$((ZONE_COUNT+1))
fi

if zone_valid "akademik.lan" "/etc/bind/db.akademik"; then
    ZONE_COUNT=$((ZONE_COUNT+1))
fi

if zone_valid "keuangan.lan" "/etc/bind/db.keuangan"; then
    ZONE_COUNT=$((ZONE_COUNT+1))
fi

if zone_valid "yayasan.lan" "/etc/bind/db.yayasan"; then
    ZONE_COUNT=$((ZONE_COUNT+1))
fi

if [ "$ZONE_COUNT" -eq 5 ]; then
    ZONES_OK=true
fi

########################################
# DNS SERVICE
########################################

if systemctl is-active --quiet bind9; then
    SERVICE_OK=true
fi

########################################
# DNS RESOLUTION
########################################

RESOLVE_COUNT=0

dns_a "www.perpus.lan" "192.168.10.11" &&
    RESOLVE_COUNT=$((RESOLVE_COUNT+1))

dns_a "www.labkom.lan" "192.168.10.12" &&
    RESOLVE_COUNT=$((RESOLVE_COUNT+1))

dns_a "www.akademik.lan" "192.168.10.13" &&
    RESOLVE_COUNT=$((RESOLVE_COUNT+1))

dns_a "www.keuangan.lan" "192.168.10.14" &&
    RESOLVE_COUNT=$((RESOLVE_COUNT+1))

dns_a "www.yayasan.lan" "192.168.10.15" &&
    RESOLVE_COUNT=$((RESOLVE_COUNT+1))

dns_a "portal.yayasan.lan" "192.168.10.15" &&
    RESOLVE_COUNT=$((RESOLVE_COUNT+1))

dns_a "ftp.yayasan.lan" "192.168.10.15" &&
    RESOLVE_COUNT=$((RESOLVE_COUNT+1))

if [ "$RESOLVE_COUNT" -eq 7 ]; then
    RESOLVE_OK=true
fi

########################################
# FINAL CHALLENGE 7
########################################

if [ "$CONFIG_OK" = true ] &&
   [ "$ZONES_OK" = true ] &&
   [ "$RESOLVE_OK" = true ] &&
   [ "$SERVICE_OK" = true ]; then

    C7=true

fi

if [ "$C7" = true ]; then
    echo "[PASS]"
    C7_STATUS="PASS"
    SCORE=$((SCORE+15))
else
    echo "[FAIL]"
fi

########################################
# FINAL STATUS
########################################

if [ "$SCORE" -eq 100 ]; then
    LAB_STATUS="done"
else
    LAB_STATUS="failed"
fi

########################################
# RESULT JSON
########################################

cat > "$RESULT_FILE" <<EOF
{
    "chapter_id": 8,
    "score": $SCORE,
    "status": "$LAB_STATUS",
    "detail": {
        "Challenge1": {
            "status": "$C1_STATUS",
            "score": 14
        },
        "Challenge2": {
            "status": "$C2_STATUS",
            "score": 14
        },
        "Challenge3": {
            "status": "$C3_STATUS",
            "score": 14
        },
        "Challenge4": {
            "status": "$C4_STATUS",
            "score": 14
        },
        "Challenge5": {
            "status": "$C5_STATUS",
            "score": 14
        },
        "Challenge6": {
            "status": "$C6_STATUS",
            "score": 15
        },
        "Challenge7": {
            "status": "$C7_STATUS",
            "score": 15
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
echo "Result : $RESULT_FILE"
echo
