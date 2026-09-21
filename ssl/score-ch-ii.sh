#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 63 (CHALLENGE MULTI-DOMAIN NGINX SSL & AUTH)
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
echo "  GRADER: LAB 63 (CHALLENGE MULTI-DOMAIN NGINX SSL)"
echo "================================================="
echo

# 0. PRASYARAT SERVER
echo -n "Step 0: Memeriksa status Nginx (Active) & Apache2 (Inactive) (10 pts)..."
NGINX_ACT=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
APACHE_ACT=$(systemctl is-active apache2 2>/dev/null || echo "inactive")

if [ "$NGINX_ACT" = "active" ] && [ "$APACHE_ACT" != "active" ]; then
    pass_check 10
else
    fail_check "Nginx harus 'active' ($NGINX_ACT) dan Apache2 harus 'inactive' ($APACHE_ACT)."
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

    # Check HTTP -> HTTPS Redirect
    REDIR_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" http://127.0.0.1/ || echo "000")
    if [ "$REDIR_CODE" -ne 301 ]; then
        fail_check "HTTP ke HTTPS Redirect untuk $DOMAIN tidak menghasilkan HTTP 301 (Respon: $REDIR_CODE)."
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

# 1. SOAL 1: PERPUS
check_challenge_item "1" "perpus.smk.lan" "/root/ca-perpus" "/etc/nginx/.htpasswd-perpus" "pustakawan" "Perpus2026!"

# 2. SOAL 2: KANTIN
check_challenge_item "2" "kantin.smk.lan" "/root/ca-kantin" "/etc/nginx/.htpasswd-kantin" "kasir" "Kantin2026!"

# 3. SOAL 3: BKK
check_challenge_item "3" "bkk.smk.lan" "/root/ca-bkk" "/etc/nginx/.htpasswd-bkk" "tim_bkk" "Bkk2026!"

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
  "chapter_id": "lab-nginx-multi-ch63",
  "score": $score,
  "status": "$status"
}
EOF
