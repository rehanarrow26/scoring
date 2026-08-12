#!/bin/bash

# ================================================================
# DNS REVERSE ZONE CHALLENGE CHECKER
# CHAPTER 11
# ================================================================

clear

########################################
# CONFIG
########################################

DNS_SERVER="192.168.10.5"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"

score=0

########################################
# FUNCTIONS
########################################

pass_check() {
    echo "[PASS]"
    score=$((score + $1))
}

fail_check() {
    echo "[FAIL]"
}

check_file() {
    local FILE="$1"

    if [ -f "$FILE" ]; then
        return 0
    fi

    return 1
}

check_text() {
    local FILE="$1"
    local TEXT="$2"

    if [ ! -f "$FILE" ]; then
        return 1
    fi

    timeout 3 grep -Fq "$TEXT" "$FILE" 2>/dev/null
}

check_zone() {
    local ZONE="$1"
    local FILE="$2"

    if [ ! -f "$FILE" ]; then
        return 1
    fi

    timeout 5 named-checkzone "$ZONE" "$FILE" >/dev/null 2>&1
}

check_dns_ptr() {
    local IP="$1"
    local EXPECTED="$2"

    local RESULT

    RESULT=$(timeout 5 dig @"$DNS_SERVER" -x "$IP" +short 2>/dev/null | head -n 1)

    if [ "$RESULT" = "$EXPECTED" ]; then
        return 0
    fi

    return 1
}

########################################
# HEADER
########################################

echo "========================================="
echo "       DNS REVERSE ZONE CHECKER"
echo "             CHAPTER 11"
echo "========================================="
echo

########################################
# BIND9 INSTALLATION
########################################

echo -n "Checking Bind9 Installation......"

if dpkg -s bind9 >/dev/null 2>&1; then
    pass_check 5
else
    fail_check
fi

########################################
# BIND9 SERVICE
########################################

echo -n "Checking Bind9 Service..........."

if systemctl is-active --quiet bind9; then
    pass_check 5
else
    fail_check
fi

echo

########################################
# CHALLENGE 1
########################################

ZONE1="30.168.192.in-addr.arpa"
FILE1="/etc/bind/db.192.168.30"

echo "-----------------------------------------"
echo "Challenge 1 - Server Akademik"
echo "-----------------------------------------"

echo -n "Checking Reverse Zone.............."

if check_text "/etc/bind/named.conf.local" \
    "zone \"30.168.192.in-addr.arpa\""; then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if check_file "$FILE1"; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if check_text "$FILE1" \
    "10      IN      PTR     server.akademik.lan."; then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 2
########################################

ZONE2="10.10.10.in-addr.arpa"
FILE2="/etc/bind/db.10.10.10"

echo
echo "-----------------------------------------"
echo "Challenge 2 - Laboratorium Komputer"
echo "-----------------------------------------"

echo -n "Checking Reverse Zone.............."

if check_text "/etc/bind/named.conf.local" \
    "zone \"10.10.10.in-addr.arpa\""; then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if check_file "$FILE2"; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if check_text "$FILE2" \
    "20      IN      PTR     server.lab.lan."; then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 3
########################################

ZONE3="50.16.172.in-addr.arpa"
FILE3="/etc/bind/db.172.16.50"

echo
echo "-----------------------------------------"
echo "Challenge 3 - Perpustakaan Digital"
echo "-----------------------------------------"

echo -n "Checking Reverse Zone.............."

if check_text "/etc/bind/named.conf.local" \
    "zone \"50.16.172.in-addr.arpa\""; then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if check_file "$FILE3"; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if check_text "$FILE3" \
    "15      IN      PTR     library.perpus.lan."; then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 4
########################################

ZONE4="40.168.192.in-addr.arpa"
FILE4="/etc/bind/db.192.168.40"

echo
echo "-----------------------------------------"
echo "Challenge 4 - Server E-Learning"
echo "-----------------------------------------"

echo -n "Checking Reverse Zone.............."

if check_text "/etc/bind/named.conf.local" \
    "zone \"40.168.192.in-addr.arpa\""; then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if check_file "$FILE4"; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if check_text "$FILE4" \
    "25      IN      PTR     lms.elearning.lan."; then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 5
########################################

ZONE5="50.168.192.in-addr.arpa"
FILE5="/etc/bind/db.192.168.50"

echo
echo "-----------------------------------------"
echo "Challenge 5 - Server Monitoring"
echo "-----------------------------------------"

echo -n "Checking Reverse Zone.............."

if check_text "/etc/bind/named.conf.local" \
    "zone \"50.168.192.in-addr.arpa\""; then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if check_file "$FILE5"; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR Record................"

if check_text "$FILE5" \
    "30      IN      PTR     grafana.monitor.lan."; then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 6
