#!/bin/bash
# ================================================================
# SCORING SCRIPT - CHAPTER 26: CHALLENGE DOCKER CONTAINER
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
echo "  GRADER: CHAPTER 26 (STUDI KASUS CHALLENGE 1-9) "
echo "================================================="
echo

# 1. Service Docker Status (10 Poin)
echo -n "Checking Docker Service Status (10 pts)................."
if systemctl is-active --quiet docker; then
    pass_check 10
else
    fail_check "Service Docker tidak aktif."
fi

# 2. Case 1: WordPress Container Status (10 Poin)
echo -n "Case 1: Container 'cms-wordpress' Running (10 pts)......"
RUNNING_WP=$(docker inspect -f '{{.State.Running}}' cms-wordpress 2>/dev/null || echo "false")
if [ "$RUNNING_WP" = "true" ]; then
    pass_check 10
else
    fail_check "Container 'cms-wordpress' tidak ditemukan atau tidak berjalan."
fi

# 3. Case 2: Apache Limited Resources (10 Poin)
echo -n "Case 2: Container 'apache-limited' (2 CPU, 512MB) (10 pts)."
CPUS_SK2=$(docker inspect -f '{{.HostConfig.NanoCpus}}' apache-limited 2>/dev/null || echo "0")
MEM_SK2=$(docker inspect -f '{{.HostConfig.Memory}}' apache-limited 2>/dev/null || echo "0")
if [ "$CPUS_SK2" -eq 2000000000 ] && [ "$MEM_SK2" -eq 536870912 ]; then
    pass_check 10
else
    fail_check "Resource limit apache-limited tidak sesuai (--cpus=2 -m 512m)."
fi

# 4. Case 3: MySQL Perpus Environment Variables (10 Poin)
echo -n "Case 3: Container 'mysql-perpus' Envs (10 pts).........."
MYSQL_ENV_SK3=$(docker inspect -f '{{range .Config.Env}}{{if eq . "MYSQL_DATABASE=db_perpus_dev"}}{{.}}{{end}}{{end}}' mysql-perpus 2>/dev/null || echo "")
if [ "$MYSQL_ENV_SK3" = "MYSQL_DATABASE=db_perpus_dev" ]; then
    pass_check 10
else
    fail_check "Environment variable MYSQL_DATABASE=db_perpus_dev tidak cocok."
fi

# 5. Case 4: Portal Berita Port 9090:80 (10 Poin)
echo -n "Case 4: Container 'portal-berita' Port 9090:80 (10 pts).."
PORT_SK4=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Ports}}{{if eq $k "80/tcp"}}{{(index $v 0).HostPort}}{{end}}{{end}}' portal-berita 2>/dev/null || echo "")
if [ "$PORT_SK4" = "9090" ]; then
    pass_check 10
else
    fail_check "Port binding 9090:80 pada portal-berita gagal."
fi

# 6. Case 5: Absensi Web Volume Mount (10 Poin)
echo -n "Case 5: Container 'absensi-web' Volume Mount (10 pts)..."
MOUNT_SK5=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/usr/share/nginx/html"}}{{.Source}}{{end}}{{end}}' absensi-web 2>/dev/null || echo "")
if [ "$MOUNT_SK5" = "/data/absensi" ]; then
    pass_check 10
else
    fail_check "Bind mount /data/absensi ke /usr/share/nginx/html tidak sesuai."
fi

# 7. Case 7: Network net-bkk Exists (10 Poin)
echo -n "Case 7: Custom Network 'net-bkk' Exists (10 pts)........"
if docker network inspect "net-bkk" >/dev/null 2>&1; then
    pass_check 10
else
    fail_check "Network 'net-bkk' tidak ditemukan."
fi

# 8. Case 8: Alumni System Full Specs (15 Poin)
echo -n "Case 8: Comprehensive 'alumni-system' Setup (15 pts)...."
NET_SK8=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' alumni-system 2>/dev/null || echo "")
CPUS_SK8=$(docker inspect -f '{{.HostConfig.NanoCpus}}' alumni-system 2>/dev/null || echo "0")
MEM_SK8=$(docker inspect -f '{{.HostConfig.Memory}}' alumni-system 2>/dev/null || echo "0")
PORT_SK8=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Ports}}{{if eq $k "80/tcp"}}{{(index $v 0).HostPort}}{{end}}{{end}}' alumni-system 2>/dev/null || echo "")
ENV1_SK8=$(docker inspect -f '{{range .Config.Env}}{{if eq . "APP_ENV=production"}}{{.}}{{end}}{{end}}' alumni-system 2>/dev/null || echo "")
ENV2_SK8=$(docker inspect -f '{{range .Config.Env}}{{if eq . "APP_REGION=jakarta"}}{{.}}{{end}}{{end}}' alumni-system 2>/dev/null || echo "")
MOUNT_SK8=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/usr/share/nginx/html"}}{{.Source}}{{end}}{{end}}' alumni-system 2>/dev/null || echo "")

if [ "$NET_SK8" = "net-alumni" ] && [ "$CPUS_SK8" -eq 1000000000 ] && [ "$MEM_SK8" -eq 268435456 ] && [ "$PORT_SK8" = "8082" ] && [ "$ENV1_SK8" = "APP_ENV=production" ] && [ "$ENV2_SK8" = "APP_REGION=jakarta" ] && [ "$MOUNT_SK8" = "/data/alumni-system" ]; then
    pass_check 15
else
    fail_check "Konfigurasi komprehensif alumni-system belum sesuai."
fi

# 9. Case 9: MySQL Kantin Specs & Network (15 Poin)
echo -n "Case 9: Container 'mysql-kantin' Specs & Network (15 pts)."
NET_SK9=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' mysql-kantin 2>/dev/null || echo "")
CPUS_SK9=$(docker inspect -f '{{.HostConfig.NanoCpus}}' mysql-kantin 2>/dev/null || echo "0")
MEM_SK9=$(docker inspect -f '{{.HostConfig.Memory}}' mysql-kantin 2>/dev/null || echo "0")
ENV_SK9=$(docker inspect -f '{{range .Config.Env}}{{if eq . "MYSQL_DATABASE=db_kantin"}}{{.}}{{end}}{{end}}' mysql-kantin 2>/dev/null || echo "")

if [ "$NET_SK9" = "net-kantin" ] && [ "$CPUS_SK9" -eq 1000000000 ] && [ "$MEM_SK9" -eq 536870912 ] && [ "$ENV_SK9" = "MYSQL_DATABASE=db_kantin" ]; then
    pass_check 15
else
    fail_check "Konfigurasi mysql-kantin (network/resources/envs) belum sesuai."
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
  "chapter_id": "chapter-26-studi-kasus-challenge-manajemen-docker-container",
  "score": $score,
  "status": "$status"
}
EOF
