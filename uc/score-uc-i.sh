#!/bin/bash
# ================================================================
# AUTOMATED GRADER: ALL-IN-ONE SERVER (server.lan)
# IP Target: 192.168.10.26 | Total Max Score: 100 Pts
# ================================================================

clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/result.json"

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
echo "  GRADER: ALL-IN-ONE SERVER (server.lan)"
echo "================================================="
echo

# ----------------------------------------------------------------
# SOAL 1: SSH SERVER (15 Pts)
# ----------------------------------------------------------------
echo -n "Soal 1: Memeriksa Konfigurasi SSH (Port 2026, Key, User admin-server) (15 pts)..."
SSH_USER_EXISTS=$(id "admin-server" &>/dev/null && echo "yes" || echo "no")
SSH_IN_SUDO=$(groups admin-server 2>/dev/null | grep -qw "sudo" && echo "yes" || echo "no")
SSH_KEY_DIR=$(test -f /home/admin-server/key/server-key && test -f /home/admin-server/key/server-key.pub && echo "yes" || echo "no")
SSH_PORT_CONFIGD=$(grep -qE '^[[:space:]]*Port[[:space:]]+2026' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null && echo "yes" || echo "no")
SSH_NOPASS=$(grep -qE '^[[:space:]]*PasswordAuthentication[[:space:]]+no' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null && echo "yes" || echo "no")

if [ "$SSH_USER_EXISTS" = "yes" ] && [ "$SSH_IN_SUDO" = "yes" ] && [ "$SSH_KEY_DIR" = "yes" ] && [ "$SSH_PORT_CONFIGD" = "yes" ] && [ "$SSH_NOPASS" = "yes" ]; then
    pass_check 15
else
    REASON=""
    [ "$SSH_USER_EXISTS" = "no" ] && REASON="User 'admin-server' belum ada. "
    [ "$SSH_IN_SUDO" = "no" ] && REASON="${REASON}User 'admin-server' bukan anggota grup sudo. "
    [ "$SSH_KEY_DIR" = "no" ] && REASON="${REASON}Pasangan key di /home/admin-server/key/ belum lengkap. "
    [ "$SSH_PORT_CONFIGD" = "no" ] && REASON="${REASON}Port SSH belum diubah ke 2026. "
    [ "$SSH_NOPASS" = "no" ] && REASON="${REASON}PasswordAuthentication belum dinonaktifkan."
    fail_check "$REASON"
fi

# ----------------------------------------------------------------
# SOAL 2: DNS SERVER (BIND9) (15 Pts)
# ----------------------------------------------------------------
echo -n "Soal 2: Memeriksa DNS Server & Record Domain (db.server & db.192.168.10) (15 pts)..."
DNS_PKG=$(dpkg -l | grep -qw bind9 && echo "yes" || echo "no")
FWD_ZONE=$(test -f /etc/bind/db.server && echo "yes" || echo "no")
REV_ZONE=$(test -f /etc/bind/db.192.168.10 && echo "yes" || echo "no")
DNS_RESOLVE_WEB=$(nslookup web.server.lan 127.0.0.1 2>/dev/null | grep -q "192.168.10.26" && echo "yes" || echo "no")
DNS_RESOLVE_PTR=$(nslookup 192.168.10.26 127.0.0.1 2>/dev/null | grep -q "server.lan" && echo "yes" || echo "no")

if [ "$DNS_PKG" = "yes" ] && [ "$FWD_ZONE" = "yes" ] && [ "$REV_ZONE" = "yes" ] && [ "$DNS_RESOLVE_WEB" = "yes" ] && [ "$DNS_RESOLVE_PTR" = "yes" ]; then
    pass_check 15
