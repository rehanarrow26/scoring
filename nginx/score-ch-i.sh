#!/bin/bash
# ================================================================
# SCORING SCRIPT: SUBDOMAIN MULTI SERVER BLOCK (CHAPTER 34)
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
echo "  GRADER: SUBDOMAIN MULTI SERVER BLOCK (LAB 34)  "
echo "================================================="
echo

SUBDOMAINS=(
    "shop.smk.lan"
    "portfolio1.smk.lan"
    "portfolio2.smk.lan"
    "cv.smk.lan"
    "streaming.smk.lan"
    "portfolio3.smk.lan"
    "food.smk.lan"
)

# ------------------------------------------------------------------
# 1. CEK STATUS APACHE2 (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Apache2 Service Disabled Status (20 pts)...."
if ! systemctl is-active --quiet apache2; then
    pass_check 20
else
    fail_check "Layanan Apache2 masih berjalan aktif. Hentikan dengan 'systemctl stop apache2'."
fi

# ------------------------------------------------------------------
# 2. CEK CLONED REPOSITORIES IN /var/www/nginx/ (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Cloned Web Repositories in /var/www/nginx/ (20 pts)..."
repo_ok=true
missing_repo=""

for sub in "${SUBDOMAINS[@]}"; do
    target="/var/www/nginx/$sub"
    if [ ! -d "$target" ] || [ ! -f "$target/index.html" ]; then
        repo_ok=false
        missing_repo="$sub"
        break
    fi
done

if [ "$repo_ok" = true ]; then
    pass_check 20
else
    fail_check "Direktori atau index.html untuk '$missing_repo' tidak ditemukan di '/var/www/nginx/'."
fi

# ------------------------------------------------------------------
# 3. CEK KONFIGURASI SITES-AVAILABLE (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Sites-Available Configurations (20 pts)..."
conf_ok=true
missing_conf=""

for sub in "${SUBDOMAINS[@]}"; do
    conf_file="/etc/nginx/sites-available/$sub.conf"
    if [ ! -f "$conf_file" ]; then
        conf_ok=false
        missing_conf="$sub.conf"
        break
    fi

    # Cek ketersediaan server_name dan root yang sesuai
    if ! grep -q -iE "server_name\s+.*$sub" "$conf_file" || ! grep -q -iE "root\s+/var/www/nginx/$sub" "$conf_file"; then
        conf_ok=false
        missing_conf="$sub.conf (server_name / root mismatch)"
        break
    fi
done

if [ "$conf_ok" = true ]; then
    pass_check 20
else
    fail_check "Konfigurasi tidak valid/ditemukan pada '/etc/nginx/sites-available/$missing_conf'."
fi

# ------------------------------------------------------------------
# 4. CEK SYMBOLIC LINK SITES-ENABLED & NGINX SYNTAX (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Symlinks & Nginx Syntax Test (20 pts)....."
link_ok=true
missing_link=""

for sub in "${SUBDOMAINS[@]}"; do
    link_file="/etc/nginx/sites-enabled/$sub.conf"
    if [ ! -L "$link_file" ]; then
        link_ok=false
        missing_link="$sub.conf"
        break
    fi
done

if [ "$link_ok" = true ] && nginx -t >/dev/null 2>&1 && systemctl is-active --quiet nginx; then
    pass_check 20
else
    if [ "$link_ok" = false ]; then
        fail_check "Symbolic link '/etc/nginx/sites-enabled/$missing_link' belum dibuat."
    else
        fail_check "Sintaks Nginx error (nginx -t) atau layanan Nginx mati."
    fi
fi

# ------------------------------------------------------------------
# 5. CEK HTTP ACCESS SEMUA SUBDOMAIN (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Testing HTTP Domain Responses (20 pts)............."
http_ok=true
failed_domain=""

for sub in "${SUBDOMAINS[@]}"; do
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $sub" http://127.0.0.1/ 2>/dev/null || echo "000")
    if [ "$code" -ne 200 ]; then
        http_ok=false
        failed_domain="$sub (HTTP $code)"
        break
    fi
done

if [ "$http_ok" = true ]; then
    pass_check 20
else
    fail_check "Gagal mendapatkan HTTP 200 OK untuk domain: $failed_domain."
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
  "chapter_id": "lab-34-nginx-subdomain-multi-server-block",
  "score": $score,
  "status": "$status"
}
EOF
