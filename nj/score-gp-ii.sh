#!/bin/bash
# ================================================================
# SCORING SCRIPT - CHAPTER 28: REVERSE PROXY APACHE2 FOR NODE.JS
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
    echo -e "   \e[33m└─> Alasan: $reason\e[0m"
}

echo "================================================="
echo "  GRADER: CHAPTER 28 (REVERSE PROXY APACHE2)    "
echo "================================================="
echo

# 1. Verifikasi DNS Resolution Bind9 untuk nodejs.smk.lan (20 Poin)
echo -n "1. Checking DNS Record nodejs.smk.lan in Bind9 (20 pts)..."
DNS_CHECK=$(dig @127.0.0.1 nodejs.smk.lan +short 2>/dev/null || nslookup nodejs.smk.lan 127.0.0.1 2>/dev/null | grep "Address:" | tail -n 1 | awk '{print $2}')

if [ -n "$DNS_CHECK" ]; then
    pass_check 20
else
    fail_check "Subdomain 'nodejs.smk.lan' tidak dapat di-resolve oleh Bind9 (A Record tidak ditemukan)."
fi

# 2. Verifikasi Modul Proxy Apache2 Active (15 Poin)
echo -n "2. Checking Apache2 Proxy Modules Status (15 pts)........"
if apache2ctl -M 2>/dev/null | grep -q "proxy_module" && apache2ctl -M 2>/dev/null | grep -q "proxy_http_module"; then
    pass_check 15
else
    fail_check "Modul 'proxy' atau 'proxy_http' belum diaktifkan di Apache2 (a2enmod proxy proxy_http)."
fi

# 3. Verifikasi File Vhost & Sites-Enabled (20 Poin)
echo -n "3. Checking VirtualHost nodejs.smk.lan Config (20 pts)..."
CONF_FILE="/etc/apache2/sites-available/nodejs.smk.lan.conf"
ENABLED_LINK="/etc/apache2/sites-enabled/nodejs.smk.lan.conf"

if [ -f "$CONF_FILE" ] && [ -L "$ENABLED_LINK" ]; then
    if grep -q "ServerName nodejs.smk.lan" "$CONF_FILE" && \
       grep -q "ProxyPass / http://localhost:3000/" "$CONF_FILE" && \
       grep -q "ProxyPassReverse / http://localhost:3000/" "$CONF_FILE"; then
        pass_check 20
    else
        fail_check "Konfigurasi ProxyPass, ProxyPassReverse, atau ServerName dalam '$CONF_FILE' tidak sesuai."
    fi
else
    fail_check "Berkas VirtualHost '$CONF_FILE' tidak ada atau belum diaktifkan (a2ensite)."
fi

# 4. Verifikasi Aplikasi Node.js Running di PM2 (15 Poin)
echo -n "4. Checking PM2 App 'node_app' Running (15 pts)........."
if command -v pm2 >/dev/null 2>&1; then
    PM2_STATUS=$(pm2 jlist 2>/dev/null | grep -o '"name":"node_app"' || echo "")
    PM2_ONLINE=$(pm2 jlist 2>/dev/null | grep -o '"status":"online"' || echo "")
    if [ -n "$PM2_STATUS" ] && [ -n "$PM2_ONLINE" ]; then
        pass_check 15
    else
        fail_check "Aplikasi Node.js 'node_app' di PM2 tidak berjalan/offline."
    fi
else
    fail_check "PM2 tidak terpasang di sistem."
fi

# 5. Verifikasi Response HTTP via Reverse Proxy Domain (30 Poin)
echo -n "5. Checking HTTP Access via http://nodejs.smk.lan (30 pts)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: nodejs.smk.lan" http://127.0.0.1/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 301 ] || [ "$HTTP_CODE" -eq 302 ]; then
    pass_check 30
else
    fail_check "Akses ke http://nodejs.smk.lan gagal (HTTP Status: $HTTP_CODE)."
fi

# Limit Score Max 100
[ "$score" -gt 100 ] && score=100

echo
echo "================================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Score: $score/100\e[0m"
    status="FAIL"
fi
echo "================================================="

cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "chapter-28-reverse-proxy-apache2",
  "score": $score,
  "status": "$status"
}
EOF
