#!/bin/bash
# ==============================================================================
# Script Name   : score-master.sh
# Description   : Automated Scoring & Verification for DNS Master (Chapter 14)
# Author        : IT Network System Administration Lab
# ==============================================================================

# Color Palette
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCORE=0
TOTAL_TESTS=10
WEIGHT_PER_TEST=10

RESULT_FILE="../result.json"
BIND_CONF="/etc/bind/named.conf.local"
SLAVE_IP="192.168.10.12"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}      DNS MASTER CHECKER - CHAPTER 14    ${NC}"
echo -e "${BLUE}=========================================${NC}"

# Function: Print status PASS/FAIL
print_result() {
    local label="$1"
    local status="$2"
    if [ "$status" -eq 0 ]; then
        echo -e "$(printf '%-33s' "$label")......[${GREEN}PASS${NC}]"
        SCORE=$((SCORE + WEIGHT_PER_TEST))
    else
        echo -e "$(printf '%-33s' "$label")......[${RED}FAIL${NC}]"
    fi
}

# 1. Check BIND9 Installation
dpkg -l | grep -q bind9
print_result "Checking Bind9 Installation" $?

# 2. Check BIND9 Service Status
systemctl is-active --quiet bind9 || systemctl is-active --quiet named
print_result "Checking Bind9 Service" $?

# 3. Check BIND9 Configuration Syntax
named-checkconf > /dev/null 2>&1
print_result "Checking Named Config Syntax" $?

# 4. Check Allow-Transfer Configuration (Targeting Slave 192.168.10.12)
grep -q "allow-transfer" "$BIND_CONF" 2>/dev/null && grep -q "$SLAVE_IP" "$BIND_CONF" 2>/dev/null
print_result "Checking Allow Transfer Config" $?

# 5. Check Challenge 1 — absensiq.lan
dig @127.0.0.1 www.absensiq.lan +short | grep -q "192.168.70.10"
print_result "Checking Zone absensiq.lan" $?

# 6. Check Challenge 2 — inventarisx.lan
dig @127.0.0.1 app.inventarisx.lan +short | grep -q "192.168.71.20"
print_result "Checking Zone inventarisx.lan" $?

# 7. Check Challenge 3 — gurupedia.lan
dig @127.0.0.1 portal.gurupedia.lan +short | grep -q "192.168.72.30"
print_result "Checking Zone gurupedia.lan" $?

# 8. Check Challenge 4 — koperasix.lan (including new record)
dig @127.0.0.1 backup.koperasix.lan +short | grep -q "192.168.73.20"
print_result "Checking Zone koperasix.lan" $?

# 9. Check Challenge 5 & 6 — pegawaihub.lan & dokumensmart.lan
RES_PEG=$(dig @127.0.0.1 hr.pegawaihub.lan +short)
RES_DOC=$(dig @127.0.0.1 storage.dokumensmart.lan +short)
if [ "$RES_PEG" == "192.168.74.20" ] && [ "$RES_DOC" == "192.168.75.20" ]; then
    print_result "Checking Zone pegawai & dokumen" 0
else
    print_result "Checking Zone pegawai & dokumen" 1
fi

# 10. Check Challenge 7 — datacore.lan
dig @127.0.0.1 monitor.datacore.lan +short | grep -q "192.168.76.40"
print_result "Checking Zone datacore.lan" $?

echo -e "${BLUE}=========================================${NC}"

if [ $SCORE -eq 100 ]; then
    echo -e "${GREEN}MISSION COMPLETE${NC}"
else
    echo -e "${YELLOW}MISSION INCOMPLETE${NC}"
fi

echo -e "Score : ${SCORE} / 100"
echo -e "${BLUE}=========================================${NC}"

# Save score to JSON
mkdir -p "$(dirname "$RESULT_FILE")"
cat << EOF > "$RESULT_FILE"
{
  "chapter": 14,
  "role": "master",
  "score": $SCORE,
  "status": "$([ $SCORE -eq 100 ] && echo "PASS" || echo "FAIL")",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
