#!/bin/bash
# ================================================================
# MULTI-SUBDOMAIN WORDPRESS DEPLOYMENT CHECKER (ROBUST VERSION)
# CHAPTER 21
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

echo "========================================="
echo "  MULTI-WORDPRESS CHECKER - CH 21"
echo "========================================="
echo

# Data 5 Skenario (subdomain:docroot:dbname:dbuser:dbpass)
items=(
    "siswa.smk.lan:/var/www/siswa:db_wp_siswa:user_wp_siswa:Siswa2026!"
    "guru.smk.lan:/var/www/guru:db_wp_guru:user_wp_guru:Guru2026!"
    "perpus.smk.lan:/var/www/perpus:db_wp_perpus:user_wp_perpus:Perpus2026!"
    "tefa.smk.lan:/var/www/tefa:db_wp_tefa:user_wp_tefa:Tefa2026!"
    "bkk.smk.lan:/var/www/bkk:db_wp_bkk:user_wp_bkk:Bkk2026!"
)

# 1. Cek Keberadaan 5 Database (15 Poin)
echo -n "Checking 5 Databases existence...................."
db_passed=0
db_failed_name=""
for item in "${items[@]}"; do
    IFS=":" read -r domain docroot dbname dbuser dbpass <<< "$item"
    # Memeriksa direktori fisik database di /var/lib/mysql atau via SQL
    if mysql -u root -e "USE \`$dbname\`;" 2>/dev/null || [ -d "/var/lib/mysql/$dbname" ]; then
        db_passed=$((db_passed + 1))
    else
        db_failed_name="$dbname"
        break
    fi
done

if [ "$db_passed" -eq 5 ]; then
    pass_check 15
else
    fail_check "Database '$db_failed_name' tidak ditemukan di MariaDB/MySQL."
fi

# 2. Cek 5 User DB & Access (15 Poin)
echo -n "Checking 5 MySQL Users & Privileges..............."
user_passed=0
user_failed_name=""
for item in "${items[@]}"; do
    IFS=":" read -r domain docroot dbname dbuser dbpass <<< "$item"
    if mysql -h 127.0.0.1 -u "$dbuser" -p"$dbpass" -e "USE \`$dbname\`;" 2>/dev/null || mysql -u "$dbuser" -p"$dbpass" -e "USE \`$dbname\`;" 2>/dev/null; then
        user_passed=$((user_passed + 1))
    else
        user_failed_name="$dbuser"
        break
    fi
done

if [ "$user_passed" -eq 5 ]; then
    pass_check 15
else
    fail_check "User DB '$user_failed_name' gagal autentikasi dengan passwordnya atau tidak punya akses ke '$dbname'."
fi

# 3. Cek Document Roots & Ownership (20 Poin)
echo -n "Checking 5 Document Roots & www-data Ownership...."
doc_passed=0
doc_failed_reason=""
for item in "${items[@]}"; do
    IFS=":" read -r domain docroot dbname dbuser dbpass <<< "$item"
    if [ ! -d "$docroot" ]; then
        doc_failed_reason="Folder '$docroot' belum dibuat."
        break
    elif [ ! -f "$docroot/wp-config.php" ]; then
        doc_failed_reason="File '$docroot/wp-config.php' belum ada."
        break
    else
        owner=$(stat -c '%U:%G' "$docroot")
        if [ "$owner" != "www-data:www-data" ]; then
            doc_failed_reason="Kepemilikan '$docroot' masih '$owner', harus 'www-data:www-data'."
            break
        fi
        doc_passed=$((doc_passed + 1))
    fi
done

if [ "$doc_passed" -eq 5 ]; then
    pass_check 20
else
    fail_check "$doc_failed_reason"
fi

# 4. Cek Apache VirtualHost Files (20 Poin)
echo -n "Checking 5 Apache VirtualHost Configurations......"
vhost_passed=0
vhost_failed_reason=""
for item in "${items[@]}"; do
    IFS=":" read -r domain docroot dbname dbuser dbpass <<< "$item"
    sub="${domain%%.*}"
    conf_file="/etc/apache2/sites-available/$sub.conf"
    
    if [ ! -f "$conf_file" ]; then
        vhost_failed_reason="Berkas vhost '$conf_file' tidak ditemukan."
        break
    elif [ ! -L "/etc/apache2/sites-enabled/$sub.conf" ]; then
        vhost_failed_reason="Situs '$sub.conf' belum diaktifkan (jalankan: a2ensite $sub.conf)."
        break
    elif ! grep -q "ServerName $domain" "$conf_file"; then
        vhost_failed_reason="ServerName '$domain' tidak ditemukan di '$conf_file'."
        break
    fi
    vhost_passed=$((vhost_passed + 1))
done

if [ "$vhost_passed" -eq 5 ]; then
    pass_check 20
else
    fail_check "$vhost_failed_reason"
fi

# 5. Cek HTTP Response 5 Subdomain (30 Poin)
echo -n "Checking HTTP Endpoints Response for 5 Subdomains."
http_passed=0
http_failed_reason=""
for item in "${items[@]}"; do
    IFS=":" read -r domain docroot dbname dbuser dbpass <<< "$item"
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $domain" http://127.0.0.1/)
    if [ "$code" -eq 200 ] || [ "$code" -eq 301 ] || [ "$code" -eq 302 ]; then
        http_passed=$((http_passed + 1))
    else
        http_failed_reason="Domain http://$domain mengembalikan status code '$code' (Diharapkan 200/301/302)."
        break
    fi
done

if [ "$http_passed" -eq 5 ]; then
    pass_check 30
else
    fail_check "$http_failed_reason"
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
  "chapter_id": 21,
  "score": $score,
  "status": "$status"
}
EOF
