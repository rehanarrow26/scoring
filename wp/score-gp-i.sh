#!/bin/bash
# ================================================================
# WORDPRESS DEPLOYMENT CHECKER WITH ERROR DETAILS
# CHAPTER 20
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

echo "========================================="
echo "     WORDPRESS CHECKER - CH 20"
echo "========================================="
echo

# 1. Cek Keberadaan Database db_wordpress (15 Poin)
echo -n "Checking Database 'db_wordpress'..................."
if mysql -e "USE db_wordpress;" 2>/dev/null; then
    pass_check 15
else
    fail_check "Database 'db_wordpress' tidak ditemukan di MariaDB/MySQL."
fi

# 2. Cek User DB user_wp (15 Poin)
echo -n "Checking MySQL User 'user_wp'@'localhost'.........."
if mysql -u user_wp -p'WordPress2026!' -e "USE db_wordpress;" 2>/dev/null; then
    pass_check 15
else
    fail_check "User 'user_wp' tidak bisa login dengan password 'WordPress2026!' atau tidak punya akses ke 'db_wordpress'."
fi

# 3. Cek Direktori Installation & Hak Akses (20 Poin)
echo -n "Checking WordPress Directory & Ownership............"
if [ ! -d "/var/www/wordpress" ]; then
    fail_check "Direktori '/var/www/wordpress' belum dibuat/diekstrak."
elif [ ! -f "/var/www/wordpress/wp-config.php" ]; then
    fail_check "File '/var/www/wordpress/wp-config.php' belum ada."
else
    owner=$(stat -c '%U:%G' /var/www/wordpress)
    if [ "$owner" != "www-data:www-data" ]; then
        fail_check "Kepemilikan folder masih '$owner', seharusnya 'www-data:www-data'."
    else
        pass_check 20
    fi
fi

# 4. Cek Vhost Configuration (20 Poin)
echo -n "Checking Apache VirtualHost Configuration..........."
if [ ! -f "/etc/apache2/sites-available/wordpress.conf" ]; then
    fail_check "File vhost '/etc/apache2/sites-available/wordpress.conf' tidak ditemukan."
elif [ ! -f "/etc/apache2/sites-enabled/wordpress.conf" ]; then
    fail_check "Situs 'wordpress.conf' belum diaktifkan (jalankan: a2ensite wordpress.conf)."
elif ! grep -q "wordpress.smk.lan" /etc/apache2/sites-available/wordpress.conf; then
    fail_check "ServerName 'wordpress.smk.lan' belum dikonfigurasi di dalam vhost."
else
    pass_check 20
fi

# 5. Cek Response HTTP Domain wordpress.smk.lan (30 Poin)
echo -n "Checking HTTP Response (http://wordpress.smk.lan).."
code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: wordpress.smk.lan" http://127.0.0.1/)
if [ "$code" -eq 200 ] || [ "$code" -eq 301 ] || [ "$code" -eq 302 ]; then
    pass_check 30
else
    fail_check "HTTP Request mengembalikan status code '$code' (diharapkan 200/301/302). Periksa service Apache atau mapping domain."
fi

# Limit Score Max 100
[ "$score" -gt 100 ] && score=100

echo
echo "========================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Score: $score/100\e[0m"
    status="FAIL"
fi
echo "========================================="

cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": 20,
  "score": $score,
  "status": "$status"
}
EOF
