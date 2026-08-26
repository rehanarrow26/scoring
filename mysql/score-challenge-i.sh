#!/bin/bash
# ================================================================
# MULTI-TENANT DATABASE & RECOVERY CHECKER
# CHAPTER 19
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
echo "   MULTI-TENANT DB CHECKER - CH 19"
echo "========================================="
echo

# Daftar 7 Skenario (DB:USER:PASS)
items=(
    "db_finance:user_finance:Fin@nce2026!"
    "db_hrd:user_hrd:HRDpass2026!"
    "db_perpus:user_perpus:Perpus2026!"
    "db_cbt:user_cbt:CBTsecure2026!"
    "db_asset:user_asset:AssetPass2026!"
    "db_alumni:user_alumni:Alumni2026!"
    "db_kantin:user_kantin:KantinPay2026!"
)

# 1. Cek Keberadaan 7 Database (21 Poin)
db_passed=0
for item in "${items[@]}"; do
    IFS=":" read -r db user pass <<< "$item"
    if mysql -e "USE $db;" 2>/dev/null; then
        db_passed=$((db_passed + 1))
    fi
done

echo -n "Checking 7 Databases existence...................."
if [ "$db_passed" -eq 7 ]; then
    pass_check 21
else
    fail_check
fi

# 2. Cek File Backup SQL di /var/backups/ (21 Poin)
backup_passed=0
for item in "${items[@]}"; do
    IFS=":" read -r db user pass <<< "$item"
    if [ -f "/var/backups/${db}.sql" ] && [ -s "/var/backups/${db}.sql" ]; then
        backup_passed=$((backup_passed + 1))
    fi
done

echo -n "Checking 7 Backup Files in /var/backups/.........."
if [ "$backup_passed" -eq 7 ]; then
    pass_check 21
else
    fail_check
fi

# 3. Cek User & Grant Privileges via CLI (21 Poin)
user_passed=0
for item in "${items[@]}"; do
    IFS=":" read -r db user pass <<< "$item"
    if mysql -u "$user" -p"$pass" -e "USE $db;" 2>/dev/null; then
        user_passed=$((user_passed + 1))
    fi
done

echo -n "Checking User Privileges & Direct CLI Login......."
if [ "$user_passed" -eq 7 ]; then
    pass_check 21
else
    fail_check
fi

# 4. Cek Autentikasi User via phpMyAdmin (28 Poin)
echo -n "Testing Login Authentication to phpMyAdmin Endpoint..."
pma_passed=0

for item in "${items[@]}"; do
    IFS=":" read -r db user pass <<< "$item"
    
    cookie_file=$(mktemp)
    
    # Ambil halaman utama phpMyAdmin dan simpan cookie sesi
    init_page=$(curl -s -c "$cookie_file" -L "http://127.0.0.1/phpmyadmin/index.php")
    
    # Ekstrak token CSRF dari response HTML (dukungan berbagai versi phpMyAdmin)
    token=$(echo "$init_page" | grep -oP 'name="token"\s+value="\K[^"]+' | head -n 1)
    if [ -z "$token" ]; then
        token=$(echo "$init_page" | grep -oP 'set_token=\K[^&"]+' | head -n 1)
    fi
    
    # Kirim payload POST Login dengan menyertakan cookie & token
    res=$(curl -s -b "$cookie_file" -c "$cookie_file" -L -X POST "http://127.0.0.1/phpmyadmin/index.php" \
        --data-urlencode "pma_username=$user" \
        --data-urlencode "pma_password=$pass" \
        --data-urlencode "server=1" \
        --data-urlencode "target=index.php" \
        --data-urlencode "token=$token")

    # Verifikasi keberhasilan login (ditemukannya elemen UI setelah autentikasi)
    if echo "$res" | grep -qE "(logout|pma_navigation|db_structure|server_databases|logged_in)"; then
        pma_passed=$((pma_passed + 1))
    fi
    
    rm -f "$cookie_file"
done

if [ "$pma_passed" -eq 7 ]; then
    pass_check 28
else
    fail_check
fi

# 5. Cek Service phpMyAdmin Web (9 Poin)
echo -n "Checking phpMyAdmin Web Endpoint Status..........."
code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/phpmyadmin/)
if [ "$code" -eq 200 ] || [ "$code" -eq 302 ]; then
    pass_check 9
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
  "chapter_id": 19,
  "score": $score,
  "status": "$status"
}
EOF
