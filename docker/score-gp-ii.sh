#!/bin/bash
# ================================================================
# DOCKER IMAGE MANAGEMENT CHECKER (ROBUST VERSION)
# CHAPTER 23
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
echo "  DOCKER IMAGE MANAGEMENT CHECKER - CH 23"
echo "========================================="
echo

# 1. Cek Status Layanan Docker Daemon (20 Poin)
echo -n "Checking Docker Daemon Status......................."
if systemctl is-active --quiet docker; then
    pass_check 20
else
    fail_check "Service Docker Daemon tidak berjalan (inactive)."
fi

# 2. Cek Keberadaan Image 'hello-world' di Local Registry (20 Poin)
echo -n "Checking 'hello-world' Image Presence..............."
if docker image inspect hello-world:latest >/dev/null 2>&1 || docker image inspect hello-world >/dev/null 2>&1; then
    pass_check 20
else
    fail_check "Image 'hello-world' tidak ditemukan di local image storage."
fi

# 3. Cek Keberadaan Image 'alpine' (Hasil perintah pull) (30 Poin)
echo -n "Checking 'alpine' Image (Pull Verification)........."
if docker image inspect alpine:latest >/dev/null 2>&1 || docker image inspect alpine >/dev/null 2>&1; then
    pass_check 30
else
    fail_check "Image 'alpine' tidak ditemukan. Jalankan perintah: docker image pull alpine"
fi

# 4. Cek Tag 'latest' dari Image 'alpine' (15 Poin)
echo -n "Checking 'alpine:latest' Tag Configuration.........."
alpine_tag=$(docker image ls --format "{{.Repository}}:{{.Tag}}" | grep -E "^alpine:(latest|)$" || true)
if [ -n "$alpine_tag" ]; then
    pass_check 15
else
    fail_check "Image 'alpine' ditemukan tetapi tag bukan 'latest'."
fi

# 5. Cek Integritas Local Image CLI Query (15 Poin)
echo -n "Checking Docker Image CLI Output Consistency........"
if docker image ls --quiet >/dev/null 2>&1; then
    pass_check 15
else
    fail_check "Gagal mengeksekusi perintah 'docker image ls'."
fi

# Limit Score Max 100
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

cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": 23,
  "score": $score,
  "status": "$status"
}
EOF
