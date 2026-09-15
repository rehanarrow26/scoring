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
# 1. CEK CHALLENGE 1: CONTAINER APP-NOTES ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Challenge 1 - Container 'app-notes' exists (20 pts)..."
if docker ps -a --format '{{.Names}}' | grep -q "^app-notes$"; then
    pass_check 20
else
    fail_check "Container 'app-notes' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 2. CEK CHALLENGE 2: FILE BACKUP DAN CONTAINER DB-BACKUP-TEST ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Challenge 2 - Backup file & Container 'db-backup-test' exist (20 pts)..."
HAS_BACKUP=false
if [ -f "$SCRIPT_DIR/backup-db/db-data.tar.gz" ] || [ -f "backup-db/db-data.tar.gz" ]; then
    HAS_BACKUP=true
fi
HAS_CONTAINER=$(docker ps -a --format '{{.Names}}' | grep -q "^db-backup-test$" && echo "true" || echo "false")

if [ "$HAS_BACKUP" = true ] && [ "$HAS_CONTAINER" = "true" ]; then
    pass_check 20
else
    fail_check "File 'backup-db/db-data.tar.gz' atau container 'db-backup-test' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 3. CEK CHALLENGE 3: CONTAINER LOG-WRITER & LOG-READER ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Challenge 3 - Containers 'log-writer' & 'log-reader' exist (20 pts)..."
HAS_WRITER=$(docker ps -a --format '{{.Names}}' | grep -q "^log-writer$" && echo "true" || echo "false")
HAS_READER=$(docker ps -a --format '{{.Names}}' | grep -q "^log-reader$" && echo "true" || echo "false")

if [ "$HAS_WRITER" = "true" ] && [ "$HAS_READER" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'log-writer' atau 'log-reader' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 4. CEK CHALLENGE 4: CONTAINER WEB-CONFIG-TEST ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Challenge 4 - Container 'web-config-test' exists (20 pts)..."
if docker ps -a --format '{{.Names}}' | grep -q "^web-config-test$"; then
    pass_check 20
else
    fail_check "Container 'web-config-test' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 5. CEK CHALLENGE 5: VOLUME VOL-NEW-DB DAN CONTAINER DB-MIGRASI ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Checking Challenge 5 - Volume 'vol-new-db' & Container 'db-migrasi' exist (20 pts)..."
HAS_VOL=$(docker volume ls --format '{{.Name}}' | grep -q "^vol-new-db$" && echo "true" || echo "false")
HAS_MIGRASI=$(docker ps -a --format '{{.Names}}' | grep -q "^db-migrasi$" && echo "true" || echo "false")

if [ "$HAS_VOL" = "true" ] && [ "$HAS_MIGRASI" = "true" ]; then
    pass_check 20
else
    fail_check "Volume 'vol-new-db' atau container 'db-migrasi' tidak ditemukan."
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
