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
# 1. CEK STUDI KASUS 1: CONTAINER WORDPRESS & WP-DB ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Case 1 - Containers 'wordpress' & 'wp-db' exist (20 pts)..."
HAS_WP=$(docker ps -a --format '{{.Names}}' | grep -q "^wordpress$" && echo "true" || echo "false")
HAS_WP_DB=$(docker ps -a --format '{{.Names}}' | grep -q "^wp-db$" && echo "true" || echo "false")

if [ "$HAS_WP" = "true" ] && [ "$HAS_WP_DB" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'wordpress' atau 'wp-db' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 2. CEK STUDI KASUS 2: FILE BACKUP & CONTAINER MARIADB-RESTORE ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Case 2 - Backup file & Container 'mariadb-restore' exist (20 pts)..."
HAS_BACKUP_FILE=false
if [ -f "backup/vol-belajar-backup.tar.gz" ] || [ -f "$SCRIPT_DIR/backup/vol-belajar-backup.tar.gz" ]; then
    HAS_BACKUP_FILE=true
fi
HAS_RESTORE=$(docker ps -a --format '{{.Names}}' | grep -q "^mariadb-restore$" && echo "true" || echo "false")

if [ "$HAS_BACKUP_FILE" = true ] && [ "$HAS_RESTORE" = "true" ]; then
    pass_check 20
else
    fail_check "File backup 'vol-belajar-backup.tar.gz' atau container 'mariadb-restore' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 3. CEK STUDI KASUS 3: CONTAINER REPORT-GENERATOR & REPORT-VIEWER ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Case 3 - Containers 'report-generator' & 'report-viewer' exist (20 pts)..."
HAS_GEN=$(docker ps -a --format '{{.Names}}' | grep -q "^report-generator$" && echo "true" || echo "false")
HAS_VIEW=$(docker ps -a --format '{{.Names}}' | grep -q "^report-viewer$" && echo "true" || echo "false")

if [ "$HAS_GEN" = "true" ] && [ "$HAS_VIEW" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'report-generator' atau 'report-viewer' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 4. CEK STUDI KASUS 4: CONTAINER APP-INSTANCE-1 & APP-INSTANCE-2 ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Case 4 - Containers 'app-instance-1' & 'app-instance-2' exist (20 pts)..."
HAS_APP1=$(docker ps -a --format '{{.Names}}' | grep -q "^app-instance-1$" && echo "true" || echo "false")
HAS_APP2=$(docker ps -a --format '{{.Names}}' | grep -q "^app-instance-2$" && echo "true" || echo "false")

if [ "$APP1_EXISTS" = "true" ] || [ "$HAS_APP1" = "true" ] && [ "$HAS_APP2" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'app-instance-1' atau 'app-instance-2' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 5. CEK STUDI KASUS 5: CONTAINER MARIADB-PROD & VOLUME PROD-MARIADB-DATA ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Checking Case 5 - Container 'mariadb-prod' & Volume 'prod-mariadb-data' exist (20 pts)..."
HAS_PROD=$(docker ps -a --format '{{.Names}}' | grep -q "^mariadb-prod$" && echo "true" || echo "false")
HAS_PROD_VOL=$(docker volume ls --format '{{.Name}}' | grep -q "^prod-mariadb-data$" && echo "true" || echo "false")

if [ "$HAS_PROD" = "true" ] && [ "$HAS_PROD_VOL" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'mariadb-prod' atau volume 'prod-mariadb-data' tidak ditemukan."
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
