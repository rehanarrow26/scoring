#!/bin/bash
# ================================================================
# AUTOMATED GRADER: FAIL2BAN DEBIAN 12 ASSESSMENT (CHAPTER 49)
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
echo "  GRADER: FAIL2BAN CONFIGURATION ON DEBIAN 12"
echo "================================================="
echo

# 1. CEK INSTALASI PAKET FAIL2BAN (15 POIN)
echo -n "Step 1: Checking Fail2ban package installation (15 pts)..."
if dpkg -l | grep -q "^ii\s\+fail2ban"; then
    pass_check 15
else
    fail_check "Paket 'fail2ban' tidak terinstal di sistem."
fi

# 2. CEK FILE /etc/fail2ban/jail.local (15 POIN)
echo -n "Step 2: Checking presence of /etc/fail2ban/jail.local (15 pts)..."
if [ -f "/etc/fail2ban/jail.local" ]; then
    pass_check 15
else
    fail_check "File '/etc/fail2ban/jail.local' tidak ditemukan."
fi

# 3. CEK PARAMETER GLOBAL [DEFAULT] (20 POIN)
echo -n "Step 3: Validating [DEFAULT] configuration parameters (20 pts)..."
if [ -f "/etc/fail2ban/jail.local" ]; then
    HAS_IGNOREIP=$(grep -E "^ignoreip\s*=.*192\.168\.10\.10" /etc/fail2ban/jail.local || echo "")
    HAS_BANTIME=$(grep -E "^bantime\s*=\s*1h" /etc/fail2ban/jail.local || echo "")
    HAS_FINDTIME=$(grep -E "^findtime\s*=\s*10m" /etc/fail2ban/jail.local || echo "")
    HAS_MAXRETRY=$(grep -E "^maxretry\s*=\s*5" /etc/fail2ban/jail.local || echo "")
    HAS_BACKEND=$(grep -E "^backend\s*=\s*systemd" /etc/fail2ban/jail.local || echo "")

    if [ -n "$HAS_IGNOREIP" ] && [ -n "$HAS_BANTIME" ] && [ -n "$HAS_FINDTIME" ] && [ -n "$HAS_MAXRETRY" ] && [ -n "$HAS_BACKEND" ]; then
        pass_check 20
    else
        fail_check "Parameter [DEFAULT] (ignoreip, bantime, findtime, maxretry, atau backend) belum sesuai spesifikasi."
    fi
else
    fail_check "File /etc/fail2ban/jail.local tidak ada."
fi

# 4. CEK JAIL [sshd] (15 POIN)
echo -n "Step 4: Validating [sshd] jail configuration (15 pts)..."
if [ -f "/etc/fail2ban/jail.local" ]; then
    SSHD_ENABLED=$(fail2ban-client status sshd 2>/dev/null || echo "")
    if [ -n "$SSHD_ENABLED" ]; then
        pass_check 15
    else
        fail_check "Jail [sshd] tidak aktif atau tidak ditemukan pada fail2ban-client status."
    fi
else
    fail_check "File /etc/fail2ban/jail.local tidak ditemukan."
fi

# 5. CEK STATUS SERVICE FAIL2BAN (15 POIN)
echo -n "Step 5: Checking fail2ban service status (15 pts)..."
SERVICE_ACTIVE=$(systemctl is-active fail2ban 2>/dev/null || echo "")

if [ "$SERVICE_ACTIVE" = "active" ]; then
    pass_check 15
else
    fail_check "Layanan 'fail2ban.service' tidak berstatus active (running)."
fi

# 6. CEK SIMULASI BAN IP 192.168.10.26 PADA SSHD (20 POIN)
echo -n "Step 6: Verifying IP 192.168.10.26 is banned in [sshd] jail (20 pts)..."
IS_BANNED=$(fail2ban-client status sshd 2>/dev/null | grep -F "192.168.10.26" || echo "")

if [ -n "$IS_BANNED" ]; then
    pass_check 20
else
    fail_check "IP 192.168.10.26 tidak terdaftar dalam Banned IP list pada jail [sshd]."
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
  "chapter_id": "lab-fail2ban-debian12",
  "score": $score,
  "status": "$status"
}
EOF
