#!/bin/bash
# ================================================================
# AUTOMATED GRADER: SAMBA LAB 3 (GROUP SHARE - DEVELOPERS)
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
echo "  GRADER: SAMBA GROUP PROJECT SHARE (LAB 3)"
echo "================================================="
echo

# 1. CEK GROUP & USER (25 Pts)
echo -n "Step 1: Memeriksa Group 'developers' & User (dev1, dev2) di Linux & Samba (25 pts)..."
if getent group developers &>/dev/null && id "dev1" &>/dev/null && id "dev2" &>/dev/null; then
    # Cek membership group developers dan database Samba (pdbedit)
    IN_DEV1=$(id -nG dev1 | grep -qw "developers" && echo "yes" || echo "no")
    IN_DEV2=$(id -nG dev2 | grep -qw "developers" && echo "yes" || echo "no")
    SMB_DEV1=$(pdbedit -L 2>/dev/null | grep -qw "dev1" && echo "yes" || echo "no")
    SMB_DEV2=$(pdbedit -L 2>/dev/null | grep -qw "dev2" && echo "yes" || echo "no")

    if [ "$IN_DEV1" = "yes" ] && [ "$IN_DEV2" = "yes" ] && [ "$SMB_DEV1" = "yes" ] && [ "$SMB_DEV2" = "yes" ]; then
        pass_check 25
    else
        fail_check "User dev1/dev2 belum tergabung dalam group 'developers' atau belum terdaftar di database Samba."
    fi
else
    fail_check "Grup 'developers' atau user 'dev1'/'dev2' belum dibuat."
fi

# 2. CEK DIREKTORI & OWNERSHIP GROUP_PROJECT (25 Pts)
echo -n "Step 2: Memeriksa Direktori /srv/group_project & Ownership (root:developers) (25 pts)..."
SHARE_DIR="/srv/group_project"

if [ -d "$SHARE_DIR" ]; then
    DIR_OWNER=$(stat -c "%U:%G" "$SHARE_DIR")
    if [ "$DIR_OWNER" = "root:developers" ]; then
        pass_check 25
    else
        fail_check "Ownership direktori tidak sesuai. Harus 'root:developers' (saat ini: $DIR_OWNER)."
    fi
else
    fail_check "Direktori $SHARE_DIR tidak ditemukan."
fi

# 3. CEK KONFIGURASI SMB.CONF UNTUK GROUP_PROJECT (35 Pts)
echo -n "Step 3: Memeriksa Konfigurasi share [group_project] di /etc/samba/smb.conf (35 pts)..."
SMB_CONF="/etc/samba/smb.conf"

if [ -f "$SMB_CONF" ]; then
    if testparm -s >/dev/null 2>&1; then
        HAS_SECTION=$(grep -E '^[[:space:]]*\[group_project\]' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_PATH=$(grep -E 'path[[:space:]]*=[[:space:]]*/srv/group_project' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")
        HAS_VALID_USERS=$(grep -E 'valid[[:space:]]+users[[:space:]]*=[[:space:]]*@developers' "$SMB_CONF" >/dev/null && echo "yes" || echo "no")

        if [ "$HAS_SECTION" = "yes" ] && [ "$HAS_PATH" = "yes" ] && [ "$HAS_VALID_USERS" = "yes" ]; then
            pass_check 35
        else
            REASON=""
            [ "$HAS_SECTION" = "no" ] && REASON="Blok '[group_project]' tidak ditemukan. "
            [ "$HAS_PATH" = "no" ] && REASON="${REASON}Path '/srv/group_project' tidak terdefinisi dengan benar. "
            [ "$HAS_VALID_USERS" = "no" ] && REASON="${REASON}Parameter 'valid users = @developers' belum dikonfigurasi dengan benar."
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
  "chapter_id": "lab-samba-group-ch72",
  "score": $score,
  "status": "$status"
}
EOF
