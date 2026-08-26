#!/bin/bash
# ================================================================
# MYSQL / MARIADB & PHPMYADMIN CHECKER
# CHAPTER 18
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
echo "   MYSQL & PHPMYADMIN CHECKER - CH 18"
echo "========================================="
echo

# 1. Cek Instalasi & Service MariaDB (15 Poin)
echo -n "Checking MariaDB Service status..................."
if systemctl is-active --quiet mariadb; then
    pass_check 15
else
    fail_check
fi

# 2. Cek Keberadaan Database db_sekolah (20 Poin)
echo -n "Checking Database 'db_sekolah'...................."
if mysql -e "USE db_sekolah;" 2>/dev/null; then
    pass_check 20
else
    fail_check
fi

# 3. Cek User Lokal admin_lokal@localhost (15 Poin)
echo -n "Checking MySQL User 'admin_lokal'@'localhost'....."
if mysql -e "SELECT User, Host FROM mysql.user;" 2>/dev/null | grep -q "admin_lokal.*localhost"; then
    pass_check 15
else
    fail_check
fi

# 4. Cek User Wildcard admin_remote@% (15 Poin)
echo -n "Checking MySQL User 'admin_remote'@'%'............"
if mysql -e "SELECT User, Host FROM mysql.user;" 2>/dev/null | grep -q "admin_remote.*%"; then
    pass_check 15
else
    fail_check
fi

# 5. Cek File Backup SQL (15 Poin)
echo -n "Checking Backup SQL file (/tmp/backup_sekolah.sql)..."
if [ -f "/tmp/backup_sekolah.sql" ] && [ -s "/tmp/backup_sekolah.sql" ]; then
    pass_check 15
else
    fail_check
fi

# 6. Cek Instalasi & Response HTTP phpMyAdmin (20 Poin)
echo -n "Checking phpMyAdmin Web Endpoint (/phpmyadmin)...."
code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/phpmyadmin/)
if [ "$code" -eq 200 ] || [ "$code" -eq 302 ]; then
    pass_check 20
else
    fail_check
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
  "chapter_id": 18,
  "score": $score,
  "status": "$status"
}
EOF
