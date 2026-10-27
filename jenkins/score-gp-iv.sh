#!/bin/bash
# ================================================================
# AUTOMATED GRADER: REGISTRY LOKAL & STAGE PUSH TO REGISTRY (LAB 81)
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
echo "  GRADER: REGISTRY LOKAL & PUSH STAGE (LAB 81)"
echo "================================================="
echo

# 1. CEK STATUS CONTAINER REGISTRY & PORT 5000 DI SERVER APLIKASI (25 Pts)
echo -n "Step 1: Memeriksa container 'registry' aktif dan port 5000 terbuka (25 pts)..."
REG_ACTIVE=$(docker inspect -f '{{.State.Running}}' registry 2>/dev/null || echo "false")
REG_PORT=$(ss -tlnp 2>/dev/null | grep -q ":5000" && echo "yes" || echo "no")

if [ "$REG_ACTIVE" = "true" ] && [ "$REG_PORT" = "yes" ]; then
    pass_check 25
else
    fail_check "Container 'registry' tidak berjalan atau port 5000 tidak terbuka di server aplikasi."
fi

# 2. CEK KATALOG REPOSITORY DI REGISTRY LOKAL (25 Pts)
echo -n "Step 2: Memeriksa katalog repository 'simple-app' pada registry lokal (25 pts)..."
CATALOG_RESPONSE=$(curl -s http://localhost:5000/v2/_catalog || echo "")
HAS_SIMPLE_APP=$(echo "$CATALOG_RESPONSE" | grep -qw "simple-app" && echo "yes" || echo "no")

if [ "$HAS_SIMPLE_APP" = "yes" ]; then
    pass_check 25
else
    fail_check "Repository 'simple-app' belum ditemukan di dalam katalog registry (respon: $CATALOG_RESPONSE)."
fi

# 3. CEK TAG IMAGE 'simple-app' DI REGISTRY LOKAL (35 Pts)
echo -n "Step 3: Memeriksa tag 'latest' dan tag build pada image di registry lokal (35 pts)..."
TAGS_RESPONSE=$(curl -s http://localhost:5000/v2/simple-app/tags/list || echo "")
HAS_LATEST=$(echo "$TAGS_RESPONSE" | grep -qw "latest" && echo "yes" || echo "no")
# Periksa apakah ada tag berupa angka (build number)
HAS_BUILD_NUM=$(echo "$TAGS_RESPONSE" | grep -qE '"tags":\[.*[0-9]+.*\]' && echo "yes" || echo "no")

if [ "$HAS_LATEST" = "yes" ] && [ "$HAS_BUILD_NUM" = "yes" ]; then
    pass_check 35
else
    fail_check "Tag 'latest' atau tag nomor build belum ditemukan di registry (respon: $TAGS_RESPONSE)."
fi

# 4. CEK INTEGRITAS VOLUME REGISTRY (15 Pts)
echo -n "Step 4: Memeriksa penggunaan volume data pada registry (15 pts)..."
VOL_CHECK=$(docker inspect registry --format '{{range .Mounts}}{{.Name}}{{end}}' 2>/dev/null || echo "")

if [ -n "$VOL_CHECK" ]; then
    pass_check 15
else
    fail_check "Container registry tidak menggunakan volume persisten yang sesuai."
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
  "chapter_id": "lab-jenkins-pipeline-push-registry-ch81",
  "score": $score,
  "status": "$status"
}
EOF
