#!/bin/bash
# ================================================================
# AUTOMATED GRADER: PIPELINE STAGE BUILD IMAGE (LAB 80)
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
echo "  GRADER: PIPELINE STAGE BUILD IMAGE (LAB 80)"
echo "================================================="
echo

# 1. CEK KEBERADAAN WORKSPACE & BERHASIL CHECKOUT/BUILD (30 Pts)
echo -n "Step 1: Memeriksa keberadaan workspace job & status sukses build (30 pts)..."
WS_DIR="/var/jenkins_home/workspace/simple-app-pipeline"
WS_CHECK=$(docker exec jenkins bash -c "test -f $WS_DIR/Dockerfile && test -f $WS_DIR/Jenkinsfile && test -f $WS_DIR/.dockerignore" && echo "yes" || echo "no")

if [ "$WS_CHECK" = "yes" ]; then
    pass_check 30
else
    fail_check "Berkas Dockerfile, .dockerignore, atau Jenkinsfile tidak lengkap di workspace."
fi

# 2. CEK APAKAH DOCKER DAEMON TERHUBUNG & DAPAT DIAKSES DARI JENKINS (25 Pts)
echo -n "Step 2: Memeriksa konektivitas Docker CLI dari dalam container Jenkins (25 pts)..."
DOCKER_CLI_CHECK=$(docker exec jenkins docker version 2>/dev/null | grep -i "Server" || echo "")

if [ -n "$DOCKER_CLI_CHECK" ]; then
    pass_check 25
else
    fail_check "Container Jenkins gagal terhubung ke Docker daemon (jenkins-docker)."
fi

# 3. CEK KEBERADAAN IMAGE 'simple-app' DI JENKINS-DOCKER (30 Pts)
echo -n "Step 3: Memeriksa keberadaan image Docker 'simple-app' (30 pts)..."
IMAGE_EXISTS=$(docker exec jenkins-docker docker images simple-app --format "{{.Repository}}" 2>/dev/null | grep -qw "simple-app" && echo "yes" || echo "no")

if [ "$IMAGE_EXISTS" = "yes" ]; then
    pass_check 30
else
    fail_check "Image Docker 'simple-app' belum ditemukan di dalam container jenkins-docker (pastikan tahap Build Image sudah dijalankan)."
fi

# 4. CEK APAKAH CONTAINER JENKINS & DOCKER-IN-DOCKER AKTIF (15 Pts)
echo -n "Step 4: Memeriksa layanan container Jenkins & jenkins-docker aktif (15 pts)..."
JENKINS_ACTIVE=$(docker inspect -f '{{.State.Running}}' jenkins 2>/dev/null || echo "false")
DIND_ACTIVE=$(docker inspect -f '{{.State.Running}}' jenkins-docker 2>/dev/null || echo "false")

if [ "$JENKINS_ACTIVE" = "true" ] && [ "$DIND_ACTIVE" = "true" ]; then
    pass_check 15
else
    fail_check "Container 'jenkins' atau 'jenkins-docker' tidak berjalan."
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
  "chapter_id": "lab-jenkins-pipeline-build-image-ch80",
  "score": $score,
  "status": "$status"
}
EOF
