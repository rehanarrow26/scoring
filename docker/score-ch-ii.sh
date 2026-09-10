#!/bin/bash
# ================================================================
# SCORING SCRIPT: TANTANGAN MANAJEMEN DOCKER VOLUME (CHAPTER 41)
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
echo "  GRADER: TANTANGAN MANAJEMEN DOCKER VOLUME (LAB 41)"
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK CHALLENGE 1: PERSISTENSI DATA WEB APP (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Challenge 1 - Web App Data Persistence (20 pts)..."
APP_RUNNING=$(docker inspect -f '{{.State.Running}}' app-notes 2>/dev/null || echo "false")
APP_MOUNT=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/usr/share/nginx/html"}}{{.Name}}{{end}}{{end}}' app-notes 2>/dev/null || echo "")
APP_CONTENT=$(curl -s --connect-timeout 2 http://localhost:8082 2>/dev/null || echo "")

if [ "$APP_RUNNING" = "true" ] && [ -n "$APP_MOUNT" ] && [[ "$APP_CONTENT" == *"Hello Volume"* ]]; then
    pass_check 20
else
    fail_check "Container 'app-notes' tidak aktif, mount ke /usr/share/nginx/html tidak ada, atau konten 'Hello Volume' tidak ditemukan di port 8082."
fi

# ------------------------------------------------------------------
# 2. CEK CHALLENGE 2: BACKUP DAN RESTORE VOLUME DB (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Challenge 2 - DB Backup & Restore Volume (20 pts)..."
HAS_BACKUP_FILE=false
if [ -f "$SCRIPT_DIR/backup-db/db-data.tar.gz" ] || [ -f "backup-db/db-data.tar.gz" ]; then
    HAS_BACKUP_FILE=true
fi

DB_RESTORE_RUNNING=$(docker inspect -f '{{.State.Running}}' db-backup-test 2>/dev/null || echo "false")
DB_RESTORE_MOUNT=$(docker inspect -f '{{range .Mounts}}{{.Name}}{{end}}' db-backup-test 2>/dev/null || echo "")

if [ "$HAS_BACKUP_FILE" = true ] && [ "$DB_RESTORE_RUNNING" = "true" ] && [[ "$DB_RESTORE_MOUNT" == *"vol-db-restored"* ]]; then
    pass_check 20
else
    fail_check "File backup 'backup-db/db-data.tar.gz' tidak ditemukan, container 'db-backup-test' tidak berjalan, atau tidak menggunakan volume 'vol-db-restored'."
fi

# ------------------------------------------------------------------
# 3. CEK CHALLENGE 3: SHARED VOLUME WRITER & READER (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Challenge 3 - Shared Volume Writer & Reader (20 pts)..."
WRITER_RUNNING=$(docker inspect -f '{{.State.Running}}' log-writer 2>/dev/null || echo "false")
READER_RUNNING=$(docker inspect -f '{{.State.Running}}' log-reader 2>/dev/null || echo "false")
READER_CONTENT=$(curl -s --connect-timeout 2 http://localhost:8083/status.txt 2>/dev/null || echo "")

if [ "$WRITER_RUNNING" = "true" ] && [ "$READER_RUNNING" = "true" ] && [[ "$READER_CONTENT" =~ [0-9] ]]; then
    pass_check 20
else
    fail_check "Container 'log-writer'/'log-reader' tidak aktif atau file 'status.txt' tidak dapat diakses di http://localhost:8083."
fi

# ------------------------------------------------------------------
# 4. CEK CHALLENGE 4: READ-ONLY VOLUME PROTECTION (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Challenge 4 - Read-Only Volume Protection (20 pts)..."
WEB_CONF_RUNNING=$(docker inspect -f '{{.State.Running}}' web-config-test 2>/dev/null || echo "false")
TOUCH_TEST=$(docker exec web-config-test touch /usr/share/nginx/html/test_write.txt 2>&1 || true)

if [ "$WEB_CONF_RUNNING" = "true" ] && [[ "$TOUCH_TEST" == *"Read-only file system"* ]]; then
    pass_check 20
else
    fail_check "Container 'web-config-test' tidak aktif atau direktori /usr/share/nginx/html tidak terproteksi Read-Only (ro)."
fi

# ------------------------------------------------------------------
# 5. CEK CHALLENGE 5: MIGRASI DATA ANTAR VOLUME (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Checking Challenge 5 - Data Migration to New Volume (20 pts)..."
MIGRASI_RUNNING=$(docker inspect -f '{{.State.Running}}' db-migrasi 2>/dev/null || echo "false")
MIGRASI_MOUNT=$(docker inspect -f '{{range .Mounts}}{{.Name}}{{end}}' db-migrasi 2>/dev/null || echo "")
FILE_EXISTS=$(docker run --rm -v vol-new-db:/data busybox sh -c "[ -f /data/sample.txt ] && echo 'yes' || echo 'no'" 2>/dev/null || echo "no")

if [ "$MIGRASI_RUNNING" = "true" ] && [[ "$MIGRASI_MOUNT" == *"vol-new-db"* ]] && [ "$FILE_EXISTS" = "yes" ]; then
    pass_check 20
else
    fail_check "Container 'db-migrasi' tidak aktif, tidak menggunakan volume 'vol-new-db', atau berkas '/data/sample.txt' tidak ditemukan di volume baru."
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

# Simpan hasil penilaian JSON untuk LMS Integrasi
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-41-docker-volume-challenge",
  "score": $score,
  "status": "$status"
}
EOF
