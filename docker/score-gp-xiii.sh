#!/bin/bash
# ================================================================
# CLEANUP SCRIPT: RESET CHAPTER 52 ENVIRONMENT
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"
TARGET_DIR="/root/images"

echo "[1/4] Menghentikan dan menghapus container sisa uji coba..."
if docker ps -a --format '{{.Names}}' | grep -q "^web-nonroot$"; then
    docker stop web-nonroot 2>/dev/null || true
    docker rm web-nonroot 2>/dev/null || true
    echo "      └─> Container web-nonroot dihapus."
fi

echo "[2/4] Menghapus docker image sederhana:latest..."
docker rmi sederhana:latest 2>/dev/null || true

echo "[3/4] Menghapus Dockerfile pada $TARGET_DIR..."
if [ -d "$TARGET_DIR" ]; then
    rm -f "$TARGET_DIR/Dockerfile"
fi

echo "[4/4] Membersihkan result.json..."
if [ -f "$RESULT_FILE" ]; then
    rm -f "$RESULT_FILE"
    echo "      └─> result.json dihapus."
fi

echo "------------------------------------------------"
echo " Cleanup Chapter 52 Selesai!"
echo "------------------------------------------------"
