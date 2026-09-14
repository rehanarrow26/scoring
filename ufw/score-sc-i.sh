#!/bin/bash
# ================================================================
# AUTOMATED GRADER: 5 GUIDED PRACTICES UFW
# Max Score: 100 Pts (5 Cases x 20 Pts)
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
echo "  GRADER: UFW 5 GUIDED PRACTICES ASSESSMENT"
echo "================================================="
echo

# 1. CEK UFW STATUS & DEFAULT POLICY
UFW_ACTIVE=$(ufw status 2>/dev/null | grep -i "Status: active" || echo "")
DEFAULT_DENY=$(ufw status verbose 2>/dev/null | grep -i "Default:" | grep -i "deny (incoming)" || echo "")

if [ -z "$UFW_ACTIVE" ] || [ -z "$DEFAULT_DENY" ]; then
    echo -e "\e[31m[CRITICAL] UFW Service tidak aktif atau Default Policy bukan Deny Incoming!\e[0m"
    echo
fi

# GP 1: SSH SUBNET MANAGEMENT (20 POIN)
echo -n "GP 1: Checking SSH Subnet Restriction (192.168.10.0/28) (20 pts)..."
SSH_SUBNET=$(ufw status 2>/dev/null | grep -i "22/tcp" | grep "192.168.10.0/28" || echo "")
if [ -n "$SSH_SUBNET" ]; then
    pass_check 20
else
    fail_check "Aturan port 22/tcp khusus subnet 192.168.10.0/28 tidak ditemukan."
fi

# GP 2: WEB HTTPS ALLOW & HTTP DENY (20 POIN)
echo -n "GP 2: Checking Web Rules (443 ALLOW & 80 DENY) (20 pts)..."
HTTPS_RULE=$(ufw status 2>/dev/null | grep -E "^443(/tcp)?\s+ALLOW" || echo "")
HTTP_RULE=$(ufw status 2>/dev/null | grep -E "^80(/tcp)?\s+DENY" || echo "")
if [ -n "$HTTPS_RULE" ] && [ -n "$HTTP_RULE" ]; then
    pass_check 20
else
    fail_check "Port 443/tcp wajib ALLOW dan Port 80/tcp wajib DENY secara eksplisit."
fi

# GP 3: MYSQL BACKEND ALLOW (20 POIN)
echo -n "GP 3: Checking MySQL Access for Backend 192.168.10.25 (20 pts)..."
MYSQL_RULE=$(ufw status 2>/dev/null | grep -i "3306" | grep "192.168.10.25" || echo "")
if [ -n "$MYSQL_RULE" ]; then
    pass_check 20
else
    fail_check "Aturan port 3306/tcp khusus IP 192.168.10.25 tidak ditemukan."
fi

# GP 4: SSH RATE LIMITING (20 POIN)
echo -n "GP 4: Checking SSH Rate Limit Rule (20 pts)..."
LIMIT_RULE=$(ufw status 2>/dev/null | grep -i "22/tcp" | grep -i "LIMIT" || echo "")
if [ -n "$LIMIT_RULE" ]; then
    pass_check 20
else
    fail_check "Fitur Rate Limit (ufw limit 22/tcp) belum diterapkan."
fi

# GP 5: BLACKLIST IP 192.168.10.66 & LOGGING (20 POIN)
echo -n "GP 5: Checking Blacklist 192.168.10.66 & Logging (20 pts)..."
BLACK_RULE=$(ufw status numbered 2>/dev/null | grep -i "DENY" | grep "192.168.10.66" || echo "")
LOG_RULE=$(ufw status verbose 2>/dev/null | grep -i "Logging:" | grep -E "on \((medium|low|high|full)\)" || echo "")
if [ -n "$BLACK_RULE" ] && [ -n "$LOG_RULE" ]; then
    pass_check 20
else
    fail_check "Aturan Deny untuk 192.168.10.66 atau Logging UFW belum diaktifkan."
fi

# Limit Max 100
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

# Save JSON Output
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-ufw-5-guided-practices",
  "score": $score,
  "status": "$status"
}
EOF
