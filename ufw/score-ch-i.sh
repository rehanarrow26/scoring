#!/bin/bash
# ================================================================
# AUTOMATED GRADER: 8 UFW CHALLENGES ASSESSMENT
# Max Score: 100 Pts
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
echo "  GRADER: UFW 8 CHALLENGES ASSESSMENT"
echo "================================================="
echo

# 0. CEK STATUS UTAMA UFW
UFW_ACTIVE=$(ufw status 2>/dev/null | grep -i "Status: active" || echo "")
DEFAULT_DENY=$(ufw status verbose 2>/dev/null | grep -i "Default:" | grep -i "deny (incoming)" || echo "")

if [ -z "$UFW_ACTIVE" ] || [ -z "$DEFAULT_DENY" ]; then
    echo -e "\e[31m[CRITICAL] UFW Service tidak aktif atau Default Policy bukan Deny Incoming!\e[0m"
    echo
fi

# CHALLENGE 1: DNS PORT 5353 TCP & UDP (12 POIN)
echo -n "CH 1: Checking DNS Port 5353 TCP/UDP for Subnet 192.168.10.0/24 (12 pts)..."
DNS_TCP=$(ufw status 2>/dev/null | grep -i "5353/tcp" | grep "192.168.10.0/24" || echo "")
DNS_UDP=$(ufw status 2>/dev/null | grep -i "5353/udp" | grep "192.168.10.0/24" || echo "")
if [ -n "$DNS_TCP" ] && [ -n "$DNS_UDP" ]; then
    pass_check 12
else
    fail_check "Aturan port 5353/tcp dan 5353/udp khusus subnet 192.168.10.0/24 tidak lengkap."
fi

# CHALLENGE 2: MONITORING AGENT 9100/TCP (12 POIN)
echo -n "CH 2: Checking Monitoring Agent 9100/tcp for IP 192.168.10.200 (12 pts)..."
MON_RULE=$(ufw status 2>/dev/null | grep -i "9100" | grep "192.168.10.200" || echo "")
if [ -n "$MON_RULE" ]; then
    pass_check 12
else
    fail_check "Aturan port 9100/tcp khusus IP 192.168.10.200 tidak ditemukan."
fi

# CHALLENGE 3: PRIORITY BLOCK HOST 192.168.10.88 (12 POIN)
echo -n "CH 3: Checking Priority Block Rule for Host 192.168.10.88 (12 pts)..."
TOP_RULE=$(ufw status numbered 2>/dev/null | grep -E "^\[\s*1\]" | grep -i "DENY" | grep "192.168.10.88" || echo "")
if [ -n "$TOP_RULE" ]; then
    pass_check 12
else
    fail_check "Aturan DENY untuk IP 192.168.10.88 harus berada pada urutan pertama (Rule #1)."
fi

# CHALLENGE 4: RATE LIMIT FTP PORT 21/TCP (12 POIN)
echo -n "CH 4: Checking FTP Port 21/tcp Rate Limit Rule (12 pts)..."
FTP_LIMIT=$(ufw status 2>/dev/null | grep -i "21/tcp" | grep -i "LIMIT" || echo "")
if [ -n "$FTP_LIMIT" ]; then
    pass_check 12
else
    fail_check "Fitur Rate Limit (ufw limit 21/tcp) belum dikonfigurasi."
fi

# CHALLENGE 5: WEB STAGING (8080, 8443) & HIGH LOGGING (16 POIN)
echo -n "CH 5: Checking Web Staging Ports (8080, 8443) & High Logging Level (16 pts)..."
PORT_8080=$(ufw status 2>/dev/null | grep -E "^8080(/tcp)?\s+ALLOW" || echo "")
PORT_8443=$(ufw status 2>/dev/null | grep -E "^8443(/tcp)?\s+ALLOW" || echo "")
LOG_HIGH=$(ufw status verbose 2>/dev/null | grep -i "Logging:" | grep -i "high" || echo "")
if [ -n "$PORT_8080" ] && [ -n "$PORT_8443" ] && [ -n "$LOG_HIGH" ]; then
    pass_check 16
else
    fail_check "Port 8080/tcp, 8443/tcp wajib ALLOW dan level logging harus diatur ke HIGH."
fi

# CHALLENGE 6: IPSEC VPN TUNNEL (500/udp, 4500/udp) (12 POIN)
echo -n "CH 6: Checking IPsec VPN Ports (500/udp, 4500/udp) for IP 192.168.10.254 (12 pts)..."
VPN_500=$(ufw status 2>/dev/null | grep -i "500/udp" | grep "192.168.10.254" || echo "")
VPN_4500=$(ufw status 2>/dev/null | grep -i "4500/udp" | grep "192.168.10.254" || echo "")
if [ -n "$VPN_500" ] && [ -n "$VPN_4500" ]; then
    pass_check 12
else
    fail_check "Aturan port 500/udp dan 4500/udp untuk IP 192.168.10.254 tidak ditemukan."
fi

# CHALLENGE 7: DENY HTTP 80/TCP WITHOUT ALLOW CONFLICT (12 POIN)
echo -n "CH 7: Checking Explicit DENY Port 80/tcp (12 pts)..."
HTTP_ALLOW=$(ufw status 2>/dev/null | grep -E "^80(/tcp)?\s+ALLOW" || echo "")
HTTP_DENY=$(ufw status 2>/dev/null | grep -E "^80(/tcp)?\s+DENY" || echo "")
if [ -z "$HTTP_ALLOW" ] && [ -n "$HTTP_DENY" ]; then
    pass_check 12
else
    fail_check "Port 80/tcp harus memiliki aturan DENY dan tidak boleh ada aturan ALLOW 80/tcp yang tersisa."
fi

# CHALLENGE 8: POSTGRESQL 5432/TCP SUBNET (12 POIN)
echo -n "CH 8: Checking PostgreSQL 5432/tcp for Subnet 192.168.10.128/26 (12 pts)..."
PG_RULE=$(ufw status 2>/dev/null | grep -i "5432/tcp" | grep "192.168.10.128/26" || echo "")
if [ -n "$PG_RULE" ]; then
    pass_check 12
else
    fail_check "Aturan port 5432/tcp khusus subnet 192.168.10.128/26 tidak ditemukan."
fi

# Limit Maximum Score 100
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
  "chapter_id": "lab-ufw-8-challenges",
  "score": $score,
  "status": "$status"
}
EOF
