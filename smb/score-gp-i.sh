#!/bin/bash
# ================================================================
# AUTOMATED GRADER: SAMBA LAB 1 (PUBLIC SHARE TANPA OTENTIKASI)
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
echo "  GRADER: SAMBA PUBLIC SHARE (LAB 1)"
echo "================================================="
echo

# 1. CEK HOSTNAME SERVER (15 Pts)
echo -n "Step 1: Memeriksa Hostname Server 'samba-server' (15 pts)..."
CURRENT_HOSTNAME=$(hostnamectl hostname 2>/dev/null || hostname)
if [ "$CURRENT_HOSTNAME" = "samba-server" ]; then
    pass_check 15
else
    fail_check "Hostname server saat ini adalah '$CURRENT_HOSTNAME', seharusnya 'samba-server'."
fi

# 2. CEK INSTALASI & STATUS LAYANAN SAMBA (20 Pts)
echo -n "Step 2: Memeriksa Instalasi & Status Layanan Samba (smbd/nmbd) (20 pts)..."
if dpkg -l | grep -E '^ii[[:space:]]+samba' >/dev/null 2>&1; then
    if systemctl is-active --quiet smbd 2>/dev/null; then
        pass_check 20
    else
        fail_check "Paket samba terinstall tetapi layanan 'smbd' tidak aktif."
    fi
else
    fail_check "Paket samba belum terinstall di sistem."
fi

# 3. CEK DIREKTORI & PERMISSION/OWNERSHIP (25 Pts)
echo -n "Step 3: Memeriksa Direktori /srv/public_share & Ownership (nobody:nogroup) (25 pts)..."
SHARE_DIR="/srv/public_share"

if [ -d "$SHARE_DIR" ]; then
    DIR_OWNER=$(stat -c "%U:%G" "$SHARE_DIR")
    # Periksa izin akses (minimal write/read untuk others, e.g., 777 atau sejenisnya)
    if [ "$DIR_OWNER" = "nobody:nogroup" ]; then
        pass_check 25
    else
        fail_check "Ownership direktori tidak sesuai. Harus 'nobody:nogroup' (saat ini: $DIR_OWNER)."
    fi
else
    fail_check "Direktori $SHARE_DIR tidak ditemukan."
fi

# 4. CEK KONFIGURASI SMB.CONF (40 Pts)
echo -n "Step 4: Memeriksa Konfigurasi share [public_share] di /etc/samba/smb.conf (40 pts)..."
SMB_CONF="/etc/samba/smb.conf"

if [ -f "$SMB_CONF" ]; then
    # Validasi sintaks smb.conf via testparm secara silent
    if testparm -s >/dev/null 2>&1; then
        # Cek apakah blok [public_share] ada dan konfigurasi guest ok / writable aktif
        HAS_SECTION=$(grep -E '^[[:space:]]*\[public_share\]' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_PATH=$(grep -E 'path[[:space:]]*=[[:space:]]*/srv/public_share' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_GUEST=$(grep -E 'guest[[:space:]]*ok[[:space:]]*=[[:space:]]*yes' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_WRITE=$(grep -E '(writable|read[[:space:]]+only)[[:space:]]*=[[:space:]]*(yes|no)' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")

        if [ "$HAS_SECTION" = "yes" ] && [ "$HAS_PATH" = "yes" ] && [ "$HAS_GUEST" = "yes" ]; then
            pass_check 40
        else
            REASON=""
            [ "$HAS_SECTION" = "no" ] && REASON="Blok '[public_share]' tidak ditemukan. "
            [ "$HAS_PATH" = "no" ] && REASON="${REASON}Path '/srv/public_share' tidak terdefinisi dengan benar. "
            [ "$HAS_GUEST" = "no" ] && REASON="${REASON}Parameter 'guest ok = yes' belum dikonfigurasi."
            fail_check "$REASON"
        fi
    else
        fail_check "Sintaks file konfigurasi Samba (/etc/samba/smb.conf) tidak valid (gagal diuji testparm)."
    fi
else
    fail_check "Berkas konfigurasi $SMB_CONF tidak ditemukan."
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
  "chapter_id": "lab-samba-public-ch68",
  "score": $score,
  "status": "$status"
}
EOF
