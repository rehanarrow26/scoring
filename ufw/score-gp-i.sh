#!/bin/bash
# ================================================================
# SCORING SCRIPT: TANTANGAN MANAJEMEN FIREWALL UFW (CHAPTER 43)
# Target IP Server : 192.168.10.10
# Blocked Client IP: 192.168.10.20
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
echo "  GRADER: KONFIGURASI FIREWALL UFW (CHAPTER 43)"
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK STATUS AKTIF UFW & DEFAULT INCOMING POLICY (25 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking UFW Service Status & Default Policy (25 pts)..."
UFW_STATUS=$(ufw status 2>/dev/null | grep -i "Status: active" || echo "")
DEFAULT_DENY=$(ufw status verbose 2>/dev/null | grep -i "Default:" | grep -i "deny (incoming)" || echo "")

if [ -n "$UFW_STATUS" ] && [ -n "$DEFAULT_DENY" ]; then
    pass_check 25
else
    fail_check "UFW tidak aktif atau Kebijakan Default Incoming tidak di-set ke 'deny'."
fi

# ------------------------------------------------------------------
# 2. CEK ATURAN PORT SSH 22/TCP (25 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking SSH Rule - Port 22/tcp Allowed (25 pts)..."
SSH_ALLOW=$(ufw status 2>/dev/null | grep -E "^22(/tcp)?\s+ALLOW" || echo "")

if [ -n "$SSH_ALLOW" ]; then
    pass_check 25
else
    fail_check "Aturan perizinan port 22/tcp (SSH) tidak ditemukan di UFW."
fi

# ------------------------------------------------------------------
# 3. CEK ATURAN PORT HTTP 80/TCP (25 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Web Server Rule - Port 80/tcp Allowed (25 pts)..."
HTTP_ALLOW=$(ufw status 2>/dev/null | grep -E "^80(/tcp)?\s+ALLOW" || echo "")

if [ -n "$HTTP_ALLOW" ]; then
    pass_check 25
else
    fail_check "Aturan perizinan port 80/tcp (HTTP) tidak ditemukan di UFW."
fi

# ------------------------------------------------------------------
# 4. CEK PEMBLOKIRAN SPESIFIK IP KLIEN 192.168.10.20 (25 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Specific Block Rule for 192.168.10.20 (25 pts)..."
BLOCK_RULE=$(ufw status numbered 2>/dev/null | grep -i "DENY" | grep "192.168.10.20" || echo "")

if [ -n "$BLOCK_RULE" ]; then
    pass_check 25
else
    fail_check "Aturan pemblokiran spesifik (DENY) untuk IP 192.168.10.20 ke port 80 tidak ditemukan."
fi

# Limit Score Max 100
[ "$score" -gt 100 ] && score=100

echo
echo "================================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Score: $score/100\e[0m"
    status="FAIL"
fi
echo "================================================="

# Simpan hasil penilaian JSON untuk LMS Integrasi
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-43-ufw-firewall-challenge",
  "score": $score,
  "status": "$status"
}
EOF
