#!/bin/bash
# ================================================================
# AUTOMATED GRADER: DOCKER COMPOSE RIHLATUL APP (LAB 77)
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
echo "  GRADER: DOCKER COMPOSE RIHLATUL APP (LAB 77)"
echo "================================================="
echo

# 1. CEK KEBERADAAN BERKAS COMPOSE.YAML (25 Pts)
echo -n "Step 1: Memeriksa berkas compose.yaml di /root/rihlatul-docker-app (25 pts)..."
COMPOSE_FILE="/root/rihlatul-docker-app/compose.yaml"

if [ -f "$COMPOSE_FILE" ]; then
    # Validasi sintaks compose menggunakan docker compose config
    cd /root/rihlatul-docker-app
    if docker compose config --quiet 2>/dev/null; then
        pass_check 25
    else
        fail_check "Berkas compose.yaml ada, tetapi sintaksnya tidak valid (gagal divalidasi docker compose config)."
    fi
else
    fail_check "Berkas $COMPOSE_FILE tidak ditemukan."
fi

# 2. CEK STATUS CONTAINER DARI COMPOSE (25 Pts)
echo -n "Step 2: Memeriksa status container berjalan via docker compose (25 pts)..."
cd /root/rihlatul-docker-app
RUNNING_CONTAINERS=$(docker compose ps --status running --format "{{.Service}}" 2>/dev/null || echo "")

HAS_MYSQL=$(echo "$RUNNING_CONTAINERS" | grep -qw "rihlatul-mysql" && echo "yes" || echo "no")
HAS_BE=$(echo "$RUNNING_CONTAINERS" | grep -qw "rihlatul-be" && echo "yes" || echo "no")
HAS_FE=$(echo "$RUNNING_CONTAINERS" | grep -qw "rihlatul-fe" && echo "yes" || echo "no")

if [ "$HAS_MYSQL" = "yes" ] && [ "$HAS_BE" = "yes" ] && [ "$HAS_FE" = "yes" ]; then
    pass_check 25
else
    fail_check "Tidak semua service (rihlatul-mysql, rihlatul-be, rihlatul-fe) berjalan aktif."
fi

# 3. CEK KESEHATAN (HEALTH) SERVICE (25 Pts)
echo -n "Step 3: Memeriksa kesehatan (health status) container (25 pts)..."
# Periksa apakah service mendeteksi sehat (healthy) atau running
MYSQL_HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-health{{end}}' rihlatul-mysql-1 rihlatul_rihlatul-mysql-1 rihlatul-rihlatul-mysql-1 2>/dev/null | grep -m1 "healthy" || echo "")
BE_HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-health{{end}}' rihlatul-be-1 rihlatul_rihlatul-be-1 rihlatul-rihlatul-be-1 2>/dev/null | grep -m1 "healthy" || echo "")

if [ -n "$MYSQL_HEALTH" ] && [ -n "$BE_HEALTH" ]; then
    pass_check 25
else
    # Cek alternatif nama container standar compose project name
    ALT_CHECK=$(docker compose ps --format "{{.Status}}" 2>/dev/null | grep -i "healthy" | wc -l)
    if [ "$ALT_CHECK" -ge 2 ]; then
        pass_check 25
    else
        fail_check "Container belum mencapai status 'healthy' secara sempurna."
    fi
fi

# 4. CEK AKSES KELAYAKAN PORT / BACKEND API (25 Pts)
echo -n "Step 4: Memeriksa respons API Backend pada port 5002 (25 pts)..."
BE_RESPONSE=$(curl -s http://localhost:5002 || echo "")

if [ -n "$BE_RESPONSE" ]; then
    pass_check 25
else
    fail_check "Backend API pada http://localhost:5002 tidak merespons."
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
  "chapter_id": "lab-docker-compose-rihlatul-ch77",
  "score": $score,
  "status": "$status"
}
EOF
