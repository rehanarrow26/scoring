#!/bin/bash
# ================================================================
# SUBDOMAIN VIRTUAL HOST & DEPLOYMENT CHECKER
# CHAPTER 17
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
echo " SUBDOMAIN VIRTUAL HOST CHECKER - CH 17"
echo "========================================="
echo

subdomains=("shop" "portfolio1" "portfolio2" "cv" "streaming" "portfolio3" "food")

# 1. Cek Resolusi DNS (20 Poin)
dns_passed=0
for sub in "${subdomains[@]}"; do
    domain="${sub}.smk.lan"
    ip=$(dig +short @127.0.0.1 "$domain" 2>/dev/null || nslookup "$domain" 127.0.0.1 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}')
    if [ "$ip" = "192.168.10.10" ]; then
        dns_passed=$((dns_passed + 1))
    fi
done

echo -n "Checking DNS A Records for 7 subdomains (192.168.10.10)..."
if [ "$dns_passed" -eq 7 ]; then
    pass_check 20
else
    fail_check
fi

# 2. Cek Folder & Repository Git Cloned (35 Poin)
dir_passed=0
for sub in "${subdomains[@]}"; do
    path="/var/www/html/${sub}.smk.lan"
    if [ -d "$path" ] && [ "$(ls -A "$path")" ]; then
        dir_passed=$((dir_passed + 1))
    fi
done

echo -n "Checking Cloned Repositories in /var/www/html/............"
if [ "$dir_passed" -eq 7 ]; then
    pass_check 35
else
    fail_check
fi

# 3. Cek Config Virtual Host (20 Poin)
conf_passed=0
for sub in "${subdomains[@]}"; do
    # Mengecek berkas [subdomain].smk.lan.conf atau [subdomain].conf
    conf1="/etc/apache2/sites-available/${sub}.smk.lan.conf"
    conf2="/etc/apache2/sites-available/${sub}.conf"
    
    target_conf=""
    if [ -f "$conf1" ]; then
        target_conf="$conf1"
    elif [ -f "$conf2" ]; then
        target_conf="$conf2"
    fi

    if [ -n "$target_conf" ]; then
        if grep -Eq "ServerName\s+${sub}\.smk\.lan" "$target_conf" 2>/dev/null && \
           grep -Eq "DocumentRoot\s+/var/www/html/${sub}\.smk\.lan" "$target_conf" 2>/dev/null; then
            conf_passed=$((conf_passed + 1))
        fi
    fi
done

echo -n "Checking VirtualHost Configuration files.................."
if [ "$conf_passed" -eq 7 ]; then
    pass_check 20
else
    fail_check
fi

# 4. Cek Symlink Enabled Sites (10 Poin)
enabled_passed=0
for sub in "${subdomains[@]}"; do
    link1="/etc/apache2/sites-enabled/${sub}.smk.lan.conf"
    link2="/etc/apache2/sites-enabled/${sub}.conf"
    if [ -L "$link1" ] || [ -L "$link2" ]; then
        enabled_passed=$((enabled_passed + 1))
    fi
done

echo -n "Checking Enabled Sites (a2ensite)........................."
if [ "$enabled_passed" -eq 7 ]; then
    pass_check 10
else
    fail_check
fi

# 5. Cek Syntax Apache2 (5 Poin)
echo -n "Checking Apache2 Config Syntax............................"
if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
    pass_check 5
else
    fail_check
fi

# 6. Uji Response HTTP via Host Header (10 Poin)
echo -n "Checking HTTP Responses via Host Headers.................."
http_passed=0
for sub in "${subdomains[@]}"; do
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${sub}.smk.lan" http://127.0.0.1/)
    if [ "$code" -eq 200 ]; then
        http_passed=$((http_passed + 1))
    fi
done

if [ "$http_passed" -eq 7 ]; then
    pass_check 10
else
    fail_check
fi

# Limit Score Max 100
[ "$score" -gt 100 ] && score=100

# Output Ringkasan
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

# Simpan Hasil ke JSON
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": 17,
  "score": $score,
  "status": "$status"
}
EOF
