#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 61 (NGINX BASIC AUTHENTICATION)
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
echo "  GRADER: LAB 61 (NGINX BASIC AUTHENTICATION)"
echo "================================================="
echo

# 1. CEK KETERSEDIAAN BERKAS .HTPASSWD DAN USER ADMIN & OPERATOR (25 POIN)
echo -n "Step 1: Memeriksa berkas /etc/nginx/.htpasswd dan user (admin & operator) (25 pts)..."
HTPASSWD_FILE="/etc/nginx/.htpasswd"

if [ -f "$HTPASSWD_FILE" ]; then
    HAS_ADMIN=$(grep -E "^admin:" "$HTPASSWD_FILE" || echo "")
    HAS_OPERATOR=$(grep -E "^operator:" "$HTPASSWD_FILE" || echo "")

    if [ -n "$HAS_ADMIN" ] && [ -n "$HAS_OPERATOR" ]; then
        pass_check 25
    else
        fail_check "Berkas $HTPASSWD_FILE harus memuat akun 'admin' dan 'operator'."
    fi
else
    fail_check "Berkas $HTPASSWD_FILE tidak ditemukan."
fi

# 2. CEK KONFIGURASI BASIC AUTH DI SERVER BLOCK NGINX (25 POIN)
echo -n "Step 2: Memeriksa konfigurasi auth_basic pada Server Block Nginx (25 pts)..."
NGINX_CONF="/etc/nginx/sites-available/secure-nginx.smk.lan.conf"

if [ -f "$NGINX_CONF" ]; then
    HAS_AUTH_BASIC=$(grep -Ei "auth_basic\s+.*" "$NGINX_CONF" || echo "")
    HAS_AUTH_FILE=$(grep -Ei "auth_basic_user_file\s+/etc/nginx/\.htpasswd" "$NGINX_CONF" || echo "")

    if [ -n "$HAS_AUTH_BASIC" ] && [ -n "$HAS_AUTH_FILE" ]; then
        pass_check 25
    else
        fail_check "Konfigurasi Nginx belum memuat auth_basic atau auth_basic_user_file yang tepat."
    fi
else
    fail_check "Berkas $NGINX_CONF tidak ditemukan."
fi

# 3. CEK PROTEKSI UNPROTECTED ACCESS / HTTP 401 (25 POIN)
echo -n "Step 3: Memeriksa penolakan akses tanpa kredensial (HTTP 401) (25 pts)..."
UNAUTH_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Host: secure-nginx.smk.lan" https://127.0.0.1/ || echo "000")

if [ "$UNAUTH_CODE" -eq 401 ]; then
    pass_check 25
else
    fail_check "Akses tanpa kredensial tidak ditolak dengan HTTP 401 (Mendapatkan HTTP Code: $UNAUTH_CODE)."
fi

# 4. CEK AKSES DENGAN KREDENSIAL VALID / HTTP 200 (25 POIN)
echo -n "Step 4: Memeriksa verifikasi login dengan kredensial valid (HTTP 200) (25 pts)..."
# Mencoba autentikasi menggunakan user admin atau operator
AUTH_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Host: secure-nginx.smk.lan" -u admin:admin123 https://127.0.0.1/ || echo "000")

if [ "$AUTH_CODE" -ne 200 ]; then
    AUTH_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Host: secure-nginx.smk.lan" -u operator:operator123 https://127.0.0.1/ || echo "000")
fi

if [ "$AUTH_CODE" -eq 200 ]; then
    pass_check 25
else
    fail_check "Login menggunakan kredensial .htpasswd gagal (Mendapatkan HTTP Code: $AUTH_CODE)."
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
  "chapter_id": "lab-nginx-auth-ch61",
  "score": $score,
  "status": "$status"
}
EOF
