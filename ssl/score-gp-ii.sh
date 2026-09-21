#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 59 (APACHE2 BASIC AUTHENTICATION)
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
echo "  GRADER: LAB 59 (APACHE2 BASIC AUTHENTICATION)"
echo "================================================="
echo

# 1. CEK KETERSEDIAAN BERKAS .HTPASSWD DAN USER ADMIN & OPERATOR (25 POIN)
echo -n "Step 1: Memeriksa berkas /etc/apache2/.htpasswd dan user (admin & operator) (25 pts)..."
HTPASSWD_FILE="/etc/apache2/.htpasswd"

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

# 2. CEK KONFIGURASI BASIC AUTH DI DEFAULT-SSL.CONF (25 POIN)
echo -n "Step 2: Memeriksa konfigurasi Basic Auth pada default-ssl.conf (25 pts)..."
VHOST_CONF="/etc/apache2/sites-available/default-ssl.conf"

if [ -f "$VHOST_CONF" ]; then
    HAS_AUTHTYPE=$(grep -Ei "AuthType\s+Basic" "$VHOST_CONF" || echo "")
    HAS_AUTHFILE=$(grep -Ei "AuthUserFile\s+/etc/apache2/\.htpasswd" "$VHOST_CONF" || echo "")
    HAS_REQUIRE=$(grep -Ei "Require\s+valid-user" "$VHOST_CONF" || echo "")

    if [ -n "$HAS_AUTHTYPE" ] && [ -n "$HAS_AUTHFILE" ] && [ -n "$HAS_REQUIRE" ]; then
        pass_check 25
    else
        fail_check "Konfigurasi default-ssl.conf belum memuat AuthType Basic, AuthUserFile, atau Require valid-user."
    fi
else
    fail_check "Berkas $VHOST_CONF tidak ditemukan."
fi

# 3. CEK PROTEKSI UNPROTECTED ACCESS / HTTP 401 (25 POIN)
echo -n "Step 3: Memeriksa penolakan akses tanpa kredensial (HTTP 401) (25 pts)..."
UNAUTH_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://127.0.0.1/ || echo "000")

if [ "$UNAUTH_CODE" -eq 401 ]; then
    pass_check 25
else
    fail_check "Akses tanpa kredensial tidak ditolak dengan HTTP 401 (Mendapatkan HTTP Code: $UNAUTH_CODE)."
fi

# 4. CEK AKSES DENGAN KREDENSIAL VALID / HTTP 200 (25 POIN)
echo -n "Step 4: Memeriksa verifikasi login dengan kredensial valid (HTTP 200) (25 pts)..."
# Mencoba autentikasi menggunakan user admin atau operator
AUTH_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -u admin:admin123 https://127.0.0.1/ || echo "000")

if [ "$AUTH_CODE" -ne 200 ]; then
    AUTH_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -u operator:operator123 https://127.0.0.1/ || echo "000")
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
  "chapter_id": "lab-apache-auth-ch59",
  "score": $score,
  "status": "$status"
}
EOF
