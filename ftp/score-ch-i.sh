#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 67 (CHALLENGE FTP MULTIMEDIA)
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
echo "  GRADER: LAB 67 (CHALLENGE FTP MULTIMEDIA)"
echo "================================================="
echo

# 1. CEK USER DAN GROUP (20 Pts)
echo -n "Step 1: Memeriksa User (webdesign1, logo1, logo2) & Group (logo) (20 pts)..."
if id "webdesign1" &>/dev/null && id "logo1" &>/dev/null && id "logo2" &>/dev/null; then
    if getent group logo | grep -qE "\blogo1\b" && getent group logo | grep -qE "\blogo2\b"; then
        pass_check 20
    else
        fail_check "User 'logo1' atau 'logo2' belum terdaftar di dalam group 'logo'."
    fi
else
    fail_check "Salah satu atau seluruh user (webdesign1, logo1, logo2) belum dibuat."
fi

# 2. CEK DIREKTORI DAN HAK AKSES / OWNERSHIP (20 Pts)
echo -n "Step 2: Memeriksa Direktori & Hak Akses Folder Divisi (20 pts)..."
WEB_DIR="/srv/ftp/desain-web"
LOGO_DIR="/srv/ftp/logo"

if [ -d "$WEB_DIR" ] && [ -d "$LOGO_DIR" ]; then
    WEB_OWNER=$(stat -c "%U" "$WEB_DIR")
    LOGO_GROUP=$(stat -c "%G" "$LOGO_DIR")
    LOGO_PERM=$(stat -c "%a" "$LOGO_DIR")

    if [ "$WEB_OWNER" = "webdesign1" ] && [ "$LOGO_GROUP" = "logo" ]; then
        pass_check 20
    else
        fail_check "Ownership direktori tidak sesuai. /srv/ftp/desain-web owner harus 'webdesign1' (saat ini: $WEB_OWNER), /srv/ftp/logo group harus 'logo' (saat ini: $LOGO_GROUP)."
    fi
else
    fail_check "Direktori /srv/ftp/desain-web atau /srv/ftp/logo tidak ditemukan."
fi

# 3. CEK KONFIGURASI DEFAULTROOT (20 Pts)
echo -n "Step 3: Memeriksa Konfigurasi DefaultRoot per Divisi (20 pts)..."
CONF_FILE="/etc/proftpd/proftpd.conf"

if [ -f "$CONF_FILE" ]; then
    GLOBAL_ROOT_OFF=$(grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -E '^[[:space:]]*DefaultRoot[[:space:]]+~' >/dev/null && echo "no" || echo "yes")
    WEB_ROOT_OK=$(grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -E '^[[:space:]]*DefaultRoot[[:space:]]+/srv/ftp/desain-web[[:space:]]+webdesign1' >/dev/null && echo "yes" || echo "no")
    LOGO_ROOT_OK=$(grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -E '^[[:space:]]*DefaultRoot[[:space:]]+/srv/ftp/logo[[:space:]]+logo' >/dev/null && echo "yes" || echo "no")

    if [ "$GLOBAL_ROOT_OFF" = "yes" ] && [ "$WEB_ROOT_OK" = "yes" ] && [ "$LOGO_ROOT_OK" = "yes" ]; then
        pass_check 20
    else
        REASON=""
        [ "$GLOBAL_ROOT_OFF" = "no" ] && REASON="'DefaultRoot ~' masih aktif (harus di-comment). "
        [ "$WEB_ROOT_OK" = "no" ] && REASON="${REASON}Baris 'DefaultRoot /srv/ftp/desain-web webdesign1' tidak ditemukan. "
        [ "$LOGO_ROOT_OK" = "no" ] && REASON="${REASON}Baris 'DefaultRoot /srv/ftp/logo logo' tidak ditemukan."
        fail_check "$REASON"
    fi
else
    fail_check "Berkas $CONF_FILE tidak ditemukan."
fi

# 4. CEK SERTIFIKAT DKV.PEM DAN KONFIGURASI TLS (20 Pts)
echo -n "Step 4: Memeriksa Sertifikat dkv.pem & Konfigurasi TLS (20 pts)..."
PEM_FILE="/etc/ssl/private/dkv.pem"
TLS_CONF="/etc/proftpd/tls.conf"

if [ -f "$PEM_FILE" ] && [ -f "$TLS_CONF" ]; then
    ENGINE_OK=$(grep -v '^[[:space:]]*#' "$TLS_CONF" | grep -iE 'TLSEngine[[:space:]]+on' >/dev/null && echo "yes" || echo "no")
    CERT_OK=$(grep -v '^[[:space:]]*#' "$TLS_CONF" | grep -E 'TLSRSACertificateFile[[:space:]]+/etc/ssl/private/dkv\.pem' >/dev/null && echo "yes" || echo "no")
    KEY_OK=$(grep -v '^[[:space:]]*#' "$TLS_CONF" | grep -E 'TLSRSACertificateKeyFile[[:space:]]+/etc/ssl/private/dkv\.pem' >/dev/null && echo "yes" || echo "no")

    if [ "$ENGINE_OK" = "yes" ] && [ "$CERT_OK" = "yes" ] && [ "$KEY_OK" = "yes" ]; then
        pass_check 20
    else
        fail_check "Konfigurasi di $TLS_CONF belum mengarah ke $PEM_FILE atau TLSEngine belum aktif."
    fi
else
    fail_check "Sertifikat $PEM_FILE atau $TLS_CONF tidak ditemukan."
fi

# 5. CEK STATUS LAYANAN PROFTPD (20 Pts)
echo -n "Step 5: Memeriksa Status Layanan ProFTPD (20 pts)..."
PROFTPD_ACT=$(systemctl is-active proftpd 2>/dev/null || service proftpd status 2>/dev/null | grep -q "running" && echo "active" || echo "inactive")

if [ "$PROFTPD_ACT" = "active" ]; then
    pass_check 20
else
    fail_check "Layanan ProFTPD tidak aktif (Status: $PROFTPD_ACT)."
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
  "chapter_id": "lab-proftpd-challenge-ch67",
  "score": $score,
  "status": "$status"
}
EOF
