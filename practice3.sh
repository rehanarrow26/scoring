#!/bin/bash

SCORE=0
DIR_TARGET="/var/www/project-x"
FILE_APP="/var/www/project-x/app.js"
FILE_CONF="/var/www/project-x/database.conf"

echo "=== AUDIT SYSTEM: TIPE 3 (HOTS CHALLENGE) ==="

# Validasi Keberadaan Struktur
if [ ! -d "$DIR_TARGET" ] || [ ! -f "$FILE_APP" ] || [ ! -f "$FILE_CONF" ]; then
    echo "❌ Error: Struktur folder/file project-x belum lengkap atau terhapus!"
    echo "Skor Akhir: 0 / 100"
    exit 1
fi

echo "Memulai uji penetrasi hak akses..."

# --- AUDIT MASALAH 1: FOLDER UTAMA (Pintu Gerbang) ---
# Uji apakah dodi_intern terblokir total dari folder utama
su dodi_intern -c "cd $DIR_TARGET" &> /dev/null
INTERN_BLOCKED=$?

# Uji apakah siti_qa bisa masuk folder utama
su siti_qa -c "cd $DIR_TARGET && ls" &> /dev/null
QA_CAN_ENTER=$?

if [ $INTERN_BLOCKED -ne 0 ] && [ $QA_CAN_ENTER -eq 0 ]; then
    echo "✅ [Masalah 1] Hak akses gerbang folder utama sempurna! (+30 Poin)"
    SCORE=$((SCORE + 30))
else
    echo "❌ [Masalah 1] Hak akses folder utama gagal. Intern bocor atau QA tidak bisa masuk."
fi


# --- AUDIT MASALAH 2: BERKAS APLIKASI (app.js) ---
# Uji apakah eko_dev bisa menulis ke app.js
su eko_dev -c "echo 'console.log(1);' >> $FILE_APP" &> /dev/null
DEV_WRITE=$?

# Uji apakah siti_qa bisa membaca app.js
su siti_qa -c "cat $FILE_APP" &> /dev/null
QA_READ=$?

# Uji apakah siti_qa terikat agar TIDAK BISA menulis ke app.js
su siti_qa -c "echo 'hack' >> $FILE_APP" &> /dev/null
QA_WRITE=$?

if [ $DEV_WRITE -eq 0 ] && [ $QA_READ -eq 0 ] && [ $QA_WRITE -ne 0 ]; then
    echo "✅ [Masalah 2] Kolaborasi aman pada berkas 'app.js' berhasil dikonfigurasi! (+40 Poin)"
    SCORE=$((SCORE + 40))
else
    echo "❌ [Masalah 2] Berkas 'app.js' gagal. Pastikan QA hanya memiliki akses read/execute saja."
fi


# --- AUDIT MASALAH 3: PROTEKSI KREDENSIAL (database.conf) ---
# Uji apakah eko_dev bisa membaca file rahasia
su eko_dev -c "cat $FILE_CONF" &> /dev/null
DEV_CONF=$?

# Uji apakah siti_qa terblokir dari file rahasia
su siti_qa -c "cat $FILE_CONF" &> /dev/null
QA_CONF=$?

if [ $DEV_CONF -eq 0 ] && [ $QA_CONF -ne 0 ]; then
    echo "✅ [Masalah 3] Isolasi berkas sensitif 'database.conf' sukses (+30 Poin)"
    SCORE=$((SCORE + 30))
else
    echo "❌ [Masalah 3] Kebocoran data! Berkas 'database.conf' masih bisa diintip oleh QA/Intern."
fi

echo "----------------------------------------"
echo "TOTAL SKOR SISWA: $SCORE / 100"
echo "========================================"
