#!/bin/bash
# ================================================================
# AUTOMATED GRADER: SAMBA CHALLENGE LAB (PT. MAJU BERSAMA)
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
echo "  GRADER: SAMBA CHALLENGE PT. MAJU BERSAMA"
echo "================================================="
echo

# 1. CEK USER & GROUP (20 Pts)
echo -n "Step 1: Memeriksa User (akuntan1, akuntan2, sysadmin1, sysadmin2) & Group (tim_it) (20 pts)..."
if id "akuntan1" &>/dev/null && id "akuntan2" &>/dev/null && id "sysadmin1" &>/dev/null && id "sysadmin2" &>/dev/null && getent group tim_it &>/dev/null; then
    # Cek membership group tim_it dan database Samba (pdbedit)
    IN_IT1=$(id -nG sysadmin1 | grep -qw "tim_it" && echo "yes" || echo "no")
    IN_IT2=$(id -nG sysadmin2 | grep -qw "tim_it" && echo "yes" || echo "no")
    
    SMB_AK1=$(pdbedit -L 2>/dev/null | grep -qw "akuntan1" && echo "yes" || echo "no")
    SMB_AK2=$(pdbedit -L 2>/dev/null | grep -qw "akuntan2" && echo "yes" || echo "no")
    SMB_IT1=$(pdbedit -L 2>/dev/null | grep -qw "sysadmin1" && echo "yes" || echo "no")
    SMB_IT2=$(pdbedit -L 2>/dev/null | grep -qw "sysadmin2" && echo "yes" || echo "no")

    if [ "$IN_IT1" = "yes" ] && [ "$IN_IT2" = "yes" ] && [ "$SMB_AK1" = "yes" ] && [ "$SMB_AK2" = "yes" ] && [ "$SMB_IT1" = "yes" ] && [ "$SMB_IT2" = "yes" ]; then
        pass_check 20
    else
        fail_check "Keanggotaan group tim_it atau pendaftaran akun ke database Samba belum lengkap."
    fi
else
    fail_check "Salah satu atau seluruh user/group (akuntan1/2, sysadmin1/2, tim_it) belum dibuat."
fi

# 2. CEK DIREKTORI & OWNERSHIP (20 Pts)
echo -n "Step 2: Memeriksa Direktori (/srv/publik, /srv/keuangan, /srv/proyek_it) & Ownership (20 pts)..."
PUB_DIR="/srv/publik"
FIN_DIR="/srv/keuangan"
IT_DIR="/srv/proyek_it"

if [ -d "$PUB_DIR" ] && [ -d "$FIN_DIR" ] && [ -d "$IT_DIR" ]; then
    PUB_OWNER=$(stat -c "%U:%G" "$PUB_DIR")
    FIN_OWNER=$(stat -c "%U:%G" "$FIN_DIR")
    IT_OWNER=$(stat -c "%U:%G" "$IT_DIR")

    # Publik: nobody:nogroup, Keuangan: akuntan1/root, IT: root:tim_it
    if [ "$PUB_OWNER" = "nobody:nogroup" ] && [ "$IT_OWNER" = "root:tim_it" ]; then
        pass_check 20
    else
        fail_check "Ownership direktori belum sesuai (Publik: $PUB_OWNER, IT: $IT_OWNER)."
    fi
else
    fail_check "Satu atau lebih direktori share (/srv/publik, /srv/keuangan, /srv/proyek_it) tidak ditemukan."
fi

# 3. CEK KONFIGURASI SMB.CONF (40 Pts)
echo -n "Step 3: Memeriksa Blok Konfigurasi Samba di /etc/samba/smb.conf (40 pts)..."
SMB_CONF="/etc/samba/smb.conf"

if [ -f "$SMB_CONF" ]; then
    if testparm -s >/dev/null 2>&1; then
        # Cek share publik
        HAS_PUB=$(grep -E '^[[:space:]]*\[publik\]' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_PUB_GUEST=$(grep -E 'guest[[:space:]]*ok[[:space:]]*=[[:space:]]*yes' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        
        # Cek share keuangan
        HAS_FIN=$(grep -E '^[[:space:]]*\[keuangan\]' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_FIN_USERS=$(grep -E 'valid[[:space:]]+users[[:space:]]*=[[:space:]]*akuntan1[[:space:]]*,[[:space:]]*akuntan2|valid[[:space:]]+users[[:space:]]*=[[:space:]]*akuntan2[[:space:]]*,[[:space:]]*akuntan1' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        [ "$HAS_FIN_USERS" = "no" ] && grep -qE 'valid[[:space:]]+users[[:space:]]*=.*akuntan1.*akuntan2' "$SMB_CONF" && HAS_FIN_USERS="yes"

        # Cek share proyek_it
        HAS_IT=$(grep -E '^[[:space:]]*\[proyek_it\]' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_IT_USERS=$(grep -E 'valid[[:space:]]+users[[:space:]]*=[[:space:]]*@tim_it' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")

        if [ "$HAS_PUB" = "yes" ] && [ "$HAS_PUB_GUEST" = "yes" ] && [ "$HAS_FIN" = "yes" ] && [ "$HAS_FIN_USERS" = "yes" ] && [ "$HAS_IT" = "yes" ] && [ "$HAS_IT_USERS" = "yes" ]; then
            pass_check 40
        else
            REASON=""
            [ "$HAS_PUB" = "no" ] && REASON="Blok '[publik]' tidak ada/salah. "
            [ "$HAS_FIN" = "no" ] && REASON="${REASON}Blok '[keuangan]' tidak ada/salah. "
            [ "$HAS_FIN_USERS" = "no" ] && REASON="${REASON}Valid users keuangan harus akuntan1 dan akuntan2. "
            [ "$HAS_IT" = "no" ] && REASON="${REASON}Blok '[proyek_it]' tidak ada/salah. "
            [ "$HAS_IT_USERS" = "no" ] && REASON="${REASON}Valid users proyek_it harus '@tim_it'."
            fail_check "$REASON"
        fi
    else
        fail_check "Sintaks file konfigurasi Samba (/etc/samba/smb.conf) tidak valid (gagal diuji testparm)."
    fi
else
    fail_check "Berkas konfigurasi $SMB_CONF tidak ditemukan."
fi

# 4. CEK STATUS LAYANAN SAMBA (20 Pts)
echo -n "Step 4: Memeriksa Status Layanan Samba (smbd) Berjalan (20 pts)..."
if systemctl is-active --quiet smbd 2>/dev/null; then
    pass_check 20
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
  "chapter_id": "lab-samba-challenge-ch73",
  "score": $score,
  "status": "$status"
}
EOF
