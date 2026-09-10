#!/bin/bash
# ================================================================
# SCORING SCRIPT: STUDI KASUS DOCKER VOLUME (CHAPTER 40)
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
    echo -e "    \e[33m└─> Alasan: $reason\e[0m"
}

echo "================================================="
echo "  GRADER: STUDI KASUS DOCKER VOLUME (LAB 40)     "
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK STUDI KASUS 1: WORDPRESS PERSISTENT VOLUME (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Case 1 - WordPress & DB Volume Mounts (20 pts)..."
WP_RUNNING=$(docker inspect -f '{{.State.Running}}' wordpress 2>/dev/null || echo "false")
DB_RUNNING=$(docker inspect -f '{{.State.Running}}' wp-db 2>/dev/null || echo "false")
WP_MOUNT=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/var/www/html"}}{{.Name}}{{end}}{{end}}' wordpress 2>/dev/null || echo "")

# PERBAIKAN: Gunakan grep -q untuk menghindari masalah dual-stack IPv4/IPv6 (\n8080)
if docker port wordpress 80/tcp 2>/dev/null | grep -q "8080"; then
    WP_PORT="8080"
else
    WP_PORT=""
fi

if [ "$WP_RUNNING" = "true" ] && [ "$DB_RUNNING" = "true" ] && [ "$WP_MOUNT" = "wp-data" ] && [ "$WP_PORT" = "8080" ]; then
    pass_check 20
else
    fail_check "Container 'wordpress'/'wp-db' tidak aktif, volume 'wp-data' salah, atau port 8080 tidak dipublikasikan."
fi

# ------------------------------------------------------------------
# 2. CEK STUDI KASUS 2: BACKUP & RESTORE VOLUME (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Case 2 - Backup File & Restore DB on Port 3307 (20 pts)..."
HAS_BACKUP_FILE=false
if [ -f "backup/vol-belajar-backup.tar.gz" ] || [ -f "$SCRIPT_DIR/backup/vol-belajar-backup.tar.gz" ]; then
    HAS_BACKUP_FILE=true
fi

# PERBAIKAN: Gunakan grep -q untuk periksa port 3307
if docker port mariadb-restore 3306/tcp 2>/dev/null | grep -q "3307"; then
    RESTORE_PORT="3307"
else
    RESTORE_PORT=""
fi

RESTORE_DB_DATA=$(docker exec mariadb-restore mariadb -u root -psabarmenanti -sN -e "USE perpustakaan; SELECT COUNT(*) FROM buku;" 2>/dev/null | tr -d '\r\n' || echo "0")

if [ "$HAS_BACKUP_FILE" = true ] && [ "$RESTORE_PORT" = "3307" ] && [ "$RESTORE_DB_DATA" -eq 2 ] 2>/dev/null; then
    pass_check 20
else
    fail_check "File backup .tar.gz tidak ada, port 3307 tidak tepat, atau data pada 'mariadb-restore' tidak valid."
fi

# ------------------------------------------------------------------
# 3. CEK STUDI KASUS 3: SHARED VOLUME & READ-ONLY VIEWER (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Case 3 - Shared Volume & Read-Only Viewer on Port 8081 (20 pts)..."
GEN_RUNNING=$(docker inspect -f '{{.State.Running}}' report-generator 2>/dev/null || echo "false")
VIEW_RUNNING=$(docker inspect -f '{{.State.Running}}' report-viewer 2>/dev/null || echo "false")
VIEW_RO=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/usr/share/nginx/html"}}{{.RW}}{{end}}{{end}}' report-viewer 2>/dev/null || echo "true")

# PERBAIKAN: Gunakan grep -q untuk periksa port 8081
if docker port report-viewer 80/tcp 2>/dev/null | grep -q "8081"; then
    VIEW_PORT="8081"
else
    VIEW_PORT=""
fi

if [ "$GEN_RUNNING" = "true" ] && [ "$VIEW_RUNNING" = "true" ] && [ "$VIEW_RO" = "false" ] && [ "$VIEW_PORT" = "8081" ]; then
    pass_check 20
else
    fail_check "Container generator/viewer tidak aktif, mount pada 'report-viewer' bukan Read-Only (ro), atau port bukan 8081."
fi

# ------------------------------------------------------------------
# 4. CEK STUDI KASUS 4: READ-ONLY CONFIGURATION VOLUME (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Case 4 - Read-Only Config Volume Protection (20 pts)..."
APP1_RO=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/etc/app"}}{{.RW}}{{end}}{{end}}' app-instance-1 2>/dev/null || echo "true")
APP2_RO=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/etc/app"}}{{.RW}}{{end}}{{end}}' app-instance-2 2>/dev/null || echo "true")
CONF_CONTENT=$(docker exec app-instance-1 cat /etc/app/app.conf 2>/dev/null | tr -d '\r\n' || echo "")
WRITE_TEST=$(docker exec app-instance-1 sh -c "echo 'test' >> /etc/app/app.conf" 2>&1 || true)

if [ "$APP1_RO" = "false" ] && [ "$APP2_RO" = "false" ] && [[ "$CONF_CONTENT" == *"APP_MODE=production"* ]] && [[ "$WRITE_TEST" == *"Read-only file system"* ]]; then
    pass_check 20
else
    fail_check "Volume 'app-config' tidak terproteksi Read-Only pada app-instance-1/2 atau file konfigurasi tidak valid."
fi

# ------------------------------------------------------------------
# 5. CEK STUDI KASUS 5: MIGRASI DATA VOLUME (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Checking Case 5 - Migrated Data on 'mariadb-prod' Port 3308 (20 pts)..."
PROD_RUNNING=$(docker inspect -f '{{.State.Running}}' mariadb-prod 2>/dev/null || echo "false")
PROD_MOUNT=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/var/lib/mysql"}}{{.Name}}{{end}}{{end}}' mariadb-prod 2>/dev/null || echo "")

# PERBAIKAN: Gunakan grep -q untuk periksa port 3308
if docker port mariadb-prod 3306/tcp 2>/dev/null | grep -q "3308"; then
    PROD_PORT="3308"
else
    PROD_PORT=""
fi

MIGRATED_DB_DATA=$(docker exec mariadb-prod mariadb -u root -psabarmenanti -sN -e "USE perpustakaan; SELECT COUNT(*) FROM buku;" 2>/dev/null | tr -d '\r\n' || echo "0")

if [ "$PROD_RUNNING" = "true" ] && [ "$PROD_MOUNT" = "prod-mariadb-data" ] && [ "$PROD_PORT" = "3308" ] && [ "$MIGRATED_DB_DATA" -eq 2 ] 2>/dev/null; then
    pass_check 20
else
    fail_check "Container 'mariadb-prod' tidak berjalan, port bukan 3308, volume bukan 'prod-mariadb-data', atau data migrasi tidak lengkap."
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
  "chapter_id": "lab-40-docker-volume-case-studies",
  "score": $score,
  "status": "$status"
}
EOF