else
    REASON=""
    [ "$DNS_PKG" = "no" ] && REASON="Paket bind9 belum terinstal. "
    [ "$FWD_ZONE" = "no" ] && REASON="${REASON}Berkas /etc/bind/db.server tidak ditemukan. "
    [ "$REV_ZONE" = "no" ] && REASON="${REASON}Berkas /etc/bind/db.192.168.10 tidak ditemukan. "
    [ "$DNS_RESOLVE_WEB" = "no" ] && REASON="${REASON}Forward lookup domain gagal ter-resolve ke 192.168.10.26. "
    [ "$DNS_RESOLVE_PTR" = "no" ] && REASON="${REASON}Reverse lookup (PTR) IP gagal."
    fail_check "$REASON"
fi

# ----------------------------------------------------------------
# SOAL 3: MYSQL SERVER (MARIADB) (10 Pts)
# ----------------------------------------------------------------
echo -n "Soal 3: Memeriksa MariaDB, Database & User Privileges (10 pts)..."
MYSQL_CONN=$(mariadb -u root -p1234 -e "SHOW DATABASES;" 2>/dev/null | grep -q "nodejs_db" && echo "yes" || echo "no")
MYSQL_USER_SERVER=$(mariadb -u root -p1234 -e "SELECT User FROM mysql.user;" 2>/dev/null | grep -qw "server_user" && echo "yes" || echo "no")
MYSQL_USER_WP=$(mariadb -u root -p1234 -e "SELECT User FROM mysql.user;" 2>/dev/null | grep -qw "wp_user" && echo "yes" || echo "no")

if [ "$MYSQL_CONN" = "yes" ] && [ "$MYSQL_USER_SERVER" = "yes" ] && [ "$MYSQL_USER_WP" = "yes" ]; then
    pass_check 10
else
    REASON=""
    [ "$MYSQL_CONN" = "no" ] && REASON="Koneksi root MariaDB (password 1234) atau database nodejs_db/wp_db gagal/tidak ada. "
    [ "$MYSQL_USER_SERVER" = "no" ] && REASON="${REASON}User 'server_user' tidak ditemukan. "
    [ "$MYSQL_USER_WP" = "no" ] && REASON="${REASON}User 'wp_user' tidak ditemukan."
    fail_check "$REASON"
fi

# ----------------------------------------------------------------
# SOAL 4: NODE.JS & PM2 (15 Pts)
# ----------------------------------------------------------------
echo -n "Soal 4: Memeriksa Repository Node.js & Proses PM2 (nodejsapp) (15 pts)..."
NODE_REPO=$(test -d /var/www/html/crud-nodejs-mysql && echo "yes" || echo "no")
PM2_RUNNING=$(pm2 jlist 2>/dev/null | grep -qw "nodejsapp" && echo "yes" || echo "no")

if [ "$NODE_REPO" = "yes" ] && [ "$PM2_RUNNING" = "yes" ]; then
    pass_check 15
else
    REASON=""
    [ "$NODE_REPO" = "no" ] && REASON="Repository /var/www/html/crud-nodejs-mysql tidak ditemukan. "
    [ "$PM2_RUNNING" = "no" ] && REASON="${REASON}Proses PM2 dengan nama 'nodejsapp' tidak aktif/tidak berjalan."
    fail_check "$REASON"
fi

# ----------------------------------------------------------------
# SOAL 5: SERTIFIKAT SSL (15 Pts)
# ----------------------------------------------------------------
echo -n "Soal 5: Memeriksa Sertifikat Root CA, Domain, & Berkas .pem FTP (15 pts)..."
SSL_CA=$(test -f /home/admin-server/ca/ca_server.crt && echo "yes" || echo "no")
SSL_DOMAINS=$(test -f /etc/ssl/certs/nodejs.server.lan.crt && test -f /etc/ssl/certs/wp.server.lan.crt && echo "yes" || echo "no")
SSL_PEM=$(test -f /etc/ssl/private/ftp.server.lan.pem && echo "yes" || echo "no")

if [ "$SSL_CA" = "yes" ] && [ "$SSL_DOMAINS" = "yes" ] && [ "$SSL_PEM" = "yes" ]; then
    pass_check 15
