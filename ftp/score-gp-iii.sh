#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 66 (KONFIGURASI PROFTPD TLS/SSL)
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
echo "  GRADER: LAB 66 (KONFIGURASI PROFTPD TLS/SSL)"
echo "================================================="
echo

# 1. CEK KEBERADAAN PEM/CERTIFICATE FILE (25 Pts)
echo -n "Step 1: Memeriksa Sertifikat SSL/PEM di /etc/ssl/private/proftpd.pem (25 pts)..."
PEM_FILE="/etc/ssl/private/proftpd.pem"

if [ -f "$PEM_FILE" ]; then
    # Memastikan file berisi sertifikat X.509 dan Private Key yang valid
    if grep -q "BEGIN CERTIFICATE" "$PEM_FILE" && grep -q "PRIVATE KEY" "$PEM_FILE"; then
        pass_check 25
    else
        fail_check "Berkas $PEM_FILE ada tetapi tidak berisi sertifikat atau private key yang valid."
    fi
else
    fail_check "Berkas sertifikat SSL $PEM_FILE tidak ditemukan."
fi

# 2. CEK MODUL & INCLUDE TLS DI PROFTPD (25 Pts)
echo -n "Step 2: Memeriksa Pemuatan Modul TLS & Include tls.conf (25 pts)..."
MODULES_CONF="/etc/proftpd/modules.conf"
MAIN_CONF="/etc/proftpd/proftpd.conf"

MOD_TLS_OK=$(grep -v '^[[:space:]]*#' "$MODULES_CONF" 2>/dev/null | grep -E 'LoadModule[[:space:]]+mod_tls\.c' >/dev/null && echo "yes" || echo "no")
INC_TLS_OK=$(grep -v '^[[:space:]]*#' "$MAIN_CONF" 2>/dev/null | grep -E 'Include[[:space:]]+/etc/proftpd/tls\.conf' >/dev/null && echo "yes" || echo "no")

if [ "$MOD_TLS_OK" = "yes" ] && [ "$INC_TLS_OK" = "yes" ]; then
    pass_check 25
else
    REASON=""
    [ "$MOD_TLS_OK" = "no" ] && REASON="'LoadModule mod_tls.c' belum di-uncomment di modules.conf. "
    [ "$INC_TLS_OK" = "no" ] && REASON="${REASON}'Include /etc/proftpd/tls.conf' belum di-uncomment di proftpd.conf."
    fail_check "$REASON"
fi

# 3. CEK KONFIGURASI TLS.CONF (25 Pts)
echo -n "Step 3: Memeriksa Direktori & Pengaturan di /etc/proftpd/tls.conf (25 pts)..."
TLS_CONF="/etc/proftpd/tls.conf"

if [ -f "$TLS_CONF" ]; then
    ENGINE_OK=$(grep -v '^[[:space:]]*#' "$TLS_CONF" | grep -iE 'TLSEngine[[:space:]]+on' >/dev/null && echo "yes" || echo "no")
    CERT_OK=$(grep -v '^[[:space:]]*#' "$TLS_CONF" | grep -E 'TLSRSACertificateFile[[:space:]]+/etc/ssl/private/proftpd\.pem' >/dev/null && echo "yes" || echo "no")
    KEY_OK=$(grep -v '^[[:space:]]*#' "$TLS_CONF" | grep -E 'TLSRSACertificateKeyFile[[:space:]]+/etc/ssl/private/proftpd\.pem' >/dev/null && echo "yes" || echo "no")

    if [ "$ENGINE_OK" = "yes" ] && [ "$CERT_OK" = "yes" ] && [ "$KEY_OK" = "yes" ]; then
        pass_check 25
    else
        REASON=""
        [ "$ENGINE_OK" = "no" ] && REASON="'TLSEngine on' belum diaktifkan. "
        [ "$CERT_OK" = "no" ] && REASON="${REASON}'TLSRSACertificateFile' tidak sesuai. "
        [ "$KEY_OK" = "no" ] && REASON="${REASON}'TLSRSACertificateKeyFile' tidak sesuai."
        fail_check "$REASON"
    fi
else
    fail_check "Berkas $TLS_CONF tidak ditemukan."
fi

# 4. CEK PAKET MOD-CRYPTO & STATUS LAYANAN PROFTPD (25 Pts)
echo -n "Step 4: Memeriksa Paket proftpd-mod-crypto & Status Layanan (25 pts)..."
if dpkg -l | grep -q "^ii  proftpd-mod-crypto"; then
    PROFTPD_ACT=$(systemctl is-active proftpd 2>/dev/null || service proftpd status 2>/dev/null | grep -q "running" && echo "active" || echo "inactive")
    if [ "$PROFTPD_ACT" = "active" ]; then
        pass_check 25
    else
        fail_check "Paket proftpd-mod-crypto terinstall tetapi layanan ProFTPD tidak aktif."
    fi
else
    fail_check "Paket proftpd-mod-crypto belum terinstall di sistem."
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
  "chapter_id": "lab-proftpd-tls-ch66",
  "score": $score,
  "status": "$status"
}
EOF
