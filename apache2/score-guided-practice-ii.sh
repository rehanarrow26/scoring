#!/bin/bash
# ================================================================
# APACHE2 MULTI VIRTUAL HOST CHECKER + BIND9
# CHAPTER 16
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
    echo -e "\e[31m[FAIL]\e[0m"
}

echo "========================================="
echo "  APACHE2 & BIND9 CHECKER - CH 16"
echo "========================================="
echo

# 1. Cek Resolusi DNS sekolah.lan (10 Poin)
echo -n "Checking DNS A Record for sekolah.lan (192.168.10.10)..."
DNS_SEKOLAH=$(dig +short @127.0.0.1 sekolah.lan 2>/dev/null || nslookup sekolah.lan 127.0.0.1 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}')
if [ "$DNS_SEKOLAH" = "192.168.10.10" ]; then
    pass_check 10
else
    fail_check
fi

# 2. Cek Resolusi DNS perpustakaan.lan (10 Poin)
echo -n "Checking DNS A Record for perpustakaan.lan (192.168.10.10)..."
DNS_PERPUS=$(dig +short @127.0.0.1 perpustakaan.lan 2>/dev/null || nslookup perpustakaan.lan 127.0.0.1 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}')
if [ "$DNS_PERPUS" = "192.168.10.10" ]; then
    pass_check 10
else
    fail_check
fi

# 3. Cek Folder & File sekolah.lan (15 Poin)
echo -n "Checking /var/www/html/sekolah.lan/index.html..."
if [ -f "/var/www/html/sekolah.lan/index.html" ] && grep -q "ini adalah website sekolah.lan" /var/www/html/sekolah.lan/index.html; then
    pass_check 15
else
    fail_check
fi

# 4. Cek Folder & File perpustakaan.lan (15 Poin)
echo -n "Checking /var/www/html/perpustakaan.lan/index.html..."
if [ -f "/var/www/html/perpustakaan.lan/index.html" ] && grep -q "ini adalah website perpustakaan.lan" /var/www/html/perpustakaan.lan/index.html; then
    pass_check 15
else
    fail_check
fi

# 5. Cek Config sekolah.lan.conf (15 Poin)
echo -n "Checking sekolah.lan.conf VirtualHost.........."
if grep -Eq "ServerName\s+sekolah\.lan" /etc/apache2/sites-available/sekolah.lan.conf 2>/dev/null && \
   grep -Eq "DocumentRoot\s+/var/www/html/sekolah\.lan" /etc/apache2/sites-available/sekolah.lan.conf 2>/dev/null; then
    pass_check 15
else
    fail_check
fi

# 6. Cek Config perpustakaan.lan.conf (15 Poin)
echo -n "Checking perpustakaan.lan.conf VirtualHost....."
if grep -Eq "ServerName\s+perpustakaan\.lan" /etc/apache2/sites-available/perpustakaan.lan.conf 2>/dev/null && \
   grep -Eq "DocumentRoot\s+/var/www/html/perpustakaan\.lan" /etc/apache2/sites-available/perpustakaan.lan.conf 2>/dev/null; then
    pass_check 15
else
    fail_check
fi

# 7. Cek Symlink Enabled Sites (10 Poin)
echo -n "Checking Enabled Virtual Hosts (a2ensite)......"
if [ -L "/etc/apache2/sites-enabled/sekolah.lan.conf" ] && [ -L "/etc/apache2/sites-enabled/perpustakaan.lan.conf" ]; then
    pass_check 10
else
    fail_check
fi

# 8. Cek Syntax Apache2 (5 Poin)
echo -n "Checking Apache2 Config Syntax................."
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    pass_check 5
else
    fail_check
fi

# 9. Uji Response HTTP via Host Header (5 Poin)
echo -n "Checking HTTP Response (Host Header)............"
RESP_SEKOLAH=$(curl -s -H "Host: sekolah.lan" http://127.0.0.1/)
RESP_PERPUS=$(curl -s -H "Host: perpustakaan.lan" http://127.0.0.1/)

if echo "$RESP_SEKOLAH" | grep -q "ini adalah website sekolah.lan" && \
   echo "$RESP_PERPUS" | grep -q "ini adalah website perpustakaan.lan"; then
    pass_check 5
else
    fail_check
fi

# Limit Score Max 100
[ "$score" -gt 100 ] && score=100

# Simpan ke JSON
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": 16,
  "score": $score,
  "status": "$([ "$score" -eq 100 ] && echo "PASS" || echo "FAIL")"
}
EOF

echo
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE - Score $score/100\e[0m"
else
    echo -e "\e[31mMISSION INCOMPLETE - Score $score/100\e[0m"
fi
