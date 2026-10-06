#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 64 (INSTALASI DAN KONFIGURASI DASAR PROFTPD)
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
echo "  GRADER: LAB 64 (INSTALASI & KONFIGURASI PROFTPD)"
echo "================================================="
echo

# 1. CEK HOSTNAME SERVER (20 Pts)
echo -n "Step 1: Memeriksa Hostname Server 'ftp-server' (20 pts)..."
CURRENT_HOSTNAME=$(hostnamectl hostname 2>/dev/null || hostname)
if [ "$CURRENT_HOSTNAME" = "ftp-server" ]; then
    pass_check 20
else
    fail_check "Hostname server saat ini adalah '$CURRENT_HOSTNAME', seharusnya 'ftp-server'."
fi

# 2. CEK INSTALASI & STATUS PROFTPD (20 Pts)
echo -n "Step 2: Memeriksa Instalasi & Status Layanan ProFTPD (20 pts)..."
if dpkg -l | grep -q "^ii  proftpd"; then
    PROFTPD_ACT=$(systemctl is-active proftpd 2>/dev/null || service proftpd status 2>/dev/null | grep -q "running" && echo "active" || echo "inactive")
    if [ "$PROFTPD_ACT" = "active" ]; then
        pass_check 20
    else
        fail_check "Paket proftpd terinstall tetapi layanannya tidak aktif (Status: $PROFTPD_ACT)."
    fi
else
    fail_check "Paket proftpd belum terinstall di sistem."
fi

# 3. CEK ETCHOSTS RESOLUTION (20 Pts)
echo -n "Step 3: Memeriksa Pemetaan IP dan Hostname di /etc/hosts (20 pts)..."
if grep -qE "192\.168\.10\.10[[:space:]]+ftp-server" /etc/hosts; then
    pass_check 20
else
    fail_check "Baris '192.168.10.10 ftp-server' tidak ditemukan di /etc/hosts."
fi

# 4. CEK KONFIGURASI PROFTPD (40 Pts)
echo -n "Step 4: Memeriksa Konfigurasi DefaultRoot & ServerName (40 pts)..."
CONF_FILE="/etc/proftpd/proftpd.conf"

if [ -f "$CONF_FILE" ]; then
    # Cek ServerName "ftp-server"
    SERVER_NAME_OK=$(grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -i 'ServerName' | grep -q '"ftp-server"' && echo "yes" || echo "no")
    
    # Cek DefaultRoot ~ (tanpa tanda pagar di depannya)
    DEFAULT_ROOT_OK=$(grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -E '^[[:space:]]*DefaultRoot[[:space:]]+~' >/dev/null && echo "yes" || echo "no")

    if [ "$SERVER_NAME_OK" = "yes" ] && [ "$DEFAULT_ROOT_OK" = "yes" ]; then
        pass_check 40
    else
        REASON=""
        [ "$SERVER_NAME_OK" = "no" ] && REASON="ServerName 'ftp-server' tidak terkonfigurasi dengan benar. "
        [ "$DEFAULT_ROOT_OK" = "no" ] && REASON="${REASON}DefaultRoot ~ belum di-uncomment atau diatur."
        fail_check "$REASON"
    fi
else
    fail_check "Berkas konfigurasi $CONF_FILE tidak ditemukan."
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
  "chapter_id": "lab-proftpd-basic-ch64",
  "score": $score,
  "status": "$status"
}
EOF
