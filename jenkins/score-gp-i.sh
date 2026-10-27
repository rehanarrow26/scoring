#!/bin/bash
# ================================================================
# AUTOMATED GRADER: JENKSIN DEVOPS & DOCKER SETUP (LAB 78)
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
echo "  GRADER: JENKINS DEVOPS & DOCKER SETUP (LAB 78)"
echo "================================================="
echo

# 1. CEK HOSTNAME SERVER (20 Pts)
echo -n "Step 1: Memeriksa Hostname Server ('jenkins-server') (20 pts)..."
CURRENT_HOSTNAME=$(hostname)

if [ "$CURRENT_HOSTNAME" = "jenkins-server" ]; then
    pass_check 20
else
    fail_check "Hostname server saat ini adalah '$CURRENT_HOSTNAME' (seharusnya 'jenkins-server')."
fi

# 2. CEK STATUS SERVICE DOCKER & CONTAINER DOCKER-IN-DOCKER (25 Pts)
echo -n "Step 2: Memeriksa Docker Daemon & Container 'jenkins-docker' (25 pts)..."
DOCKER_ACTIVE=$(systemctl is-active --quiet docker && echo "yes" || echo "no")
DIND_RUNNING=$(docker inspect -f '{{.State.Running}}' jenkins-docker 2>/dev/null || echo "false")

if [ "$DOCKER_ACTIVE" = "yes" ] && [ "$DIND_RUNNING" = "true" ]; then
    pass_check 25
else
    fail_check "Layanan Docker belum aktif atau container 'jenkins-docker' tidak berjalan."
fi

# 3. CEK IMAGE KUSTOM JENKINS & CONTAINER JENKINS BERJALAN (35 Pts)
echo -n "Step 3: Memeriksa Image Kustom 'myjenkins' & Container 'jenkins' (Port 8080) (35 pts)..."
IMAGE_EXISTS=$(docker images -q myjenkins 2>/dev/null)
JENKINS_RUNNING=$(docker inspect -f '{{.State.Running}}' jenkins 2>/dev/null || echo "false")
JENKINS_PORT=$(ss -tlnp 2>/dev/null | grep -q ":8080" && echo "yes" || echo "no")

if [ -n "$IMAGE_EXISTS" ] && [ "$JENKINS_RUNNING" = "true" ] && [ "$JENKINS_PORT" = "yes" ]; then
    pass_check 35
else
    REASON=""
    [ -z "$IMAGE_EXISTS" ] && REASON="Image kustom 'myjenkins' belum dibangun. "
    [ "$JENKINS_RUNNING" = "false" ] && REASON="${REASON}Container 'jenkins' tidak berjalan. "
    [ "$JENKINS_PORT" = "no" ] && REASON="${REASON}Port 8080 tidak terbuka untuk Jenkins."
    fail_check "$REASON"
fi

# 4. CEK INTEGRASI JENKINS DENGAN DOCKER CLI (20 Pts)
echo -n "Step 4: Memeriksa Konektivitas Docker CLI di dalam Container Jenkins (20 pts)..."
CLI_VERSION_CHECK=$(docker exec jenkins docker version 2>/dev/null | grep -i "Server" || echo "")

if [ -n "$CLI_VERSION_CHECK" ]; then
    pass_check 20
else
    fail_check "Jenkins gagal berkomunikasi dengan Docker daemon (pastikan variabel DOCKER_HOST dan TLS terpasang benar)."
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
  "chapter_id": "lab-jenkins-docker-setup-ch78",
  "score": $score,
  "status": "$status"
}
EOF
