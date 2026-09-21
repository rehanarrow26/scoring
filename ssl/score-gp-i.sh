#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 58 (APACHE2 TLS/SSL SELF-SIGNED CERT)
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
echo "  GRADER: LAB 58 (APACHE2 TLS/SSL SELF-SIGNED)"
echo "================================================="
echo

# 1. CEK STATUS LAYANAN APACHE2 & NGINX (20 POIN)
echo -n "Step 1: Memeriksa status Apache2 (Active) dan Nginx (Inactive) (20 pts)..."
APACHE_ACTIVE=$(systemctl is-active apache2 2>/dev/null || echo "inactive")
NGINX_ACTIVE=$(systemctl is-active nginx 2>/dev/null || echo "inactive")

if [ "$APACHE_ACTIVE" = "active" ] && [ "$NGINX_ACTIVE" != "active" ]; then
    pass_check 20
else
    fail_check "Apache2 harus 'active' ($APACHE_ACTIVE) dan Nginx harus 'inactive' ($NGINX_ACTIVE)."
fi

# 2. CEK KONFIGURASI SSH ROOT LOGIN (10 POIN)
echo -n "Step 2: Memeriksa konfigurasi SSH PermitRootLogin (10 pts)..."
if grep -Ei "^\s*PermitRootLogin\s+yes" /etc/ssh/sshd_config >/dev/null 2>&1; then
    pass_check 10
else
    fail_check "PermitRootLogin yes tidak ditemukan pada /etc/ssh/sshd_config."
fi

# 3. CEK KETERSEDIAAN SERTIFIKAT & SAN EXTENSION (30 POIN)
echo -n "Step 3: Memeriksa berkas Sertifikat SSL dan SAN (Subject Alternative Name) (30 pts)..."
CRT_PATH="/etc/ssl/certs/secure.smk.lan.crt"
KEY_PATH="/etc/ssl/private/secure.smk.lan.key"

if [ -f "$CRT_PATH" ] && [ -f "$KEY_PATH" ]; then
    SAN_CHECK=$(openssl x509 -in "$CRT_PATH" -text -noout 2>/dev/null | grep -A1 "Subject Alternative Name" || echo "")
    if [[ "$SAN_CHECK" == *"secure.smk.lan"* ]]; then
        pass_check 30
    else
        fail_check "Sertifikat $CRT_PATH tidak memuat Subject Alternative Name (SAN) 'secure.smk.lan'."
    fi
else
    fail_check "Berkas sertifikat $CRT_PATH atau key $KEY_PATH tidak ditemukan."
fi

# 4. CEK KONFIGURASI VIRTUAL HOST SSL APACHE2 (20 POIN)
echo -n "Step 4: Memeriksa konfigurasi default-ssl.conf Apache2 (20 pts)..."
VHOST_CONF="/etc/apache2/sites-available/default-ssl.conf"

if [ -f "$VHOST_CONF" ]; then
    HAS_SERVERNAME=$(grep -Ei "^\s*ServerName\s+secure\.smk\.lan" "$VHOST_CONF" || echo "")
    HAS_CERT=$(grep -Ei "^\s*SSLCertificateFile\s+/etc/ssl/certs/secure\.smk\.lan\.crt" "$VHOST_CONF" || echo "")
    HAS_KEY=$(grep -Ei "^\s*SSLCertificateKeyFile\s+/etc/ssl/private/secure\.smk\.lan\.key" "$VHOST_CONF" || echo "")

    if [ -n "$HAS_SERVERNAME" ] && [ -n "$HAS_CERT" ] && [ -n "$HAS_KEY" ]; then
        pass_check 20
    else
        fail_check "Konfigurasi default-ssl.conf belum memuat ServerName, SSLCertificateFile, atau SSLCertificateKeyFile yang sesuai."
    fi
else
    fail_check "Berkas $VHOST_CONF tidak ditemukan."
fi

# 5. CEK RESPON KONEKSI HTTPS / SSL HANDSHAKE (20 POIN)
echo -n "Step 5: Memeriksa respon HTTPS port 443 pada Apache2 (20 pts)..."
SSL_RESP=$(curl -k -s -o /dev/null -w "%{http_code}" https://127.0.0.1/ || echo "000")

if [ "$SSL_RESP" -eq 200 ] || [ "$SSL_RESP" -eq 301 ] || [ "$SSL_RESP" -eq 302 ]; then
    pass_check 20
else
    fail_check "Koneksi HTTPS ke https://127.0.0.1/ gagal (HTTP Code: $SSL_RESP)."
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
  "chapter_id": "lab-apache-ssl-ch58",
  "score": $score,
  "status": "$status"
}
EOF
