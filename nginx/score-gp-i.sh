#!/bin/bash
# ================================================================
# SCORING SCRIPT: NGINX BASIC DEPLOYMENT 
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
echo "  GRADER: NGINX BASIC DEPLOYMENT (CHAPTER 16)    "
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK STATUS APACHE2 (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Apache2 Disabled Status (20 pts)..........."
if ! systemctl is-active --quiet apache2; then
    pass_check 20
else
    fail_check "Layanan Apache2 masih berjalan aktif. Hentikan dengan 'systemctl stop apache2'."
fi

# ------------------------------------------------------------------
# 2. CEK STATUS SERVICE NGINX (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Nginx Service Status (20 pts)............."
if systemctl is-active --quiet nginx; then
    pass_check 20
else
    fail_check "Layanan Nginx tidak aktif atau belum berjalan."
fi

# ------------------------------------------------------------------
# 3. CEK DIREKTORI REPOSITORY CLONE (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Cloned Web Repository (20 pts)............."
TARGET_DIR="/var/www/html/Portifolio-Projetos-Nginx"
if [ -d "$TARGET_DIR" ] && [ -f "$TARGET_DIR/index.html" ]; then
    pass_check 20
else
    fail_check "Direktori '$TARGET_DIR' atau berkas 'index.html' di dalamnya tidak ditemukan."
fi

# ------------------------------------------------------------------
# 4. CEK KONFIGURASI ROOT DIRECTORY NGINX (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Nginx Root Configuration (20 pts)........."
DEFAULT_CONF="/etc/nginx/sites-available/default"

# Memeriksa direktori root di file konfigurasi default
ROOT_CONFIG=$(grep -iE "^\s*root\s+/var/www/html/Portifolio-Projetos-Nginx;?" "$DEFAULT_CONF" 2>/dev/null || echo "")

if [ -n "$ROOT_CONFIG" ]; then
    pass_check 20
else
    fail_check "Konfigurasi 'root' pada '$DEFAULT_CONF' belum diubah ke '/var/www/html/Portifolio-Projetos-Nginx'."
fi

# ------------------------------------------------------------------
# 5. CEK HTTP RESPONSE / AKSES LOCALHOST PORT 80 (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Testing HTTP Web Access via Localhost (20 pts)......"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" -eq 200 ]; then
    pass_check 20
else
    fail_check "Web server memberikan respons HTTP $HTTP_CODE (diharapkan 200 OK)."
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
  "chapter_id": "chapter-16-nginx-basic-deployment",
  "score": $score,
  "status": "$status"
}
EOF
