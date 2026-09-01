#!/bin/bash
# ================================================================
# SCORING SCRIPT - CHAPTER 24: MANAJEMEN DOCKER CONTAINER
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

echo "========================================="
echo "  GRADER: CHAPTER 24 (DOCKER CONTAINER)"
echo "========================================="
echo

# 1. Cek Layanan Docker Service (20 Poin)
echo -n "Checking Docker Service Status (20 pts)................."
if systemctl is-active --quiet docker; then
    pass_check 20
else
    fail_check "Service Docker tidak aktif/running."
fi

# 2. Cek Keberadaan Container Bernama 'nginx' (25 Poin)
echo -n "Checking Container Named 'nginx' Exists (25 pts)......."
if docker inspect "nginx" >/dev/null 2>&1; then
    pass_check 25
else
    fail_check "Container dengan nama 'nginx' tidak ditemukan."
fi

# 3. Cek Status Container Harus Running (25 Poin)
echo -n "Checking Container 'nginx' Status is Running (25 pts)..."
CONTAINER_STATUS=$(docker inspect -f '{{.State.Running}}' nginx 2>/dev/null || echo "false")
if [ "$CONTAINER_STATUS" = "true" ]; then
    pass_check 25
else
    fail_check "Container 'nginx' terdeteksi tetapi tidak dalam status running (Exited/Created)."
fi

# 4. Cek Binding Port 80 Host ke Port 80 Container (15 Poin)
echo -n "Checking Port Binding 80:80 (15 pts)...................."
PORT_BINDING=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Ports}}{{(index $v 0).HostPort}}{{end}}' nginx 2>/dev/null || echo "")
if [ "$PORT_BINDING" = "80" ]; then
    pass_check 15
else
    fail_check "Port host 80 tidak dipublikasikan ke port container (pastikan menggunakan -p 80:80)."
fi

# 5. Cek Akses HTTP ke Localhost / Response Nginx (15 Poin)
echo -n "Checking Web Service Response via curl (15 pts)........."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    pass_check 15
else
    fail_check "Layanan web pada http://localhost:80 tidak mengembalikan HTTP status 200 OK."
fi

# Limit Score Maksimal 100
[ "$score" -gt 100 ] && score=100

echo
echo "========================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Score: $score/100\e[0m"
    status="FAIL"
fi
echo "========================================="

# Output JSON
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "chapter-24-docker-container",
  "score": $score,
  "status": "$status"
}
EOF
