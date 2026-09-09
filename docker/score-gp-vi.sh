#!/bin/bash
# ================================================================
# SCORING SCRIPT: MANAJEMEN DOCKER VOLUME & PERSISTENSI DATA (CHAPTER 40)
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
echo "  GRADER: MANAJEMEN DOCKER VOLUME (LAB 40)       "
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. CEK DOCKER VOLUME 'vol-belajar' (15 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Docker Volume 'vol-belajar' (15 pts)..."
if docker volume ls --format '{{.Name}}' | grep -q "^vol-belajar$"; then
    pass_check 15
else
    fail_check "Docker Volume 'vol-belajar' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 2. CEK DOCKER NETWORK 'belajar' (10 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Docker Network 'belajar' (10 pts)..."
if docker network ls --format '{{.Name}}' | grep -q "^belajar$"; then
    pass_check 10
else
    fail_check "Docker Network 'belajar' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 3. CEK CONTAINER 'mariadb' AKTIF (15 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Active Container 'mariadb' (15 pts)..."
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' mariadb 2>/dev/null || echo "false")
if [ "$IS_RUNNING" = "true" ]; then
    pass_check 15
else
    fail_check "Container 'mariadb' tidak ada atau tidak dalam kondisi running."
fi

# ------------------------------------------------------------------
# 4. CEK MOUNTING VOLUME KE /var/lib/mysql (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Volume Mount to Container (20 pts)..."
MOUNT_SOURCE=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/var/lib/mysql"}}{{.Name}}{{end}}{{end}}' mariadb 2>/dev/null || echo "")
if [ "$MOUNT_SOURCE" = "vol-belajar" ]; then
    pass_check 20
else
    fail_check "Volume 'vol-belajar' tidak ter-mount dengan benar ke '/var/lib/mysql'."
fi

# ------------------------------------------------------------------
# 5. CEK DATABASE 'perpustakaan' DALAM MARIADB (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Checking Database 'perpustakaan' (20 pts)..."
HAS_DB=$(docker exec mariadb mariadb -u root -psabarmenanti -sN -e "SHOW DATABASES LIKE 'perpustakaan';" 2>/dev/null | tr -d '\r\n')
if [ "$HAS_DB" = "perpustakaan" ]; then
    pass_check 20
else
    fail_check "Database 'perpustakaan' tidak ditemukan dalam container MariaDB."
fi

# ------------------------------------------------------------------
# 6. CEK ISI & DATA TABEL 'buku' (20 POIN)
# ------------------------------------------------------------------
echo -n "6. Checking Data Persistence in Table 'buku' (20 pts)..."
DATA_COUNT=$(docker exec mariadb mariadb -u root -psabarmenanti -sN -e "USE perpustakaan; SELECT COUNT(*) FROM buku WHERE kode IN ('001', '002');" 2>/dev/null | tr -d '\r\n' || echo "0")
if [ "$DATA_COUNT" -eq 2 ]; then
    pass_check 20
else
    fail_check "Data dalam tabel 'buku' tidak sesuai/tidak ter-persist (Ditemukan: $DATA_COUNT baris)."
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
  "chapter_id": "lab-40-docker-volume-management",
  "score": $score,
  "status": "$status"
}
EOF
