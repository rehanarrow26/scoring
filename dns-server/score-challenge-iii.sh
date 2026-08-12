#!/usr/bin/env bash

set -u

# ================================================================
#  DNS CHAPTER 12 — FORWARD & REVERSE DNS
#  SCORING SCRIPT
# ================================================================

DNS_SERVER="192.168.10.5"
CHAPTER_ID=12

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"

TOTAL_SCORE=0

PASS_COUNT=0
FAIL_COUNT=0

echo "========================================="
echo "   DNS FORWARD & REVERSE DNS CHECKER"
echo "              CHAPTER 12"
echo "========================================="
echo

# ================================================================
# HELPER
# ================================================================

pass_check() {
    echo "Checking $1.................[PASS]"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail_check() {
    echo "Checking $1.................[FAIL]"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

check() {
    local NAME="$1"
    local POINT="$2"
    local COMMAND="$3"

    if eval "$COMMAND" >/dev/null 2>&1; then
        pass_check "$NAME"
        TOTAL_SCORE=$((TOTAL_SCORE + POINT))
        return 0
    else
        fail_check "$NAME"
        return 1
    fi
}

# ================================================================
# BASIC BIND CHECK
# ================================================================

echo "[ BASIC DNS SERVER ]"
echo

if dpkg -s bind9 >/dev/null 2>&1; then
    pass_check "Bind9 Installation"
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
else
    fail_check "Bind9 Installation"
fi

if systemctl is-active --quiet bind9; then
    pass_check "Bind9 Service"
    TOTAL_SCORE=$((TOTAL_SCORE + 5))
else
    fail_check "Bind9 Service"
fi

echo
echo "Current Score : $TOTAL_SCORE"
echo
echo "========================================="

# ================================================================
# FUNCTION — FORWARD ZONE
# ================================================================

check_forward_zone() {
    local ZONE="$1"
    local FILE="$2"

    if grep -Eq "zone[[:space:]]+\"$ZONE\"" /etc/bind/named.conf.local \
        && [ -f "$FILE" ]; then
        return 0
    fi

    return 1
}

# ================================================================
# FUNCTION — FORWARD RECORD
# ================================================================

check_forward_record() {
    local HOST="$1"
    local EXPECTED_IP="$2"

    local RESULT

    RESULT=$(dig @"$DNS_SERVER" "$HOST" A +short 2>/dev/null | head -1)

    [ "$RESULT" = "$EXPECTED_IP" ]
}

# ================================================================
# FUNCTION — MX
# ================================================================

check_mx() {
    local DOMAIN="$1"
    local EXPECTED="$2"

    local RESULT

    RESULT=$(dig @"$DNS_SERVER" "$DOMAIN" MX +short 2>/dev/null)

    echo "$RESULT" | grep -q "$EXPECTED"
}

# ================================================================
# FUNCTION — REVERSE
# ================================================================

check_ptr() {
    local IP="$1"
    local EXPECTED="$2"

    local RESULT

    RESULT=$(dig @"$DNS_SERVER" -x "$IP" PTR +short 2>/dev/null | sed 's/\.$//' | head -1)

    [ "$RESULT" = "$EXPECTED" ]
}

# ================================================================
# FUNCTION — REVERSE ZONE
# ================================================================

check_reverse_zone() {
    local ZONE="$1"
    local FILE="$2"

    if grep -Eq "zone[[:space:]]+\"$ZONE\"" /etc/bind/named.conf.local \
        && [ -f "$FILE" ]; then
        return 0
    fi

    return 1
}

# ================================================================
# CHALLENGE 1
# ================================================================

echo
echo "-----------------------------------------"
echo " Challenge 1 - Server Akademik"
echo "-----------------------------------------"

check \
"Forward Zone akademik12.lan" \
3 \
"check_forward_zone 'akademik12.lan' '/etc/bind/db.akademik12'"

check \
"A Record akademik12.lan" \
1 \
"check_forward_record 'akademik12.lan' '192.168.70.10'"

check \
"A Record www.akademik12.lan" \
1 \
"check_forward_record 'www.akademik12.lan' '192.168.70.10'"

check \
"A Record mail.akademik12.lan" \
1 \
"check_forward_record 'mail.akademik12.lan' '192.168.70.10'"

check \
"A Record portal.akademik12.lan" \
1 \
"check_forward_record 'portal.akademik12.lan' '192.168.70.10'"

check \
"MX akademik12.lan" \
2 \
"check_mx 'akademik12.lan' 'mail.akademik12.lan.'"

check \
"Reverse Zone 192.168.70" \
2 \
"check_reverse_zone '70.168.192.in-addr.arpa' '/etc/bind/db.192.168.70'"

check \
"PTR 192.168.70.10" \
2 \
"check_ptr '192.168.70.10' 'akademik12.lan'"

echo
echo "Current Score : $TOTAL_SCORE"

# ================================================================
# CHALLENGE 2
# ================================================================

echo
echo "-----------------------------------------"
echo " Challenge 2 - Laboratorium"
echo "-----------------------------------------"

check \
"Forward Zone lab12.lan" \
3 \
"check_forward_zone 'lab12.lan' '/etc/bind/db.lab12'"

check \
"A Record lab12.lan" \
1 \
"check_forward_record 'lab12.lan' '10.30.40.10'"

check \
"A Record www.lab12.lan" \
1 \
"check_forward_record 'www.lab12.lan' '10.30.40.10'"

check \
"A Record repo.lab12.lan" \
1 \
"check_forward_record 'repo.lab12.lan' '10.30.40.10'"

check \
"A Record monitor.lab12.lan" \
1 \
"check_forward_record 'monitor.lab12.lan' '10.30.40.10'"

check \
"A Record mail.lab12.lan" \
1 \
"check_forward_record 'mail.lab12.lan' '10.30.40.10'"

check \
"MX lab12.lan" \
1 \
"check_mx 'lab12.lan' 'mail.lab12.lan.'"

check \
"Reverse Zone 10.30.40" \
2 \
"check_reverse_zone '40.30.10.in-addr.arpa' '/etc/bind/db.10.30.40'"

check \
"PTR 10.30.40.10" \
1 \
"check_ptr '10.30.40.10' 'lab12.lan'"

echo
echo "Current Score : $TOTAL_SCORE"

# ================================================================
# CHALLENGE 3
# ================================================================

echo
echo "-----------------------------------------"
echo " Challenge 3 - Perpustakaan Digital"
echo "-----------------------------------------"

check \
"Forward Zone perpus12.lan" \
3 \
"check_forward_zone 'perpus12.lan' '/etc/bind/db.perpus12'"

check \
"A Record perpus12.lan" \
1 \
"check_forward_record 'perpus12.lan' '172.20.60.15'"

check \
"A Record www.perpus12.lan" \
1 \
"check_forward_record 'www.perpus12.lan' '172.20.60.15'"

check \
"A Record library.perpus12.lan" \
1 \
"check_forward_record 'library.perpus12.lan' '172.20.60.15'"

check \
"A Record search.perpus12.lan" \
1 \
"check_forward_record 'search.perpus12.lan' '172.20.60.15'"

check \
"A Record mail.perpus12.lan" \
1 \
"check_forward_record 'mail.perpus12.lan' '172.20.60.15'"

check \
"MX perpus12.lan" \
1 \
"check_mx 'perpus12.lan' 'mail.perpus12.lan.'"

check \
"Reverse Zone 172.20.60" \
2 \
"check_reverse_zone '60.20.172.in-addr.arpa' '/etc/bind/db.172.20.60'"

check \
"PTR 172.20.60.15" \
1 \
"check_ptr '172.20.60.15' 'perpus12.lan'"

echo
echo "Current Score : $TOTAL_SCORE"

# ================================================================
# CHALLENGE 4
# ================================================================

echo
echo "-----------------------------------------"
echo " Challenge 4 - E-Learning"
echo "-----------------------------------------"

check \
"Forward Zone elearning12.lan" \
3 \
"check_forward_zone 'elearning12.lan' '/etc/bind/db.elearning12'"

check \
"A Record elearning12.lan" \
1 \
"check_forward_record 'elearning12.lan' '192.168.80.20'"

check \
"A Record www.elearning12.lan" \
1 \
"check_forward_record 'www.elearning12.lan' '192.168.80.20'"

check \
"A Record lms.elearning12.lan" \
1 \
"check_forward_record 'lms.elearning12.lan' '192.168.80.20'"

check \
"A Record api.elearning12.lan" \
1 \
"check_forward_record 'api.elearning12.lan' '192.168.80.20'"

check \
"A Record mail.elearning12.lan" \
1 \
"check_forward_record 'mail.elearning12.lan' '192.168.80.20'"

check \
"MX elearning12.lan" \
1 \
"check_mx 'elearning12.lan' 'mail.elearning12.lan.'"

check \
"Reverse Zone 192.168.80" \
2 \
"check_reverse_zone '80.168.192.in-addr.arpa' '/etc/bind/db.192.168.80'"

check \
"PTR 192.168.80.20" \
1 \
"check_ptr '192.168.80.20' 'elearning12.lan'"

echo
echo "Current Score : $TOTAL_SCORE"

# ================================================================
# CHALLENGE 5
# ================================================================

echo
echo "-----------------------------------------"
echo " Challenge 5 - Monitoring"
echo "-----------------------------------------"

check \
"Forward Zone monitor12.lan" \
3 \
"check_forward_zone 'monitor12.lan' '/etc/bind/db.monitor12'"

check \
"A Record monitor12.lan" \
1 \
"check_forward_record 'monitor12.lan' '192.168.90.25'"

check \
"A Record grafana.monitor12.lan" \
1 \
"check_forward_record 'grafana.monitor12.lan' '192.168.90.25'"

check \
"A Record prometheus.monitor12.lan" \
1 \
"check_forward_record 'prometheus.monitor12.lan' '192.168.90.25'"

check \
"A Record alert.monitor12.lan" \
1 \
"check_forward_record 'alert.monitor12.lan' '192.168.90.25'"

check \
"A Record mail.monitor12.lan" \
1 \
"check_forward_record 'mail.monitor12.lan' '192.168.90.25'"

check \
"MX monitor12.lan" \
1 \
"check_mx 'monitor12.lan' 'mail.monitor12.lan.'"

check \
"Reverse Zone 192.168.90" \
2 \
"check_reverse_zone '90.168.192.in-addr.arpa' '/etc/bind/db.192.168.90'"

check \
"PTR 192.168.90.25" \
1 \
"check_ptr '192.168.90.25' 'monitor12.lan'"

echo
echo "Current Score : $TOTAL_SCORE"

# ================================================================
# CHALLENGE 6
# ================================================================

echo
echo "-----------------------------------------"
echo " Challenge 6 - Server Keuangan"
echo "-----------------------------------------"

check \
"Forward Zone finance12.lan" \
3 \
"check_forward_zone 'finance12.lan' '/etc/bind/db.finance12'"

check \
"A Record finance12.lan" \
1 \
"check_forward_record 'finance12.lan' '10.40.50.30'"

check \
"A Record www.finance12.lan" \
1 \
"check_forward_record 'www.finance12.lan' '10.40.50.30'"

check \
"A Record app.finance12.lan" \
1 \
"check_forward_record 'app.finance12.lan' '10.40.50.30'"

check \
"A Record report.finance12.lan" \
1 \
"check_forward_record 'report.finance12.lan' '10.40.50.30'"

check \
"A Record mail.finance12.lan" \
1 \
"check_forward_record 'mail.finance12.lan' '10.40.50.30'"

check \
"MX finance12.lan" \
1 \
"check_mx 'finance12.lan' 'mail.finance12.lan.'"

check \
"Reverse Zone 10.40.50" \
2 \
"check_reverse_zone '50.40.10.in-addr.arpa' '/etc/bind/db.10.40.50'"

check \
"PTR 10.40.50.30" \
1 \
"check_ptr '10.40.50.30' 'finance12.lan'"

echo
echo "Current Score : $TOTAL_SCORE"

# ================================================================
# CHALLENGE 7
# ================================================================

echo
echo "-----------------------------------------"
echo " Challenge 7 - Infrastruktur"
echo "-----------------------------------------"

check \
"Forward Zone infra12.lan" \
2 \
"check_forward_zone 'infra12.lan' '/etc/bind/db.infra12'"

check \
"Forward Records Web" \
1 \
"check_forward_record 'web.infra12.lan' '10.50.60.10'"

check \
"Forward Records WWW" \
1 \
"check_forward_record 'www.infra12.lan' '10.50.60.10'"

check \
"Forward Records Portal" \
1 \
"check_forward_record 'portal.infra12.lan' '10.50.60.10'"

check \
"Forward Records Mail" \
1 \
"check_forward_record 'mail.infra12.lan' '10.50.60.20'"

check \
"Forward Records SMTP" \
1 \
"check_forward_record 'smtp.infra12.lan' '10.50.60.20'"

check \
"Forward Records IMAP" \
1 \
"check_forward_record 'imap.infra12.lan' '10.50.60.20'"

check \
"Forward Records Backup" \
1 \
"check_forward_record 'backup.infra12.lan' '10.50.60.30'"

check \
"Forward Records Storage" \
1 \
"check_forward_record 'storage.infra12.lan' '10.50.60.30'"

check \
"Forward Records Repository" \
1 \
"check_forward_record 'repository.infra12.lan' '10.50.60.30'"

check \
"MX infra12.lan" \
2 \
"check_mx 'infra12.lan' 'mail.infra12.lan.'"

check \
"Reverse Zone 10.50.60" \
2 \
"check_reverse_zone '60.50.10.in-addr.arpa' '/etc/bind/db.10.50.60'"

check \
"PTR 10.50.60.10" \
1 \
"check_ptr '10.50.60.10' 'web.infra12.lan'"

check \
"PTR 10.50.60.20" \
1 \
"check_ptr '10.50.60.20' 'mail.infra12.lan'"

check \
"PTR 10.50.60.30" \
1 \
"check_ptr '10.50.60.30' 'backup.infra12.lan'"

echo
echo "Current Score : $TOTAL_SCORE"

# ================================================================
# GLOBAL VALIDATION
# ================================================================

echo
echo "-----------------------------------------"
echo " Global Validation"
echo "-----------------------------------------"

if named-checkconf >/dev/null 2>&1; then
    pass_check "named-checkconf"
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
else
    fail_check "named-checkconf"
fi

ZONE_OK=1

for Z in \
    "akademik12.lan /etc/bind/db.akademik12" \
    "lab12.lan /etc/bind/db.lab12" \
    "perpus12.lan /etc/bind/db.perpus12" \
    "elearning12.lan /etc/bind/db.elearning12" \
    "monitor12.lan /etc/bind/db.monitor12" \
    "finance12.lan /etc/bind/db.finance12" \
    "infra12.lan /etc/bind/db.infra12"
do
    set -- $Z

    if ! named-checkzone "$1" "$2" >/dev/null 2>&1; then
        ZONE_OK=0
        break
    fi
done

if [ "$ZONE_OK" -eq 1 ]; then
    pass_check "Forward Zone Validation"
    TOTAL_SCORE=$((TOTAL_SCORE + 2))
else
    fail_check "Forward Zone Validation"
fi

# ================================================================
# CAP SCORE
# ================================================================

if [ "$TOTAL_SCORE" -gt 100 ]; then
    TOTAL_SCORE=100
fi

echo
echo "========================================="
echo "            FINAL RESULT"
echo "========================================="
echo
echo "PASS CHECK : $PASS_COUNT"
echo "FAIL CHECK : $FAIL_COUNT"
echo
echo "Score : $TOTAL_SCORE /100"
echo

# ================================================================
# RESULT JSON
# ================================================================

if [ "$TOTAL_SCORE" -eq 100 ]; then
    STATUS="PASS"
else
    STATUS="FAILED"
fi

cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": $CHAPTER_ID,
  "score": $TOTAL_SCORE,
  "status": "$STATUS"
}
EOF

if [ "$TOTAL_SCORE" -eq 100 ]; then

    echo "========================================="
    echo "          MISSION COMPLETE"
    echo "========================================="
    echo
    echo "Forward & Reverse DNS berhasil."
    echo
else

    echo "========================================="
    echo "          MISSION INCOMPLETE"
    echo "========================================="
    echo
    echo "Periksa konfigurasi yang masih FAIL."
    echo
fi
