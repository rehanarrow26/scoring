#!/bin/bash
# ================================================================
# SCORING SCRIPT: WORDPRESS ON NGINX + PHP-FPM (CHAPTER 35)
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
echo "  GRADER: DEPLOY WORDPRESS NGINX (LAB 35)        "
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK STATUS APACHE2 DISABLED (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Apache2 Service Stopped (20 pts)........."
if ! systemctl is-active --quiet apache2; then
    pass_check 20
else
    fail_check "Layanan Apache2 masih berjalan aktif. Hentikan dengan 'systemctl stop apache2'."
fi

# ------------------------------------------------------------------
# 2. CEK DATABASE & USER MARIADB (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking MariaDB Database & User Credentials (20 pts)..."
if mysql -u user_wp_nginx -p'WPNginx2026!' -e "USE db_wordpress_nginx;" >/dev/null 2>&1; then
    pass_check 20
else
    fail_check "Database 'db_wordpress_nginx' atau kredensial 'user_wp_nginx' tidak dapat diakses."
fi

# ------------------------------------------------------------------
# 3. CEK WORDPRESS INSTALLATION & PERMISSIONS (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking WordPress Files & Permissions (20 pts)..."
WP_DIR="/var/www/wordpress-nginx"
if [ -f "$WP_DIR/wp-config.php" ] && [ -f "$WP_DIR/index.php" ]; then
    OWNER=$(stat -c '%U:%G' "$WP_DIR")
    if [ "$OWNER" = "www-data:www-data" ]; then
        pass_check 20
    else
        fail_check "Kepemilikan direktori '$WP_DIR' bukan www-data:www-data (saat ini: $OWNER)."
    fi
else
    fail_check "Berkas wp-config.php atau index.php tidak ditemukan di '$WP_DIR'."
fi

# ------------------------------------------------------------------
# 4. CEK KONFIGURASI SERVER BLOCK & PHP-FPM (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Nginx Server Block & PHP-FPM Config (20 pts)..."
CONF="/etc/nginx/sites-available/wordpress-nginx.conf"
LINK="/etc/nginx/sites-enabled/wordpress-nginx.conf"

if [ -f "$CONF" ] && [ -L "$LINK" ]; then
    if grep -q "wordpress-nginx.smk.lan" "$CONF" && grep -q "fastcgi_pass" "$CONF" && nginx -t >/dev/null 2>&1; then
        pass_check 20
    else
        fail_check "Konfigurasi Nginx memuat kesalahan sintaks atau direktif fastcgi_pass/server_name tidak sesuai."
    fi
else
    fail_check "Berkas '$CONF' atau symbolic link di sites-enabled tidak ditemukan."
fi

# ------------------------------------------------------------------
# 5. CEK RESPONSE HTTP WORDPRESS (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Testing HTTP Response for wordpress-nginx.smk.lan (20 pts)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: wordpress-nginx.smk.lan" http://127.0.0.1/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 302 ]; then
    pass_check 20
else
    fail_check "Respon HTTP tidak valid (diterima HTTP $HTTP_CODE, mengharapkan 200 atau 302)."
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

# Simpan hasil penilaian JSON untuk LMS
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-35-deploy-wordpress-nginx",
  "score": $score,
  "status": "$status"
}
EOF
