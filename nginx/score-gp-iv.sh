#!/bin/bash
# ================================================================
# SCORING SCRIPT: DEPLOY LARAVEL APP ON NGINX (CHAPTER 38)
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
echo "  GRADER: DEPLOY LARAVEL APP ON NGINX (LAB 38)   "
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK DEPLOYMENT LARAVEL & COMPOSER VENDOR (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Laravel Codebase & Vendor Directory (20 pts)..."
APP_DIR="/var/www/laravel-app"
if [ -d "$APP_DIR/vendor" ] && [ -f "$APP_DIR/.env" ] && grep -q "APP_KEY=base64:" "$APP_DIR/.env"; then
    pass_check 20
else
    fail_check "Aplikasi Laravel belum di-clone, 'composer install' belum dijalankan, atau APP_KEY belum di-generate di .env."
fi

# ------------------------------------------------------------------
# 2. CEK DATABASE MARIADB & TABEL MIGRATED (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Database Connection & Migrations (20 pts)..."
if mysql -u user_laravel_app -p'LaravelApp2026!' -e "USE db_laravel_app; SHOW TABLES;" 2>/dev/null | grep -q "migrations"; then
    pass_check 20
else
    fail_check "Database 'db_laravel_app' tidak dapat diakses atau tabel belum di-migrate ('php artisan migrate')."
fi

# ------------------------------------------------------------------
# 3. CEK PERMISSIONS STORAGE & BOOTSTRAP CACHE (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Directory Permissions (www-data) (20 pts)..."
OWNER=$(stat -c '%U:%G' "$APP_DIR")
STORAGE_PERM=$(stat -c '%a' "$APP_DIR/storage")

if [ "$OWNER" = "www-data:www-data" ] && [ "$STORAGE_PERM" -ge 775 ]; then
    pass_check 20
else
    fail_check "Kepemilikan folder harus www-data:www-data dan izin direktori storage/ minimal 775."
fi

# ------------------------------------------------------------------
# 4. CEK KONFIGURASI SERVER BLOCK NGINX (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Nginx Server Block & Symlink (20 pts)..."
CONF="/etc/nginx/sites-available/products.smk.lan.conf"
LINK="/etc/nginx/sites-enabled/products.smk.lan.conf"

if [ -f "$CONF" ] && [ -L "$LINK" ]; then
    if grep -q "products.smk.lan" "$CONF" && grep -q "/var/www/laravel-app/public" "$CONF" && nginx -t >/dev/null 2>&1; then
        pass_check 20
    else
        fail_check "Sintaks Nginx error atau direktif root/server_name tidak mengarah ke public/."
    fi
else
    fail_check "Berkas konfigurasi di sites-available atau symlink di sites-enabled belum dibuat."
fi

# ------------------------------------------------------------------
# 5. CEK HTTP RESPONSE UNTUK DOMAIN PRODUCTS.SMK.LAN (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Testing HTTP Response (http://products.smk.lan/products) (20 pts)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: products.smk.lan" http://127.0.0.1/products 2>/dev/null || echo "000")

if [ "$HTTP_CODE" -eq 200 ]; then
    pass_check 20
else
    fail_check "Gagal mendapatkan respon HTTP 200 OK (Diterima HTTP $HTTP_CODE)."
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
  "chapter_id": "lab-38-deploy-laravel-nginx",
  "score": $score,
  "status": "$status"
}
EOF
