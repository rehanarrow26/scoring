#!/bin/bash
# ==============================================================================
# Score Script: Lab 55 - USER - Menjalankan Container sebagai Non-Root
# Total Max Score: 100
# ==============================================================================

WORK_DIR="/root/images"
RESULT_FILE="/root/scoring/result.json"
SCORE=0

mkdir -p /root/scoring

echo "======================================================================"
echo "               EVALUASI LAB 55: USER (NON-ROOT)                      "
echo "======================================================================"

# 1. Cek keberadaan direktori dan Dockerfile (20 Poin)
if [ -f "$WORK_DIR/Dockerfile" ]; then
    echo "[PASS] Dockerfile ditemukan di $WORK_DIR (+20 Poin)"
    SCORE=$((SCORE + 20))
else
    echo "[FAIL] Dockerfile tidak ditemukan di $WORK_DIR (+0 Poin)"
fi

# 2. Cek instruksi 'USER' dan 'adduser' pada Dockerfile (30 Poin)
if [ -f "$WORK_DIR/Dockerfile" ]; then
    HAS_ADDUSER=$(grep -i "adduser" "$WORK_DIR/Dockerfile" || true)
    HAS_USER_INSTR=$(grep -i "USER" "$WORK_DIR/Dockerfile" || true)

    if [ -n "$HAS_ADDUSER" ] && [ -n "$HAS_USER_INSTR" ]; then
        echo "[PASS] Dockerfile memuat instruksi 'adduser' dan 'USER' (+30 Poin)"
        SCORE=$((SCORE + 30))
    else
        echo "[FAIL] Dockerfile belum memiliki sintaks 'adduser' atau 'USER' (+0 Poin)"
    fi
else
    echo "[SKIP] Lewati pemeriksaan sintaks Dockerfile."
fi

# 3. Pengujian eksekusi container & verifikasi user non-root (30 Poin)
IMAGE_EXISTS=$(docker images -q sederhana:latest 2>/dev/null || true)
if [ -n "$IMAGE_EXISTS" ]; then
    CONTAINER_USER=$(docker run --rm sederhana:latest whoami 2>/dev/null || echo "root")
    CONTAINER_UID=$(docker run --rm sederhana:latest id -u 2>/dev/null || echo "0")

    if [ "$CONTAINER_USER" != "root" ] && [ "$CONTAINER_UID" -ne 0 ]; then
        echo "[PASS] Container berjalan sebagai user non-root: $CONTAINER_USER (UID: $CONTAINER_UID) (+30 Poin)"
        SCORE=$((SCORE + 30))
    else
        echo "[FAIL] Container masih berjalan sebagai root (UID: $CONTAINER_UID) (+0 Poin)"
    fi
else
    echo "[FAIL] Image 'sederhana:latest' belum dibangun (+0 Poin)"
fi

# 4. Pengujian fungsionalitas aplikasi & pembatasan hak akses (20 Poin)
if [ -n "$IMAGE_EXISTS" ]; then
    # Tes akses web
    docker run -d --name test-web-55 -p 8080:8080 sederhana:latest >/dev/null 2>&1 || true
    sleep 2
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "000")
    docker stop test-web-55 >/dev/null 2>&1 || true
    docker rm test-web-55 >/dev/null 2>&1 || true

    # Tes restriksi root (apk add harus gagal untuk non-root)
    RESTRICT_CHECK=$(docker run --rm --entrypoint sh sederhana:latest -c "apk add --no-cache curl" 2>&1 || true)

    if [ "$HTTP_CODE" -eq 200 ] && echo "$RESTRICT_CHECK" | grep -qi "permission denied"; then
        echo "[PASS] Web server aktif (HTTP 200) dan hak akses root dibatasi secara efektif (+20 Poin)"
        SCORE=$((SCORE + 20))
    else
        echo "[FAIL] Pengujian fungsional/restriksi gagal (HTTP Code: $HTTP_CODE) (+0 Poin)"
    fi
else
    echo "[SKIP] Lewati pengujian fungsionalitas."
fi

echo "======================================================================"
echo "FINAL SCORE: $SCORE / 100"
echo "======================================================================"

# Menuliskan output ke result.json
cat << EOF > "$RESULT_FILE"
{
  "score": $SCORE,
  "max_score": 100,
  "lab": "Lab 55 - USER - Menjalankan Container sebagai Non-Root"
}
EOF