########################################

ZONE6="60.168.192.in-addr.arpa"
FILE6="/etc/bind/db.192.168.60"

echo
echo "-----------------------------------------"
echo "Challenge 6 - Web & Database Server"
echo "-----------------------------------------"

echo -n "Checking Reverse Zone.............."

if check_text "/etc/bind/named.conf.local" \
    "zone \"60.168.192.in-addr.arpa\""; then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if check_file "$FILE6"; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking Web PTR..................."

if check_text "$FILE6" \
    "10      IN      PTR     web.sekolah60.lan."; then
    pass_check 5
else
    fail_check
fi

echo -n "Checking Database PTR.............."

if check_text "$FILE6" \
    "20      IN      PTR     database.sekolah60.lan."; then
    pass_check 5
else
    fail_check
fi

########################################
# CHALLENGE 7
########################################

ZONE7="30.20.10.in-addr.arpa"
FILE7="/etc/bind/db.10.20.30"

echo
echo "-----------------------------------------"
echo "Challenge 7 - Infrastruktur"
echo "-----------------------------------------"

echo -n "Checking Reverse Zone.............."

if check_text "/etc/bind/named.conf.local" \
    "zone \"30.20.10.in-addr.arpa\""; then
    pass_check 3
else
    fail_check
fi

echo -n "Checking Zone File................."

if check_file "$FILE7"; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking Web PTR..................."

if check_text "$FILE7" \
    "10      IN      PTR     web.infra.lan."; then
    pass_check 4
else
    fail_check
fi

echo -n "Checking Mail PTR.................."

if check_text "$FILE7" \
    "20      IN      PTR     mail.infra.lan."; then
    pass_check 4
else
    fail_check
fi

echo -n "Checking Backup PTR................"

if check_text "$FILE7" \
    "30      IN      PTR     backup.infra.lan."; then
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

if timeout 5 named-checkconf >/dev/null 2>&1; then
    pass_check 5
else
    fail_check
fi

echo -n "Checking named-checkzone.........."

ZONE_OK=0

check_zone "$ZONE1" "$FILE1" && ZONE_OK=$((ZONE_OK + 1))
check_zone "$ZONE2" "$FILE2" && ZONE_OK=$((ZONE_OK + 1))
check_zone "$ZONE3" "$FILE3" && ZONE_OK=$((ZONE_OK + 1))
check_zone "$ZONE4" "$FILE4" && ZONE_OK=$((ZONE_OK + 1))
check_zone "$ZONE5" "$FILE5" && ZONE_OK=$((ZONE_OK + 1))
check_zone "$ZONE6" "$FILE6" && ZONE_OK=$((ZONE_OK + 1))
check_zone "$ZONE7" "$FILE7" && ZONE_OK=$((ZONE_OK + 1))

if [ "$ZONE_OK" -eq 7 ]; then
    pass_check 10
else
    echo "[FAIL]"
    echo "Valid zones: $ZONE_OK / 7"
fi

########################################
# FUNCTIONAL DNS TEST
########################################

echo
echo "-----------------------------------------"
echo "Reverse DNS Functional Test"
echo "-----------------------------------------"

echo -n "Checking PTR 192.168.30.10........."

if check_dns_ptr \
    "192.168.30.10" \
    "server.akademik.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 10.10.10.20............"

if check_dns_ptr \
    "10.10.10.20" \
    "server.lab.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 172.16.50.15..........."

if check_dns_ptr \
    "172.16.50.15" \
    "library.perpus.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 192.168.40.25..........."

if check_dns_ptr \
    "192.168.40.25" \
    "lms.elearning.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 192.168.50.30..........."

if check_dns_ptr \
    "192.168.50.30" \
    "grafana.monitor.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 192.168.60.10..........."

if check_dns_ptr \
    "192.168.60.10" \
    "web.sekolah60.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 192.168.60.20..........."

if check_dns_ptr \
    "192.168.60.20" \
    "database.sekolah60.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 10.20.30.10............."

if check_dns_ptr \
    "10.20.30.10" \
    "web.infra.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 10.20.30.20............."

if check_dns_ptr \
    "10.20.30.20" \
    "mail.infra.lan."; then
    pass_check 2
else
    fail_check
fi

echo -n "Checking PTR 10.20.30.30............."

if check_dns_ptr \
    "10.20.30.30" \
    "backup.infra.lan."; then
    pass_check 2
else
    fail_check
fi

########################################
# LIMIT SCORE
########################################

if [ "$score" -gt 100 ]; then
    score=100
fi

########################################
# STATUS
########################################

if [ "$score" -eq 100 ]; then
    STATUS="PASS"
else
    STATUS="FAIL"
fi

########################################
# SAVE RESULT
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

if [ "$score" -eq 100 ]; then
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
