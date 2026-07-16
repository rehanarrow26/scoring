#!/bin/bash

# Inisialisasi Nilai
SCORE=0
TOTAL_TESTS=3
TARGET_FILE="/tmp/ujian/soal_rahasia.txt"

echo "=== AUDIT SYSTEM: TIPE 1 (GUIDED PRACTICE) ==="

# Cek apakah file ada
if [ ! -f "$TARGET_FILE" ]; then
    echo "❌ Error: File $TARGET_FILE tidak ditemukan!"
    echo "Skor Akhir: 0 / 100"
    exit 1
fi

# Test 1: Cek Kepemilikan (Owner harus gurubaru)
OWNER=$(stat -c '%U' "$TARGET_FILE")
if [ "$OWNER" == "gurubaru" ]; then
    echo "✅ [Test 1/3] Owner file adalah 'gurubaru' (+35 Poin)"
    SCORE=$((SCORE + 35))
else
    echo "❌ [Test 1/3] Owner file salah. Saat ini: '$OWNER', seharusnya: 'gurubaru'"
fi

# Test 2: Cek Mask Hak Akses (Harus 640 atau -rw-r-----)
PERM_NUMERIC=$(stat -c '%a' "$TARGET_FILE")
if [ "$PERM_NUMERIC" == "640" ]; then
    echo "✅ [Test 2/3] Hak akses file adalah 640 / -rw-r----- (+35 Poin)"
    SCORE=$((SCORE + 35))
else
    echo "❌ [Test 2/3] Hak akses salah. Saat ini: '$PERM_NUMERIC', seharusnya: '640'"
fi

# Test 3: Uji Penetrasi Akses Siswa (Harus Terblokir)
su siswa -c "cat $TARGET_FILE" &> /dev/null
if [ $? -ne 0 ]; then
    echo "✅ [Test 3/3] User 'siswa' sukses terblokir dari file (+30 Poin)"
    SCORE=$((SCORE + 30))
else
    echo "❌ [Test 3/3] Keamanan Bocor! User 'siswa' masih bisa membaca file."
fi

echo "----------------------------------------"
echo "TOTAL SKOR SISWA: $SCORE / 100"
echo "========================================"
