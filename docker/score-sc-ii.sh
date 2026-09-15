#!/bin/bash
# ================================================================
# SCORING SCRIPT: DOCKER NETWORK GUIDED PRACTICE (CHAPTER 31)
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
echo "  GRADER: DOCKER NETWORK GUIDED PRACTICE (CH 31) "
echo "================================================="
echo

# ------------------------------------------------------------------
# 1. STUDI KASUS 1: CONTAINER NODE-FINANCE & NODE-PERPUS ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Case 1: Containers 'node-finance' & 'node-perpus' exist (20 pts)..."
HAS_FINANCE=$(docker ps -a --format '{{.Names}}' | grep -q "^node-finance$" && echo "true" || echo "false")
HAS_PERPUS=$(docker ps -a --format '{{.Names}}' | grep -q "^node-perpus$" && echo "true" || echo "false")

if [ "$HAS_FINANCE" = "true" ] && [ "$HAS_PERPUS" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'node-finance' atau 'node-perpus' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 2. STUDI KASUS 2: CONTAINER WEB-APP & DB-APP ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Case 2: Containers 'web-app' & 'db-app' exist (20 pts)..."
HAS_WEB=$(docker ps -a --format '{{.Names}}' | grep -q "^web-app$" && echo "true" || echo "false")
HAS_DB=$(docker ps -a --format '{{.Names}}' | grep -q "^db-app$" && echo "true" || echo "false")

if [ "$HAS_WEB" = "true" ] && [ "$HAS_DB" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'web-app' atau 'db-app' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 3. STUDI KASUS 3: CONTAINER APP-LEGACY & NETWORK NET-MONITORING ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Case 3: Container 'app-legacy' & Network 'net-monitoring' exist (20 pts)..."
HAS_LEGACY=$(docker ps -a --format '{{.Names}}' | grep -q "^app-legacy$" && echo "true" || echo "false")
HAS_MON_NET=$(docker network ls --format '{{.Name}}' | grep -q "^net-monitoring$" && echo "true" || echo "false")

if [ "$HAS_LEGACY" = "true" ] && [ "$HAS_MON_NET" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'app-legacy' atau network 'net-monitoring' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 4. STUDI KASUS 4: CONTAINER NODE-SUBNET & NETWORK NET-CUSTOM-SUBNET ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Case 4: Container 'node-subnet' & Network 'net-custom-subnet' exist (20 pts)..."
HAS_NODE_SUBNET=$(docker ps -a --format '{{.Names}}' | grep -q "^node-subnet$" && echo "true" || echo "false")
HAS_CUSTOM_NET=$(docker network ls --format '{{.Name}}' | grep -q "^net-custom-subnet$" && echo "true" || echo "false")

if [ "$HAS_NODE_SUBNET" = "true" ] && [ "$HAS_CUSTOM_NET" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'node-subnet' atau network 'net-custom-subnet' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 5. STUDI KASUS 5: CONTAINER BACKEND-1, BACKEND-2, & FRONTEND-APP ADA (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Checking Case 5: Containers 'backend-1', 'backend-2' & 'frontend-app' exist (20 pts)..."
HAS_B1=$(docker ps -a --format '{{.Names}}' | grep -q "^backend-1$" && echo "true" || echo "false")
HAS_B2=$(docker ps -a --format '{{.Names}}' | grep -q "^backend-2$" && echo "true" || echo "false")
HAS_FRONT=$(docker ps -a --format '{{.Names}}' | grep -q "^frontend-app$" && echo "true" || echo "false")

if [ "$HAS_B1" = "true" ] && [ "$HAS_B2" = "true" ] && [ "$HAS_FRONT" = "true" ]; then
    pass_check 20
else
    fail_check "Container 'backend-1', 'backend-2', atau 'frontend-app' tidak ditemukan."
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

mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "chapter-31-docker-network-gp",
  "score": $score,
  "status": "$status"
}
EOF
