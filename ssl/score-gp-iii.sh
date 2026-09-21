#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 60 (NGINX TLS/SSL SELF-SIGNED CERT)
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
echo "  GRADER: LAB 60 (NGINX TLS/SSL SELF-SIGNED)"
echo "================================================="
echo

# 1. CEK STATUS LAYANAN NGINX & APACHE2 (20 POIN)
echo -n "Step 1: Memeriksa status Nginx (Active) dan Apache2 (Inactive) (20 pts)..."
NGINX_ACTIVE=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
APACHE_ACTIVE=$(systemctl is-active apache2 2>/dev/null || echo "inactive")

if [ "$NGINX_ACTIVE" = "active" ] && [ "$APACHE_ACTIVE" != "active" ]; then
    pass_check 20
else
    fail_check "Nginx harus 'active' ($NGINX_ACTIVE) dan Apache2 harus 'inactive' ($APACHE_ACTIVE)."
fi

# 2. CEK KETERSEDIAAN SERTIFIKAT & SAN EXTENSION (25 POIN)
echo -n "Step 2: Memeriksa berkas Sertifikat SSL Nginx dan SAN (25 pts)..."
CRT_PATH="/etc/ssl/certs/secure-nginx.smk.lan.crt"
KEY_PATH="/etc/ssl/private/secure-nginx.smk.lan.key"

if [ -f "$CRT_PATH" ] && [ -f "$KEY_PATH" ]; then
    SAN_CHECK=$(openssl x509 -in "$CRT_PATH" -text -noout 2>/dev/null | grep -A1 "Subject Alternative Name" || echo "")
    if [[ "$SAN_CHECK" == *"secure-nginx.smk.lan"* ]]; then
        pass_check 25
    else
        fail_check "Sertifikat $CRT_PATH tidak memuat SAN 'secure-nginx.smk.lan'."
    fi
else
    fail_check "Berkas sertifikat $CRT_PATH atau key $KEY_PATH tidak ditemukan."
fi

# 3. CEK KONFIGURASI SERVER BLOCK NGINX (20 POIN)
echo -n "Step 3: Memeriksa Server Block Nginx secure-nginx.smk.lan.conf (20 pts)..."
VHOST_CONF="/etc/nginx/sites-available/secure-nginx.smk.lan.conf"
LINK_CONF="/etc/nginx/sites-enabled/secure-nginx.smk.lan.conf"

if [ -f "$VHOST_CONF" ] && [ -L "$LINK_CONF" ]; then
    HAS_SERVERNAME=$(grep -Ei "server_name\s+.*secure-nginx\.smk\.lan" "$VHOST_CONF" || echo "")
    HAS_CERT=$(grep -Ei "ssl_certificate\s+/etc/ssl/certs/secure-nginx\.smk\.lan\.crt" "$VHOST_CONF" || echo "")
    HAS_KEY=$(grep -Ei "ssl_certificate_key\s+/etc/ssl/private/secure-nginx\.smk\.lan\.key" "$VHOST_CONF" || echo "")

    if [ -n "$HAS_SERVERNAME" ] && [ -n "$HAS_CERT" ] && [ -n "$HAS_KEY" ]; then
        pass_check 20
    else
        fail_check "Konfigurasi Server Block belum memuat server_name, ssl_certificate, atau ssl_certificate_key yang tepat."
    fi
else
    fail_check "Berkas konfigurasi $VHOST_CONF atau symlink di sites-enabled tidak ditemukan."
fi

# 4. CEK HTTP TO HTTPS REDIRECT (15 POIN)
echo -n "Step 4: Memeriksa HTTP ke HTTPS Redirect (HTTP 301) (15 pts)..."
REDIRECT_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: secure-nginx.smk.lan" http://127.0.0.1/ || echo "000")

if [ "$REDIRECT_CODE" -eq 301 ]; then
    pass_check 15
else
    fail_check "HTTP ke HTTPS Redirect tidak merespons HTTP 301 (Mendapatkan HTTP Code: $REDIRECT_CODE)."
fi

# 5. CEK RESPON KONEKSI HTTPS / SSL HANDSHAKE NGINX (20 POIN)
echo -n "Step 5: Memeriksa respon HTTPS port 443 pada Nginx (20 pts)..."
SSL_RESP=$(curl -k -s -o /dev/null -w "%{http_code}" -H "Host: secure-nginx.smk.lan" https://127.0.0.1/ || echo "000")

if [ "$SSL_RESP" -eq 200 ] || [ "$SSL_RESP" -eq 301 ] || [ "$SSL_RESP" -eq 302 ]; then
    pass_check 20
else
    fail_check "Koneksi HTTPS Nginx ke https://127.0.0.1/ gagal (HTTP Code: $SSL_RESP)."
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
  "chapter_id": "lab-nginx-ssl-ch60",
  "score": $score,
  "status": "$status"
}
EOF
