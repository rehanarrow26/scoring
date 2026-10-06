#!/bin/bash
# ================================================================
# AUTOMATED GRADER: LAB 69 (DOCKER COMPOSE MARIADB & PHPMYADMIN)
# Total Max Score: 100 Pts
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
echo "  GRADER: LAB 69 (MARIADB & PHPMYADMIN COMPOSE)"
echo "================================================="
echo

# 1. CEK DIREKTORI KERJA MYAPP DAN FILE COMPOSE.YAML (20 Pts)
echo -n "Step 1: Memeriksa Direktori /root/myapp & compose.yaml (20 pts)..."
TARGET_DIR="/root/myapp"
COMPOSE_FILE="$TARGET_DIR/compose.yaml"

if [ -d "$TARGET_DIR" ] && [ -f "$COMPOSE_FILE" ]; then
    pass_check 20
else
    fail_check "Direktori '$TARGET_DIR' atau berkas '$COMPOSE_FILE' tidak ditemukan."
fi

# 2. CEK STRUKTUR DAN KONFIGURASI COMPOSE.YAML (20 Pts)
echo -n "Step 2: Memeriksa Konfigurasi Service & Environment di compose.yaml (20 pts)..."
if [ -f "$COMPOSE_FILE" ]; then
    MARIADB_SERVICE=$(grep -E '^[[:space:]]*mariadb:' "$COMPOSE_FILE" >/dev/null && echo "yes" || echo "no")
    PMA_SERVICE=$(grep -E '^[[:space:]]*phpmyadmin:' "$COMPOSE_FILE" >/dev/null && echo "yes" || echo "no")
    DB_NAME_OK=$(grep -E 'MYSQL_DATABASE:[[:space:]]*perpustakaan' "$COMPOSE_FILE" >/dev/null && echo "yes" || echo "no")
    VOL_OK=$(grep -E '\./data:/var/lib/mysql' "$COMPOSE_FILE" >/dev/null && echo "yes" || echo "no")

    if [ "$MARIADB_SERVICE" = "yes" ] && [ "$PMA_SERVICE" = "yes" ] && [ "$DB_NAME_OK" = "yes" ] && [ "$VOL_OK" = "yes" ]; then
        pass_check 20
    else
        REASON=""
        [ "$MARIADB_SERVICE" = "no" ] && REASON="Service 'mariadb' tidak ditemukan. "
        [ "$PMA_SERVICE" = "no" ] && REASON="${REASON}Service 'phpmyadmin' tidak ditemukan. "
        [ "$DB_NAME_OK" = "no" ] && REASON="${REASON}MYSQL_DATABASE 'perpustakaan' tidak sesuai. "
        [ "$VOL_OK" = "no" ] && REASON="${REASON}Volume mount './data:/var/lib/mysql' tidak sesuai."
        fail_check "$REASON"
    fi
else
    fail_check "Berkas $COMPOSE_FILE tidak dapat dibaca."
fi

# 3. CEK STATUS CONTAINER BERJALAN (20 Pts)
echo -n "Step 3: Memeriksa Status Container (mariadb & phpmyadmin) Berjalan (20 pts)..."
MARIADB_RUNNING=$(docker ps --filter "name=myapp-mariadb" --filter "status=running" -q)
[ -z "$MARIADB_RUNNING" ] && MARIADB_RUNNING=$(docker ps --filter "name=mariadb" --filter "status=running" -q)

PMA_RUNNING=$(docker ps --filter "name=myapp-phpmyadmin" --filter "status=running" -q)
[ -z "$PMA_RUNNING" ] && PMA_RUNNING=$(docker ps --filter "name=phpmyadmin" --filter "status=running" -q)

if [ -n "$MARIADB_RUNNING" ] && [ -n "$PMA_RUNNING" ]; then
    pass_check 20
else
    fail_check "Container 'mariadb' atau 'phpmyadmin' tidak dalam kondisi berjalan (Running)."
fi

# 4. CEK KONEKSI DAN KEBERADAAN TABEL BUKU DI MARIADB (20 Pts)
echo -n "Step 4: Memeriksa Database 'perpustakaan' dan Tabel 'buku' (20 pts)..."
if command -v mysql &>/dev/null; then
    QUERY_RESULT=$(mysql -h 127.0.0.1 -u root -psabarmenanti -P 3306 -e "USE perpustakaan; SHOW TABLES LIKE 'buku';" 2>/dev/null | grep -i "buku" || echo "")
else
    # Fallback via docker exec jika mysql client tidak terinstall di host
    CONTAINER_ID=$(docker ps --filter "ancestor=mariadb:latest" -q | head -n 1)
    QUERY_RESULT=$(docker exec "$CONTAINER_ID" mariadb -u root -psabarmenanti perpustakaan -e "SHOW TABLES LIKE 'buku';" 2>/dev/null | grep -i "buku" || echo "")
fi

if [ -n "$QUERY_RESULT" ]; then
    pass_check 20
else
    fail_check "Tabel 'buku' tidak ditemukan di dalam database 'perpustakaan'."
fi

# 5. CEK KELENGKAPAN ISI DATA PADA TABEL BUKU (20 Pts)
echo -n "Step 5: Memeriksa Isian Data Buku di Tabel 'buku' (20 pts)..."
if command -v mysql &>/dev/null; then
    ROW_COUNT=$(mysql -h 127.0.0.1 -u root -psabarmenanti -P 3306 -e "USE perpustakaan; SELECT COUNT(*) FROM buku WHERE kode IN ('001', '002');" -sN 2>/dev/null || echo "0")
else
    CONTAINER_ID=$(docker ps --filter "ancestor=mariadb:latest" -q | head -n 1)
    ROW_COUNT=$(docker exec "$CONTAINER_ID" mariadb -u root -psabarmenanti perpustakaan -e "SELECT COUNT(*) FROM buku WHERE kode IN ('001', '002');" -sN 2>/dev/null || echo "0")
fi

if [ "$ROW_COUNT" -eq 2 ]; then
    pass_check 20
else
    fail_check "Data buku dengan kode '001' dan '002' tidak lengkap/tidak ditemukan (Ditemukan: $ROW_COUNT/2 baris)."
fi

# Limit Max Score 100
[ "$score" -gt 100 ] && score=100

echo
echo "================================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Total Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Total Score: $score/100\e[0m"
    status="FAIL"
fi
echo "================================================="

# Menulis Luaran JSON untuk Sistem Scoring Lab
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-docker-compose-mariadb-pma-ch69",
  "score": $score,
  "status": "$status"
}
EOF
