#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 65 (USER FTP DAN MULTIPLE DEFAULTROOT)
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
echo "  GRADER: LAB 65 (USER FTP & MULTIPLE DEFAULTROOT)"
echo "================================================="
echo

# 1. CEK USER DAN GROUP (25 Pts)
echo -n "Step 1: Memeriksa User (webadmin, webdev1, webdev2) & Group (webdev) (25 pts)..."
if id "webadmin" &>/dev/null && id "webdev1" &>/dev/null && id "webdev2" &>/dev/null; then
    if getent group webdev | grep -qE "\bwebdev1\b" && getent group webdev | grep -qE "\bwebdev2\b"; then
        pass_check 25
    else
        fail_check "User webdev1 atau webdev2 belum dimasukkan ke dalam group 'webdev'."
    fi
else
    fail_check "Salah satu atau seluruh user (webadmin, webdev1, webdev2) belum dibuat."
fi

# 2. CEK DIREKTORI DAN HAK AKSES (25 Pts)
echo -n "Step 2: Memeriksa Direktori /var/www/html/blog & app Beserta Ownership (25 pts)..."
BLOG_DIR="/var/www/html/blog"
APP_DIR="/var/www/html/app"

if [ -d "$BLOG_DIR" ] && [ -d "$APP_DIR" ]; then
    BLOG_OWNER=$(stat -c "%U:%G" "$BLOG_DIR")
    APP_GROUP=$(stat -c "%G" "$APP_DIR")

    if [ "$BLOG_OWNER" = "webadmin:webadmin" ] && [ "$APP_GROUP" = "webdev" ]; then
        pass_check 25
    else
        fail_check "Ownership direktori tidak sesuai. /blog harus 'webadmin:webadmin' (saat ini: $BLOG_OWNER), /app group harus 'webdev' (saat ini group: $APP_GROUP)."
    fi
else
    fail_check "Direktori /var/www/html/blog atau /var/www/html/app tidak ditemukan."
fi

# 3. CEK KONFIGURASI DEFAULTROOT PROFTPD (30 Pts)
echo -n "Step 3: Memeriksa Konfigurasi Multiple DefaultRoot di proftpd.conf (30 pts)..."
CONF_FILE="/etc/proftpd/proftpd.conf"

if [ -f "$CONF_FILE" ]; then
    # Pastikan DefaultRoot global (~ atau /) disatukan atau di-comment agar tidak menimpa per-user
    ROOT_GLOBAL_ACTIVE=$(grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -E '^[[:space:]]*DefaultRoot[[:space:]]+~' >/dev/null && echo "yes" || echo "no")
    
    # Cek DefaultRoot khusus
    BLOG_CONF=$(grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -E '^[[:space:]]*DefaultRoot[[:space:]]+/var/www/html/blog[[:space:]]+webadmin' >/dev/null && echo "yes" || echo "no")
    APP_CONF=$(grep -v '^[[:space:]]*#' "$CONF_FILE" | grep -E '^[[:space:]]*DefaultRoot[[:space:]]+/var/www/html/app[[:space:]]+webdev' >/dev/null && echo "yes" || echo "no")

    if [ "$ROOT_GLOBAL_ACTIVE" = "no" ] && [ "$BLOG_CONF" = "yes" ] && [ "$APP_CONF" = "yes" ]; then
        pass_check 30
    else
        REASON=""
        [ "$ROOT_GLOBAL_ACTIVE" = "yes" ] && REASON="'DefaultRoot ~' masih aktif (belum di-comment). "
        [ "$BLOG_CONF" = "no" ] && REASON="${REASON}Baris 'DefaultRoot /var/www/html/blog webadmin' tidak ditemukan. "
        [ "$APP_CONF" = "no" ] && REASON="${REASON}Baris 'DefaultRoot /var/www/html/app webdev' tidak ditemukan."
        fail_check "$REASON"
    fi
else
    fail_check "Berkas $CONF_FILE tidak ditemukan."
fi

# 4. CEK STATUS LAYANAN PROFTPD & APACHE2 (20 Pts)
echo -n "Step 4: Memeriksa Status Layanan ProFTPD & Apache2 (20 pts)..."
PROFTPD_ACT=$(systemctl is-active proftpd 2>/dev/null || service proftpd status 2>/dev/null | grep -q "running" && echo "active" || echo "inactive")
APACHE_ACT=$(systemctl is-active apache2 2>/dev/null || service apache2 status 2>/dev/null | grep -q "running" && echo "active" || echo "inactive")

if [ "$PROFTPD_ACT" = "active" ] && [ "$APACHE_ACT" = "active" ]; then
    pass_check 20
else
    fail_check "Layanan belum aktif (ProFTPD: $PROFTPD_ACT, Apache2: $APACHE_ACT)."
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
  "chapter_id": "lab-proftpd-multi-root-ch65",
  "score": $score,
  "status": "$status"
}
EOF
