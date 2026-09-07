#!/bin/bash
# ================================================================
# SCORING SCRIPT - CHAPTER 29: CHALLENGE DEPLOY NODE.JS + REVERSE PROXY
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
echo "  GRADER: CHAPTER 29 (CHALLENGE DEPLOYMENT)     "
echo "================================================="
echo

# 1. Cek Clone Repository di /var/www/html (10 Poin)
echo -n "1. Checking Git Repository Clone in /var/www/html (10 pts)..."
REPO_PATH="/var/www/html/crud-nodejs-mysql"
if [ -d "$REPO_PATH" ] && [ -d "$REPO_PATH/.git" ]; then
    pass_check 10
else
    fail_check "Repository belum di-clone ke lokasi '$REPO_PATH'."
fi

# 2. Cek User Database 'ch-i-db' & Akses Password 'Challenge123!' (10 Poin)
echo -n "2. Checking MySQL User 'ch-i-db' Authentication (10 pts)..."
if mysql -u ch-i-db -p'Challenge123!' -e "SHOW DATABASES;" >/dev/null 2>&1 || \
   mysql -h 127.0.0.1 -u ch-i-db -p'Challenge123!' -e "SHOW DATABASES;" >/dev/null 2>&1; then
    pass_check 10
else
    fail_check "User 'ch-i-db' gagal diautentikasi dengan password 'Challenge123!'."
fi

# 3. Cek Penyesuaian Konfigurasi DB pada Source Code Aplikasi (10 Poin)
echo -n "3. Checking DB Config in Application Source Code (10 pts)..."
CONFIG_FOUND=0
if [ -d "$REPO_PATH" ]; then
    if grep -rq "ch-i-db" "$REPO_PATH/src/" 2>/dev/null || grep -rq "Challenge123!" "$REPO_PATH/src/" 2>/dev/null; then
        CONFIG_FOUND=1
    fi
fi

if [ "$CONFIG_FOUND" -eq 1 ]; then
    pass_check 10
else
    fail_check "Konfigurasi koneksi database di source code (folder src/) belum diperbarui dengan user 'ch-i-db'."
fi

# 4. Cek npm dependencies (node_modules) (10 Poin)
echo -n "4. Checking npm dependencies / node_modules (10 pts)......."
if [ -d "$REPO_PATH/node_modules" ]; then
    pass_check 10
else
    fail_check "Folder 'node_modules' tidak ditemukan. Jalankan 'npm install' di direktori aplikasi."
fi

# 5. Cek PM2 Process Status 'ch-ii-app' (10 Poin)
echo -n "5. Checking PM2 Process 'ch-ii-app' Running (10 pts)......."
if command -v pm2 >/dev/null 2>&1; then
    PM2_STATUS=$(pm2 jlist 2>/dev/null | grep -o '"name":"ch-ii-app"' || echo "")
    PM2_ONLINE=$(pm2 jlist 2>/dev/null | grep -o '"status":"online"' || echo "")
    if [ -n "$PM2_STATUS" ] && [ -n "$PM2_ONLINE" ]; then
        pass_check 10
    else
        fail_check "Proses PM2 dengan nama 'ch-ii-app' tidak ditemukan atau tidak berstatus 'online'."
    fi
else
    fail_check "PM2 tidak terinstal di sistem."
fi

# 6. Cek Port 5000 Direct HTTP Response (10 Poin)
echo -n "6. Checking Direct Access on Port 5000 (10 pts)............"
HTTP_5000=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5000/ 2>/dev/null || echo "000")
if [ "$HTTP_5000" -eq 200 ] || [ "$HTTP_5000" -eq 301 ] || [ "$HTTP_5000" -eq 302 ]; then
    pass_check 10
else
    fail_check "Aplikasi tidak merespon di port 5000 (HTTP status: $HTTP_5000)."
fi

# 7. Cek DNS Resolution 'challenge-app.smk.lan' via Bind9 (10 Poin)
echo -n "7. Checking DNS Record 'challenge-app.smk.lan' (10 pts)...."
DNS_CHECK=$(dig @127.0.0.1 challenge-app.smk.lan +short 2>/dev/null || nslookup challenge-app.smk.lan 127.0.0.1 2>/dev/null | grep "Address:" | tail -n 1 | awk '{print $2}')
if [ -n "$DNS_CHECK" ]; then
    pass_check 10
else
    fail_check "Subdomain 'challenge-app.smk.lan' gagal di-resolve oleh Bind9."
fi

# 8. Cek Modul Proxy Apache2 (10 Poin)
echo -n "8. Checking Apache2 Proxy Modules (10 pts)................."
if apache2ctl -M 2>/dev/null | grep -q "proxy_module" && apache2ctl -M 2>/dev/null | grep -q "proxy_http_module"; then
    pass_check 10
else
    fail_check "Modul 'proxy' atau 'proxy_http' belum aktif di Apache2."
fi

# 9. Cek Virtual Host Apache2 Reverse Proxy (10 Poin)
echo -n "9. Checking Apache2 VirtualHost Configuration (10 pts)....."
CONF_FILE="/etc/apache2/sites-available/challenge-app.smk.lan.conf"
ENABLED_LINK="/etc/apache2/sites-enabled/challenge-app.smk.lan.conf"

if { [ -f "$CONF_FILE" ] && [ -L "$ENABLED_LINK" ]; } || grep -rq "challenge-app.smk.lan" /etc/apache2/sites-enabled/ 2>/dev/null; then
    pass_check 10
else
    fail_check "VirtualHost untuk domain 'challenge-app.smk.lan' tidak terkonfigurasi atau belum di-aktifkan (a2ensite)."
fi

# 10. Cek HTTP Access via Domain Reverse Proxy (10 Poin)
echo -n "10. Checking Proxy Access http://challenge-app.smk.lan (10 pts)..."
HTTP_PROXY=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: challenge-app.smk.lan" http://127.0.0.1/ 2>/dev/null || echo "000")
if [ "$HTTP_PROXY" -eq 200 ] || [ "$HTTP_PROXY" -eq 301 ] || [ "$HTTP_PROXY" -eq 302 ]; then
    pass_check 10
else
    fail_check "Akses reverse proxy via http://challenge-app.smk.lan gagal (HTTP status: $HTTP_PROXY)."
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
  "chapter_id": "chapter-29-challenge-deploy-nodejs-proxy",
  "score": $score,
  "status": "$status"
}
EOF
