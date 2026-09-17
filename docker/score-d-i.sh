#!/bin/bash
# ================================================================
# AUTOMATED GRADER: CHAPTER 54 (RIHLATUL DOCKER APP)
# Total Max Score: 100 Pts
# ================================================================

clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"
APP_DIR="/root/rihlatul-docker-app"

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
echo "  GRADER: CHAPTER 54 (RIHLATUL DOCKER APP)"
echo "================================================="
echo

# 1. CEK STRUKTUR FOLDER DAN DOCKERFILE (25 POIN)
echo -n "Step 1: Memeriksa struktur folder dan keberadaan Dockerfile (25 pts)..."
if [ -f "$APP_DIR/db/Dockerfile" ] && [ -f "$APP_DIR/be/Dockerfile" ] && [ -f "$APP_DIR/fe/Dockerfile" ]; then
    HAS_VOL=$(grep -E "^\s*VOLUME" "$APP_DIR/db/Dockerfile" || echo "")
    HAS_HC_DB=$(grep -E "^\s*HEALTHCHECK" "$APP_DIR/db/Dockerfile" || echo "")
    HAS_STAGE_BE=$(grep -E "^\s*FROM.*AS" "$APP_DIR/be/Dockerfile" || echo "")
    HAS_STAGE_FE=$(grep -E "^\s*FROM.*AS" "$APP_DIR/fe/Dockerfile" || echo "")

    if [ -n "$HAS_VOL" ] && [ -n "$HAS_HC_DB" ] && [ -n "$HAS_STAGE_BE" ] && [ -n "$HAS_STAGE_FE" ]; then
        pass_check 25
    else
        fail_check "Dockerfile db, be, atau fe belum menerapkan VOLUME, HEALTHCHECK, atau Multi-stage build dengan benar."
    fi
else
    fail_check "Berkas Dockerfile di fe, be, atau db tidak ditemukan di $APP_DIR."
fi

# 2. CEK STATUS CONTAINER MYSQL & HEALTHCHECK (25 POIN)
echo -n "Step 2: Memeriksa status container rihlatul-mysql (25 pts)..."
DB_RUNNING=$(docker ps --filter "name=rihlatul-mysql" --filter "status=running" -q)

if [ -n "$DB_RUNNING" ]; then
    DB_HEALTH=$(docker inspect rihlatul-mysql --format '{{.State.Health.Status}}' 2>/dev/null || echo "")
    if [ "$DB_HEALTH" = "healthy" ] || [ "$DB_HEALTH" = "starting" ]; then
        pass_check 25
    else
        fail_check "Container rihlatul-mysql tidak dalam kondisi healthy (Status: '$DB_HEALTH')."
    fi
else
    fail_check "Container rihlatul-mysql tidak sedang berjalan."
fi

# 3. CEK STATUS CONTAINER BACKEND & RESPONS API (25 POIN)
echo -n "Step 3: Memeriksa container rihlatul-be dan endpoint API 5002 (25 pts)..."
BE_RUNNING=$(docker ps --filter "name=rihlatul-be" --filter "status=running" -q)

if [ -n "$BE_RUNNING" ]; then
    BE_RESP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5002 || echo "000")
    if [ "$BE_RESP" -ne "000" ]; then
        pass_check 25
    else
        fail_check "Container rihlatul-be tidak merespons request di port 5002 (HTTP Status: $BE_RESP)."
    fi
else
    fail_check "Container rihlatul-be tidak sedang berjalan."
fi

# 4. CEK STATUS CONTAINER FRONTEND & RESPONS WEB (25 POIN)
echo -n "Step 4: Memeriksa container rihlatul-fe dan respons web 5555 (25 pts)..."
FE_RUNNING=$(docker ps --filter "name=rihlatul-fe" --filter "status=running" -q)

if [ -n "$FE_RUNNING" ]; then
    FE_RESP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5555 || echo "000")
    if [ "$FE_RESP" -eq 200 ] || [ "$FE_RESP" -eq 304 ] || [ "$FE_RESP" -eq 302 ]; then
        pass_check 25
    else
        fail_check "Container rihlatul-fe merespons dengan HTTP Status: $FE_RESP (Ekspektasi: 200/302/304)."
    fi
else
    fail_check "Container rihlatul-fe tidak sedang berjalan."
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
  "chapter_id": "lab-docker-rihlatul-ch54",
  "score": $score,
  "status": "$status"
}
EOF
