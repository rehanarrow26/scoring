#!/bin/bash
# ================================================================
# AUTOMATED GRADER: FAIL2BAN MULTI-SCENARIO (CHAPTER 50)
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
echo "  GRADER: FAIL2BAN MULTI-SCENARIO (CHAPTER 50)"
echo "================================================="
echo

# 1. CEK CASE 1: SSH CUSTOM PORT 2222 & JAIL SSHD (25 POIN)
echo -n "Step 1: Validating Case 1 (SSH Port 2222 & sshd jail) (25 pts)..."
SSH_PORT_OK=$(ss -tlnp | grep -E "2222" || echo "")
JAIL_SSH_OK=$(fail2ban-client status sshd 2>/dev/null | grep -F "192.168.10.21" || echo "")

if [ -n "$SSH_PORT_OK" ] && [ -n "$JAIL_SSH_OK" ]; then
    pass_check 25
else
    fail_check "Port SSH belum 2222 atau IP 192.168.10.21 tidak ter-ban di jail sshd."
fi

# 2. CEK CASE 2: FILTER WORDPRESS & JAIL WORDPRESS (25 POIN)
echo -n "Step 2: Validating Case 2 (WordPress filter & wordpress jail) (25 pts)..."
FILTER_WP_OK=$( [ -f /etc/fail2ban/filter.d/wordpress.conf ] && echo "OK" || echo "" )
JAIL_WP_OK=$(fail2ban-client status wordpress 2>/dev/null | grep -F "192.168.10.22" || echo "")

if [ -n "$FILTER_WP_OK" ] && [ -n "$JAIL_WP_OK" ]; then
    pass_check 25
else
    fail_check "Filter /etc/fail2ban/filter.d/wordpress.conf belum ada atau IP 192.168.10.22 tidak ter-ban di jail wordpress."
fi

# 3. CEK CASE 3: MYSQL BIND-ADDRESS 0.0.0.0 & JAIL MYSQLD-AUTH (25 POIN)
echo -n "Step 3: Validating Case 3 (MariaDB bind 0.0.0.0 & mysqld-auth jail) (25 pts)..."
MYSQL_BIND_OK=$(ss -tlnp | grep -E "0\.0\.0\.0:3306" || echo "")
JAIL_MYSQL_OK=$(fail2ban-client status mysqld-auth 2>/dev/null | grep -F "192.168.10.23" || echo "")

if [ -n "$MYSQL_BIND_OK" ] && [ -n "$JAIL_MYSQL_OK" ]; then
    pass_check 25
else
    fail_check "MariaDB belum bind ke 0.0.0.0:3306 atau IP 192.168.10.23 tidak ter-ban di jail mysqld-auth."
fi

# 4. CEK CASE 4: JAIL RECIDIVE & REPEAT OFFENDER (25 POIN)
echo -n "Step 4: Validating Case 4 (recidive jail & IP 192.168.10.24 ban) (25 pts)..."
JAIL_RECIDIVE_OK=$(fail2ban-client status recidive 2>/dev/null | grep -F "192.168.10.24" || echo "")

if [ -n "$JAIL_RECIDIVE_OK" ]; then
    pass_check 25
else
    fail_check "Jail recidive tidak aktif atau IP 192.168.10.24 tidak terdaftar di Banned IP list recidive."
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
  "chapter_id": "lab-fail2ban-scenarios-ch50",
  "score": $score,
  "status": "$status"
}
EOF
