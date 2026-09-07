#!/bin/bash
# ================================================================
# GRADER: DOCKER NETWORK MANAGEMENT (LANGKAH 1-6 REAL-TIME)
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
echo "  GRADER: MANAJEMEN DOCKER NETWORK (STEP 1-6)    "
echo "================================================="
echo

# 1. Cek Docker Daemon Active (20 Poin)
echo -n "1. Checking Docker Service Status (20 pts)............."
if systemctl is-active --quiet docker || docker info >/dev/null 2>&1; then
    pass_check 20
else
    fail_check "Docker daemon tidak aktif atau belum berjalan."
fi

# 2. Cek Keberadaan Network 'belajar' & Driver 'bridge' (20 Poin)
echo -n "2. Checking Docker Network 'belajar' (20 pts).........."
NET_DRIVER=$(docker network inspect belajar -f '{{.Driver}}' 2>/dev/null || echo "")
if [ "$NET_DRIVER" == "bridge" ]; then
    pass_check 20
else
    fail_check "Docker network 'belajar' bertipe 'bridge' tidak ditemukan."
fi

# 3. Cek Status Running Container 'mariadb' (20 Poin)
echo -n "3. Checking Container 'mariadb' Running Status (20 pts)..."
CONTAINER_RUNNING=$(docker inspect -f '{{.State.Running}}' mariadb 2>/dev/null || echo "false")
if [ "$CONTAINER_RUNNING" == "true" ]; then
    pass_check 20
else
    fail_check "Container 'mariadb' tidak ditemukan atau tidak dalam status running (Up)."
fi

# 4. Cek Keterhubungan Container ke Network 'belajar' (20 Poin)
echo -n "4. Checking Container Network Attachment (20 pts)......"
ATTACHED_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' mariadb 2>/dev/null || echo "")
if [[ "$ATTACHED_NET" == *"belajar"* ]]; then
    pass_check 20
else
    fail_check "Container 'mariadb' tidak terhubung ke network 'belajar'."
fi

# 5. Cek Port Binding (3306) & Environment Password (20 Poin)
echo -n "5. Checking Port Binding & ENV Variables (20 pts)..."
PORT_BOUND=$(docker inspect -f '{{(index (index .HostConfig.PortBindings "3306/tcp") 0).HostPort}}' mariadb 2>/dev/null || echo "")
ENV_PASS=$(docker inspect -f '{{range .Config.Env}}{{if eq . "MARIADB_ROOT_PASSWORD=sabarmenanti"}}OK{{end}}{{end}}' mariadb 2>/dev/null || echo "")

if [ "$PORT_BOUND" == "3306" ] && [ "$ENV_PASS" == "OK" ]; then
    pass_check 20
else
    fail_check "Port binding host 3306:3306 atau ENV 'MARIADB_ROOT_PASSWORD=sabarmenanti' tidak sesuai."
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

# simpan hasil penilaian untuk LMS
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "docker-network-management",
  "score": $score,
  "status": "$status"
}
EOF
