#!/bin/bash
# ================================================================
# AUTOMATED GRADER: FAIL2BAN ADVANCED (STUDI KASUS 5 - 7)
# Total Max Score: 100 Pts
# ================================================================

clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"

score=0

pass_check() {
    echo -e "\e[32m[PASS]\e[0m"
    score=$((score + $1))
}

fail_check() {
    local reason="$1"
    echo -e "\e[31m[FAIL]\e[0m"
    echo -e "    \e[33m└─> Alasan: $reason\e[0m"
}

echo "================================================="
echo "  GRADER: FAIL2BAN ADVANCED (KASUS 5 - 7)"
echo "================================================="
echo

# 1. CEK KASUS 5: WHITELIST IP ADMIN (ignoreip) (35 POIN)
echo -n "Step 1: Validating Case 5 (Whitelist IP 192.168.10.40/29 & 192.168.10.50) (35 pts)..."
IGNORE_IP_VAL=$(fail2ban-client get sshd ignoreip 2>/dev/null || echo "")
NET_CHECK=$(echo "$IGNORE_IP_VAL" | grep -E "192\.168\.10\.40/29|192\.168\.10\.40/255\.255\.255\.248" || echo "")
SINGLE_CHECK=$(echo "$IGNORE_IP_VAL" | grep -F "192.168.10.50" || echo "")

# Pastikan 192.168.10.41 TIDAK ter-ban dan 192.168.10.31 ter-ban
BANNED_LIST=$(fail2ban-client status sshd 2>/dev/null || echo "")
IS_41_NOT_BANNED=$(echo "$BANNED_LIST" | grep -F "192.168.10.41" || echo "OK_NOT_BANNED")
IS_31_BANNED=$(echo "$BANNED_LIST" | grep -F "192.168.10.31" || echo "")

if [ -n "$NET_CHECK" ] && [ -n "$SINGLE_CHECK" ] && [ "$IS_41_NOT_BANNED" = "OK_NOT_BANNED" ] && [ -n "$IS_31_BANNED" ]; then
    pass_check 35
else
    fail_check "Parameter ignoreip belum mengonfigurasi 192.168.10.40/29 & 192.168.10.50 dengan benar, atau status ban 192.168.10.31/192.168.10.41 tidak sesuai."
fi

# 2. CEK KASUS 6: BAN PROGRESIF (bantime.increment, factor, maxtime) (35 POIN)
echo -n "Step 2: Validating Case 6 (Progressive Ban Settings) (35 pts)..."
JAIL_CONF=$(cat /etc/fail2ban/jail.local 2>/dev/null || echo "")
INC_OK=$(echo "$JAIL_CONF" | grep -iE "^\s*bantime\.increment\s*=\s*true" || echo "")
FACTOR_OK=$(echo "$JAIL_CONF" | grep -iE "^\s*bantime\.factor\s*=\s*2" || echo "")
MAXTIME_OK=$(echo "$JAIL_CONF" | grep -iE "^\s*bantime\.maxtime\s*=\\s*1w" || echo "")
IS_32_BANNED=$(echo "$BANNED_LIST" | grep -F "192.168.10.32" || echo "")

if [ -n "$INC_OK" ] && [ -n "$FACTOR_OK" ] && [ -n "$MAXTIME_OK" ] && [ -n "$IS_32_BANNED" ]; then
    pass_check 35
else
    fail_check "Pengaturan bantime.increment, bantime.factor, atau bantime.maxtime belum tepat di /etc/fail2ban/jail.local, atau 192.168.10.32 tidak ter-ban."
fi

# 3. CEK KASUS 7: DETEKSI DICTIONARY ATTACK MULTI-USERNAME (30 POIN)
echo -n "Step 3: Validating Case 7 (Multi-username dictionary attack detection) (30 pts)..."
SSHD_ENABLED=$(fail2ban-client status sshd 2>/dev/null | grep -i "Status for the jail: sshd" || echo "")
IS_33_BANNED=$(echo "$BANNED_LIST" | grep -F "192.168.10.33" || echo "")

if [ -n "$SSHD_ENABLED" ] && [ -n "$IS_33_BANNED" ]; then
    pass_check 30
else
    fail_check "Jail sshd tidak aktif atau IP 192.168.10.33 (multi-username dictionary attack) tidak ter-ban."
fi

# Limit Max Score 100
[ "$score" -gt 100 ] && score=100

echo
echo "================================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Total Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Total Score: $score/100\e[0m"
    status="FAIL"
fi
echo "================================================="

# Menulis Luaran JSON untuk Sistem Scoring Lab
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-fail2ban-scenarios-part2",
  "score": $score,
  "status": "$status"
}
EOF
