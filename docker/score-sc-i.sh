#!/bin/bash
# ================================================================
# SCORING SCRIPT - CHAPTER 25: MANAJEMEN DOCKER CONTAINER (ALL CASES)
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
echo "  GRADER: CHAPTER 25 (STUDI KASUS 1 - 8)        "
echo "================================================="
echo

# 1. Docker Service Status (10 Poin)
echo -n "Checking Docker Service Status (10 pts)................."
if systemctl is-active --quiet docker; then
    pass_check 10
else
    fail_check "Service Docker tidak aktif."
fi

# 2. Studi Kasus 1: web-apache (10 Poin)
echo -n "Case 1: Container 'web-apache' Running (10 pts)........."
RUNNING_APACHE=$(docker inspect -f '{{.State.Running}}' web-apache 2>/dev/null || echo "false")
if [ "$RUNNING_APACHE" = "true" ]; then
    pass_check 10
else
    fail_check "Container 'web-apache' tidak ditemukan atau tidak berjalan."
fi

# 3. Studi Kasus 2: nginx-limited Resource Limits (10 Poin)
echo -n "Case 2: Container 'nginx-limited' (1 CPU, 256MB) (10 pts)."
CPUS_SK2=$(docker inspect -f '{{.HostConfig.NanoCpus}}' nginx-limited 2>/dev/null || echo "0")
MEM_SK2=$(docker inspect -f '{{.HostConfig.Memory}}' nginx-limited 2>/dev/null || echo "0")
if [ "$CPUS_SK2" -eq 1000000000 ] && [ "$MEM_SK2" -eq 268435456 ]; then
    pass_check 10
else
    fail_check "Resource limit nginx-limited tidak sesuai (--cpus=1 -m 256m)."
fi

# 4. Studi Kasus 3: mysql-dev Environment Variable (10 Poin)
echo -n "Case 3: Container 'mysql-dev' Envs (10 pts)............."
MYSQL_ENV=$(docker exec mysql-dev env 2>/dev/null | grep "^MYSQL_DATABASE=db_sekolah" || echo "")
if [ -n "$MYSQL_ENV" ]; then
    pass_check 10
else
    fail_check "Environment variable MYSQL_DATABASE=db_sekolah tidak cocok."
fi

# 5. Studi Kasus 4: landing-page Port 8080:80 (10 Poin)
echo -n "Case 4: Container 'landing-page' Port 8080:80 (10 pts).."
PORT_SK4=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Ports}}{{if eq $k "80/tcp"}}{{(index $v 0).HostPort}}{{end}}{{end}}' landing-page 2>/dev/null || echo "")
if [ "$PORT_SK4" = "8080" ]; then
    pass_check 10
else
    fail_check "Port binding 8080:80 pada landing-page gagal."
fi

# 6. Studi Kasus 5: web-persistent Volume Bind Mount (10 Poin)
echo -n "Case 5: Container 'web-persistent' Volume (10 pts)....."
MOUNT_SK5=$(docker inspect -f '{{range .Mounts}}{{if and (eq .Source "/data/web") (eq .Destination "/var/www/html")}}{{.Source}}{{end}}{{end}}' web-persistent 2>/dev/null || echo "")
if [ "$MOUNT_SK5" = "/data/web" ]; then
    pass_check 10
else
    fail_check "Bind mount /data/web ke /var/www/html tidak sesuai."
fi

# 7. Studi Kasus 7: Custom Network 'net-testing' Exists (10 Poin)
echo -n "Case 7: Custom Network 'net-testing' Exists (10 pts)...."
if docker network inspect "net-testing" >/dev/null 2>&1; then
    pass_check 10
else
    fail_check "Network 'net-testing' tidak ditemukan."
fi

# 8. Studi Kasus 8: app-production Full Specs (30 Poin)
echo -n "Case 8: Comprehensive 'app-production' Setup (30 pts)..."
NET_SK8=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' app-production 2>/dev/null || echo "")
CPUS_SK8=$(docker inspect -f '{{.HostConfig.NanoCpus}}' app-production 2>/dev/null || echo "0")
MEM_SK8=$(docker inspect -f '{{.HostConfig.Memory}}' app-production 2>/dev/null || echo "0")
PORT_SK8=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Ports}}{{if eq $k "80/tcp"}}{{(index $v 0).HostPort}}{{end}}{{end}}' app-production 2>/dev/null || echo "")
ENV_SK8=$(docker exec app-production env 2>/dev/null | grep "^APP_ENV=production" || echo "")
MOUNT_SK8=$(docker inspect -f '{{range .Mounts}}{{if and (eq .Source "/data/app-production") (eq .Destination "/usr/share/nginx/html")}}{{.Source}}{{end}}{{end}}' app-production 2>/dev/null || echo "")

if [ "$NET_SK8" = "net-production" ] && [ "$CPUS_SK8" -eq 2000000000 ] && [ "$MEM_SK8" -eq 536870912 ] && [ "$PORT_SK8" = "8081" ] && [ -n "$ENV_SK8" ] && [ "$MOUNT_SK8" = "/data/app-production" ]; then
    pass_check 30
else
    fail_check "Konfigurasi komprehensif app-production belum lengkap/sesuai."
fi

# Limit Score Maksimal 100
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

# Output JSON
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "chapter-25-manajemen-docker-container",
  "score": $score,
  "status": "$status"
}
EOF
