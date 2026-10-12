#!/bin/bash
# ================================================================
# AUTOMATED GRADER: SAMBA LAB 2 (PRIVATE SHARE DENGAN OTENTIKASI)
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
echo "  GRADER: SAMBA PRIVATE SHARE (LAB 2)"
echo "================================================="
echo

# 1. CEK USER LINUX & SAMBA (25 Pts)
echo -n "Step 1: Memeriksa User 'siswa1' di Linux & Database Samba (25 pts)..."
if id "siswa1" &>/dev/null; then
    # Periksa apakah user terdaftar di database samba (pdbedit)
    if pdbedit -L 2>/dev/null | grep -qw "siswa1"; then
        pass_check 25
    else
        fail_check "User 'siswa1' ada di Linux, tetapi belum ditambahkan ke database Samba (smbpasswd)."
    fi
else
    fail_check "User sistem 'siswa1' belum dibuat."
fi

# 2. CEK DIREKTORI & OWNERSHIP PRIVATE_SHARE (25 Pts)
echo -n "Step 2: Memeriksa Direktori /srv/private_share & Ownership (siswa1:siswa1) (25 pts)..."
SHARE_DIR="/srv/private_share"

if [ -d "$SHARE_DIR" ]; then
    DIR_OWNER=$(stat -c "%U:%G" "$SHARE_DIR")
    if [ "$DIR_OWNER" = "siswa1:siswa1" ]; then
        pass_check 25
    else
        fail_check "Ownership direktori tidak sesuai. Harus 'siswa1:siswa1' (saat ini: $DIR_OWNER)."
    fi
else
    fail_check "Direktori $SHARE_DIR tidak ditemukan."
fi

# 3. CEK KONFIGURASI SMB.CONF UNTUK PRIVATE_SHARE (35 Pts)
echo -n "Step 3: Memeriksa Konfigurasi share [private_share] di /etc/samba/smb.conf (35 pts)..."
SMB_CONF="/etc/samba/smb.conf"

if [ -f "$SMB_CONF" ]; then
    if testparm -s >/dev/null 2>&1; then
        HAS_SECTION=$(grep -E '^[[:space:]]*\[private_share\]' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_PATH=$(grep -E 'path[[:space:]]*=[[:space:]]*/srv/private_share' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_VALID_USERS=$(grep -E 'valid[[:space:]]+users[[:space:]]*=[[:space:]]*siswa1' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_WRITE=$(grep -E '(writable|read[[:space:]]+only)[[:space:]]*=[[:space:]]*(yes|no)' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")

        if [ "$HAS_SECTION" = "yes" ] && [ "$HAS_PATH" = "yes" ] && [ "$HAS_VALID_USERS" = "yes" ]; then
            pass_check 35
        else
            REASON=""
            [ "$HAS_SECTION" = "no" ] && REASON="Blok '[private_share]' tidak ditemukan. "
            [ "$HAS_PATH" = "no" ] && REASON="${REASON}Path '/srv/private_share' tidak terdefinisi dengan benar. "
            [ "$HAS_VALID_USERS" = "no" ] && REASON="${REASON}Parameter 'valid users = siswa1' belum dikonfigurasi."
            fail_check "$REASON"
        fi
    else
        fail_check "Sintaks file konfigurasi Samba (/etc/samba/smb.conf) tidak valid (gagal diuji testparm)."
    fi
else
    fail_check "Berkas konfigurasi $SMB_CONF tidak ditemukan."
fi

# 4. CEK STATUS LAYANAN SAMBA (15 Pts)
echo -n "Step 4: Memeriksa Status Layanan Samba (smbd) Berjalan (15 pts)..."
if systemctl is-active --quiet smbd 2>/dev/null; then
    pass_check 15
else
    fail_check "Layanan Samba 'smbd' tidak aktif atau tidak berjalan."
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
  "chapter_id": "lab-samba-private-ch71",
  "score": $score,
  "status": "$status"
}
EOF
