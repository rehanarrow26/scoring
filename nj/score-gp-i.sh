#!/bin/bash
# ================================================================
# SCORING SCRIPT - CHAPTER 27: DEPLOY NODE.JS APP + EXPRESS + MYSQL
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
echo "  GRADER: CHAPTER 27 (NODE.JS + EXPRESS + MYSQL) "
echo "================================================="
echo

# 1. Cek Node.js & NPM Installed (10 Poin)
echo -n "Checking Node.js & NPM Installation (10 pts).........."
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    pass_check 10
else
    fail_check "Node.js atau NPM belum terinstall pada sistem."
fi

# 2. Cek Direktori Repo & Node Modules (15 Poin)
echo -n "Checking Repo Path & npm dependencies (15 pts)........"
if [ -d "/var/www/crud-nodejs-mysql" ] && [ -d "/var/www/crud-nodejs-mysql/node_modules" ]; then
    pass_check 15
else
    fail_check "Direktori '/var/www/crud-nodejs-mysql' atau 'node_modules' tidak ditemukan."
fi

# 3. Cek Database Existence (15 Poin)
echo -n "Checking Database 'customersdb' (15 pts)................"
if mysql -u root -e "USE customersdb;" >/dev/null 2>&1 || [ -d "/var/lib/mysql/customersdb" ]; then
    pass_check 15
else
    fail_check "Database 'customersdb' belum dibuat/di-import."
fi

# 4. Cek User DB Autentikasi & Akses (15 Poin)
echo -n "Checking DB User 'user_nodeapp' & Access (15 pts)......"
if mysql -u user_nodeapp -p'NodeApp2026!' -e "USE customersdb;" >/dev/null 2>&1 || \
   mysql -h 127.0.0.1 -u user_nodeapp -p'NodeApp2026!' -e "USE customersdb;" >/dev/null 2>&1; then
    pass_check 15
else
    fail_check "User DB 'user_nodeapp' gagal login dengan password 'NodeApp2026!' atau tidak punya akses ke 'customersdb'."
fi

# 5. Cek Konfigurasi File src/db.js (15 Poin)
echo -n "Checking Database Config in src/db.js (15 pts)........."
DB_FILE="/var/www/crud-nodejs-mysql/src/db.js"
if [ -f "$DB_FILE" ] && grep -q "user_nodeapp" "$DB_FILE" && grep -q "NodeApp2026!" "$DB_FILE" && grep -q "customersdb" "$DB_FILE"; then
    pass_check 15
else
    fail_check "Berkas 'src/db.js' belum dikonfigurasi dengan user, password, dan database yang sesuai."
fi

# 6. Cek PM2 Process Status 'node_app' (15 Poin)
echo -n "Checking PM2 App 'node_app' Running Status (15 pts)...."
if command -v pm2 >/dev/null 2>&1; then
    PM2_STATUS=$(pm2 jlist 2>/dev/null | grep -o '"name":"node_app"' || echo "")
    PM2_ONLINE=$(pm2 jlist 2>/dev/null | grep -o '"status":"online"' || echo "")
    if [ -n "$PM2_STATUS" ] && [ -n "$PM2_ONLINE" ]; then
        pass_check 15
    else
        fail_check "Proses PM2 dengan nama 'node_app' tidak ditemukan atau tidak bernilai 'online'."
    fi
else
    fail_check "PM2 tidak terpasang di sistem."
fi

# 7. Cek Response Endpoint Port 3000 (15 Poin)
echo -n "Checking App HTTP Endpoint on Port 3000 (15 pts)......."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 301 ] || [ "$HTTP_CODE" -eq 302 ]; then
    pass_check 15
else
    fail_check "Aplikasi di port 3000 tidak merespon (HTTP status code: $HTTP_CODE)."
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
  "chapter_id": "chapter-27-deploy-nodejs-app-express-mysql",
  "score": $score,
  "status": "$status"
}
EOF
