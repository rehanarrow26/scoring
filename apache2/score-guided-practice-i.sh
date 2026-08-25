#!/bin/bash
# ================================================================
# WEB SERVER APACHE2 & GIT DEPLOYMENT CHECKER
# CHAPTER 15
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
echo "   APACHE2 WEB SERVER CHECKER - CH 15"
echo "========================================="
echo

# 1. Cek Instalasi Apache2 (15 Poin)
echo -n "Checking Apache2 Installation............"
if dpkg -s apache2 >/dev/null 2>&1; then
    pass_check 15
else
    fail_check
fi

# 2. Cek Service Apache2 Active (15 Poin)
echo -n "Checking Apache2 Service Active.........."
if systemctl is-active --quiet apache2; then
    pass_check 15
else
    fail_check
fi

# 3. Cek Git Repository Cloned (20 Poin)
echo -n "Checking Git Repository (.git folder)...."
if [ -d "/var/www/html/Portifolio-Projetos/.git" ]; then
    pass_check 20
else
    fail_check
fi

# 4. Cek Configuration DocumentRoot (20 Poin)
echo -n "Checking 000-default.conf DocumentRoot..."
if grep -Eq "DocumentRoot\s+/var/www/html/Portifolio-Projetos" /etc/apache2/sites-available/000-default.conf 2>/dev/null; then
    pass_check 20
else
    fail_check
fi

# 5. Cek Syntax Apache2 (15 Poin)
echo -n "Checking Apache2 Config Syntax..........."
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    pass_check 15
else
    fail_check
fi

# 6. Uji Akses HTTP Web Server (15 Poin)
echo -n "Checking HTTP Response (Localhost)......."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1/")
if [ "$HTTP_STATUS" -eq 200 ]; then
    pass_check 15
else
    fail_check
fi

# Limit Score Max 100
[ "$score" -gt 100 ] && score=100

# Simpan ke JSON
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": 15,
  "score": $score,
  "status": "$([ $score -eq 100 ] && echo "PASS" || echo "FAIL")"
}
EOF

echo
echo "========================================="
echo "Score : $score / 100"
echo "========================================="

if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE\e[0m"
else
    echo -e "\e[31mMISSION INCOMPLETE\e[0m"
fi
echo
