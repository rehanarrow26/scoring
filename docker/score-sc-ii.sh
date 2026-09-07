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
# 1. STUDI KASUS 1: ISOLASI NETWORK (20 POIN)
# ------------------------------------------------------------------
echo -n "1. Checking Case 1: Network Isolation (20 pts)........."
FIN_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' node-finance 2>/dev/null || echo "")
PER_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' node-perpus 2>/dev/null || echo "")

if [ "$FIN_NET" == "net-finance" ] && [ "$PER_NET" == "net-perpus" ]; then
    pass_check 20
else
    fail_check "Container 'node-finance' atau 'node-perpus' tidak terhubung ke network terisolasi masing-masing."
fi

# ------------------------------------------------------------------
# 2. STUDI KASUS 2: KOMUNIKASI APP STACK (20 POIN)
# ------------------------------------------------------------------
echo -n "2. Checking Case 2: Web App & DB Communication (20 pts)..."
WEB_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' web-app 2>/dev/null || echo "")
DB_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' db-app 2>/dev/null || echo "")
DB_ENV=$(docker inspect -f '{{range .Config.Env}}{{if eq . "MARIADB_ROOT_PASSWORD=AppStack2026!"}}OK{{end}}{{end}}' db-app 2>/dev/null || echo "")

if [ "$WEB_NET" == "net-app-stack" ] && [ "$DB_NET" == "net-app-stack" ] && [ "$DB_ENV" == "OK" ]; then
    pass_check 20
else
    fail_check "Container 'web-app' dan 'db-app' belum terhubung ke 'net-app-stack' atau password MariaDB salah."
fi

# ------------------------------------------------------------------
# 3. STUDI KASUS 3: NETWORK CONNECT / DISCONNECT (20 POIN)
# ------------------------------------------------------------------
echo -n "3. Checking Case 3: Connect & Disconnect Status (20 pts)..."
LEGACY_NETS=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' app-legacy 2>/dev/null || echo "")
MON_NET_EXISTS=$(docker network inspect net-monitoring >/dev/null 2>&1 && echo "YES" || echo "NO")

if [[ "$LEGACY_NETS" != *"net-monitoring"* ]] && [ "$MON_NET_EXISTS" == "YES" ] && [ -n "$LEGACY_NETS" ]; then
    pass_check 20
else
    fail_check "Container 'app-legacy' masih terhubung ke 'net-monitoring' atau network 'net-monitoring' tidak ditemukan."
fi

# ------------------------------------------------------------------
# 4. STUDI KASUS 4: CUSTOM SUBNET & GATEWAY (PERBAIKAN) (20 POIN)
# ------------------------------------------------------------------
echo -n "4. Checking Case 4: Custom Subnet & Gateway (20 pts)....."
SUBNET=$(docker network inspect net-custom-subnet | grep -o '"Subnet": "[^"]*"' | cut -d'"' -f4 || echo "")
GATEWAY=$(docker network inspect net-custom-subnet | grep -o '"Gateway": "[^"]*"' | cut -d'"' -f4 || echo "")
NODE_EXISTS=$(docker ps -a --format '{{.Names}}' | grep "^node-subnet$" || echo "")

if [ "$SUBNET" == "172.28.0.0/16" ] && [ "$GATEWAY" == "172.28.0.1" ] && [ -n "$NODE_EXISTS" ]; then
    pass_check 20
else
    fail_check "Subnet (172.28.0.0/16), Gateway (172.28.0.1), atau container 'node-subnet' tidak sesuai."
fi

# ------------------------------------------------------------------
# 5. STUDI KASUS 5: NETWORK ALIAS (PERBAIKAN) (20 POIN)
# ------------------------------------------------------------------
echo -n "5. Checking Case 5: Network Alias Configuration (20 pts)..."
ALIAS1=$(docker inspect backend-1 | grep -i "api-backend" || echo "")
ALIAS2=$(docker inspect backend-2 | grep -i "api-backend" || echo "")
FRONT_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' frontend-app 2>/dev/null || echo "")

if [ -n "$ALIAS1" ] && [ -n "$ALIAS2" ] && [ "$FRONT_NET" == "net-backend" ]; then
    pass_check 20
else
    fail_check "Opsi --network-alias 'api-backend' pada backend-1/backend-2 atau network 'frontend-app' tidak sesuai."
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
