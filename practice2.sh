#!/bin/bash

SCORE=0
TARGET_FILE="/tmp/log/aktivitas.log"

echo "=== AUDIT SYSTEM: TIPE 2 (LOTS PRACTICE) ==="

if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ Error: File $TARGET_FILE tidak ditemukan!"
    echo "Skor Akhir: 0 / 100"
    exit 1
fi

# Test 1: Cek Owner Utama (Harus admin_juni)
OWNER=$(stat -c '%U' "$TARGET_FILE")
if [ "$OWNER" == "admin_juni" ]; then
    echo "✅ [Test 1/3] Owner file adalah 'admin_juni' (+30 Poin)"
    SCORE=$((SCORE + 30))
else
    echo "❌ [Test 1/3] Owner file salah. Saat ini: '$OWNER'"
fi

# Test 2: Cek Group Utama (Harus it_support)
GROUP=$(stat -c '%G' "$TARGET_FILE")
if [ "$GROUP" == "it_support" ]; then
    echo "✅ [Test 2/3] Group file adalah 'it_support' (+30 Poin)"
    SCORE=$((SCORE + 30))
else
    echo "❌ [Test 2/3] Group file salah. Saat ini: '$GROUP'"
fi

# Test 3: Cek Hak Akses Akhir (Harus 644 atau -rw-r--r--)
PERM_NUMERIC=$(stat -c '%a' "$TARGET_FILE")
if [ "$PERM_NUMERIC" == "644" ]; then
    echo "✅ [Test 3/3] Standarisasi hak akses numeric 644 tepat (+40 Poin)"
    SCORE=$((SCORE + 40))
else
    echo "❌ [Test 3/3] Hak akses salah. Saat ini: '$PERM_NUMERIC', seharusnya: '644'"
fi

echo "----------------------------------------"
echo "TOTAL SKOR SISWA: $SCORE / 100"
echo "========================================"