else
    REASON=""
    [ "$SSL_CA" = "no" ] && REASON="Root CA ca_server.crt tidak ditemukan di /home/admin-server/ca/. "
    [ "$SSL_DOMAINS" = "no" ] && REASON="${REASON}Sertifikat domain .crt belum disalin ke /etc/ssl/certs/. "
    [ "$SSL_PEM" = "no" ] && REASON="${REASON}Berkas gabungan .pem untuk ftp.server.lan tidak ditemukan di /etc/ssl/private/."
    fail_check "$REASON"
fi

# ----------------------------------------------------------------
# SOAL 6: WEB SERVER (NGINX & WORDPRESS) (15 Pts)
# ----------------------------------------------------------------
echo -n "Soal 6: Memeriksa Server Block Nginx & WordPress Document Root (15 pts)..."
NGINX_WP=$(test -f /etc/nginx/sites-enabled/wp.server.lan.conf && test -d /var/www/html/wp && echo "yes" || echo "no")
NGINX_NODE=$(test -f /etc/nginx/sites-enabled/nodejs.server.lan.conf && echo "yes" || echo "no")
NGINX_TEST=$(nginx -t 2>/dev/null && echo "yes" || echo "no")

if [ "$NGINX_WP" = "yes" ] && [ "$NGINX_NODE" = "yes" ] && [ "$NGINX_TEST" = "yes" ]; then
    pass_check 15
else
    REASON=""
    [ "$NGINX_WP" = "no" ] && REASON="Server block wp.server.lan.conf atau folder /var/www/html/wp belum siap. "
    [ "$NGINX_NODE" = "no" ] && REASON="${REASON}Server block nodejs.server.lan.conf belum aktif. "
    [ "$NGINX_TEST" = "no" ] && REASON="${REASON}Uji sintaks nginx (nginx -t) gagal."
    fail_check "$REASON"
fi

# ----------------------------------------------------------------
# SOAL 7: FTP SERVER (PROFTPD) (10 Pts)
# ----------------------------------------------------------------
echo -n "Soal 7: Memeriksa ProFTPD, User (wp_admin, nodejs_admin), & TLS (10 pts)..."
FTP_ACTIVE=$(systemctl is-active --quiet proftpd 2>/dev/null && echo "yes" || echo "no")
FTP_USERS=$(id "wp_admin" &>/dev/null && id "nodejs_admin" &>/dev/null && echo "yes" || echo "no")
FTP_TLS=$(grep -qi "TLSEngine" /etc/proftpd/tls.conf /etc/proftpd/proftpd.conf 2>/dev/null && echo "yes" || echo "no")

if [ "$FTP_ACTIVE" = "yes" ] && [ "$FTP_USERS" = "yes" ] && [ "$FTP_TLS" = "yes" ]; then
    pass_check 10
else
    REASON=""
    [ "$FTP_ACTIVE" = "no" ] && REASON="Layanan ProFTPD tidak aktif. "
    [ "$FTP_USERS" = "no" ] && REASON="${REASON}User wp_admin atau nodejs_admin belum dibuat. "
    [ "$FTP_TLS" = "no" ] && REASON="${REASON}Konfigurasi TLS/FTPS belum diaktifkan."
    fail_check "$REASON"
fi

# ----------------------------------------------------------------
# SOAL 8: FIREWALL (UFW) (5 Pts)
# ----------------------------------------------------------------
echo -n "Soal 8: Memeriksa Status UFW & Port Masuk Terbuka (5 pts)..."
UFW_STATUS=$(ufw status 2>/dev/null | grep -q "Status: active" && echo "yes" || echo "no")
UFW_PORTS=$(ufw status 2>/dev/null | grep -E "2026|53|80|443|21|49152" | wc -l)

if [ "$UFW_STATUS" = "yes" ] && [ "$UFW_PORTS" -ge 4 ]; then
    pass_check 5
else
    REASON=""
    [ "$UFW_STATUS" = "no" ] && REASON="UFW belum aktif. "
    [ "$UFW_PORTS" -lt 4 ] && REASON="${REASON}Aturan port UFW yang diperlukan belum lengkap."
    fail_check "$REASON"
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
  "chapter_id": "lab-all-in-one-server",
  "score": $score,
  "status": "$status"
}
EOF
