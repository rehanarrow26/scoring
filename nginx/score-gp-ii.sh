#!/bin/bash
# ================================================================
# SCORING SCRIPT: NGINX MULTI SERVER BLOCK (CHAPTER 17 / LAB 33)
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
echo "  GRADER: NGINX MULTI SERVER BLOCK (LAB 33)      "
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK DIREKTORI WEB & INDEX.HTML (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Web Directories & index.html Files (20 pts)..."
DIR_SEKOLAH="/var/www/html/sekolah.lan/index.html"
DIR_PERPUS="/var/www/html/perpustakaan.lan/index.html"

if [ -f "$DIR_SEKOLAH" ] && [ -f "$DIR_PERPUS" ]; then
    pass_check 20
else
    fail_check "Berkas index.html pada '/var/www/html/sekolah.lan/' atau '/var/www/html/perpustakaan.lan/' belum dibuat."
fi

# ------------------------------------------------------------------
# 2. CEK BERKAS SITES-AVAILABLE (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Sites-Available Configurations (20 pts)..."
CONF_SEKOLAH="/etc/nginx/sites-available/sekolah.lan.conf"
CONF_PERPUS="/etc/nginx/sites-available/perpustakaan.lan.conf"

if [ -f "$CONF_SEKOLAH" ] && [ -f "$CONF_PERPUS" ]; then
    # Verifikasi sederhana isi server_name
    SN_SEKOLAH=$(grep -iE "^\s*server_name\s+.*sekolah\.lan" "$CONF_SEKOLAH" 2>/dev/null)
    SN_PERPUS=$(grep -iE "^\s*server_name\s+.*perpustakaan\.lan" "$CONF_PERPUS" 2>/dev/null)

    if [ -n "$SN_SEKOLAH" ] && [ -n "$SN_PERPUS" ]; then
        pass_check 20
    else
        fail_check "Berkas konfigurasi ada, namun direktif 'server_name' belum dikonfigurasi dengan benar."
    fi
else
    fail_check "Berkas '$CONF_SEKOLAH' atau '$CONF_PERPUS' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 3. CEK SYMBOLIC LINK SITES-ENABLED (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Symlinks in Sites-Enabled (20 pts)......."
LINK_SEKOLAH="/etc/nginx/sites-enabled/sekolah.lan.conf"
LINK_PERPUS="/etc/nginx/sites-enabled/perpustakaan.lan.conf"

if [ -L "$LINK_SEKOLAH" ] && [ -L "$LINK_PERPUS" ]; then
    pass_check 20
else
    fail_check "Symbolic link di '/etc/nginx/sites-enabled/' belum dibuat untuk salah satu atau kedua domain."
fi

# ------------------------------------------------------------------
# 4. CEK SINTAKS NGINX & SERVICE STATUS (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Testing Nginx Syntax & Service Health (20 pts)....."
if nginx -t >/dev/null 2>&1 && systemctl is-active --quiet nginx; then
    pass_check 20
else
    fail_check "Sintaks konfigurasi Nginx error atau layanan Nginx tidak aktif."
fi

# ------------------------------------------------------------------
# 5. CEK HTTP RESPONSE PER DOMAIN (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Testing HTTP Domain Responses (20 pts)............."
# Menguji respon domain melalui curl
RESP_SEKOLAH=$(curl -s -H "Host: sekolah.lan" http://127.0.0.1/ 2>/dev/null)
RESP_PERPUS=$(curl -s -H "Host: perpustakaan.lan" http://127.0.0.1/ 2>/dev/null)

if echo "$RESP_SEKOLAH" | grep -qi "sekolah" && echo "$RESP_PERPUS" | grep -qi "perpustakaan"; then
    pass_check 20
else
    fail_check "Akses HTTP ke domain 'sekolah.lan' atau 'perpustakaan.lan' tidak mengembalikan konten yang sesuai."
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
  "chapter_id": "lab-33-nginx-multi-server-block",
  "score": $score,
  "status": "$status"
}
EOF
