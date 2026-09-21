#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 62 (CHALLENGE MULTI-DOMAIN SSL & AUTH)
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
echo "  GRADER: LAB 62 (CHALLENGE MULTI-DOMAIN SSL & AUTH)"
echo "================================================="
echo

# 0. PRASYARAT SERVER
echo -n "Step 0: Memeriksa status Apache2 (Active) & Nginx (Inactive) (10 pts)..."
APACHE_ACT=$(systemctl is-active apache2 2>/dev/null || echo "inactive")
NGINX_ACT=$(systemctl is-active nginx 2>/dev/null || echo "inactive")

if [ "$APACHE_ACT" = "active" ] && [ "$NGINX_ACT" != "active" ]; then
    pass_check 10
else
    fail_check "Apache2 harus 'active' ($APACHE_ACT) dan Nginx harus 'inactive' ($NGINX_ACT)."
fi

# FUNGSI CEK SOAL INDIVIDUAL
check_challenge_item() {
    local ITEM_NUM=$1
    local DOMAIN=$2
    local CA_DIR=$3
    local HTPASSWD=$4
    local USER=$5
    local PASS=$6

    echo "--- Soal $ITEM_NUM: $DOMAIN ---"
    
    # Check CA Root & Cert Existence
    if [ ! -f "$CA_DIR/rootCA.crt" ] || [ ! -f "$CA_DIR/rootCA.key" ]; then
        fail_check "CA Root di $CA_DIR tidak ditemukan."
        return
    fi

    if [ ! -f "/etc/ssl/certs/$DOMAIN.crt" ] || [ ! -f "/etc/ssl/private/$DOMAIN.key" ]; then
        fail_check "Sertifikat atau Key SSL untuk $DOMAIN tidak ditemukan."
        return
    fi

    # Check htpasswd user
    if [ ! -f "$HTPASSWD" ] || ! grep -q "^$USER:" "$HTPASSWD"; then
        fail_check "Berkas $HTPASSWD tidak ada atau user '$USER' belum terdaftar."
        return
    fi

    # Check Unauth Response (HTTP 401)
    UNAUTH_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" https://127.0.0.1/ || echo "000")
    if [ "$UNAUTH_CODE" -ne 401 ]; then
        fail_check "Akses HTTPS tanpa autentikasi ke $DOMAIN tidak menghasilkan HTTP 401 (Respon: $UNAUTH_CODE)."
        return
    fi

    # Check Auth Response (HTTP 200)
    AUTH_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" -u "$USER:$PASS" https://127.0.0.1/ || echo "000")
    if [ "$AUTH_CODE" -ne 200 ]; then
        fail_check "Login HTTPS ke $DOMAIN dengan user '$USER' gagal (Respon: $AUTH_CODE)."
        return
    fi

    pass_check 30
}

# 1. SOAL 1: FINANCE
check_challenge_item "1" "finance.smk.lan" "/root/ca-finance" "/etc/apache2/.htpasswd-finance" "bendahara" "Finance2026!"

# 2. SOAL 2: HRD
check_challenge_item "2" "hrd.smk.lan" "/root/ca-hrd" "/etc/apache2/.htpasswd-hrd" "staff_hrd" "HRD2026!"

# 3. SOAL 3: ALUMNI
check_challenge_item "3" "alumni.smk.lan" "/root/ca-alumni" "/etc/apache2/.htpasswd-alumni" "tim_alumni" "Alumni2026!"

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
  "chapter_id": "lab-apache-multi-ch62",
  "score": $score,
  "status": "$status"
}
EOF
