#!/bin/bash

clear

score=0

echo "================================================="
echo "        Linux Networking Practice Checker"
echo "================================================="
echo

##############################################
# PILIH INTERFACE
##############################################

interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$'))

echo "Pilih interface yang digunakan pada praktikum:"
echo

for i in "${!interfaces[@]}"
do
    echo "[$((i+1))] ${interfaces[$i]}"
done

echo

while true
do
    read -p "Masukkan nomor interface : " pilih

    if [[ "$pilih" =~ ^[0-9]+$ ]] && \
       [ "$pilih" -ge 1 ] && \
       [ "$pilih" -le "${#interfaces[@]}" ]
    then
        BASE="${interfaces[$((pilih-1))]}"
        break
    fi

    echo "Pilihan tidak valid!"
done

echo
echo "Interface dipilih : $BASE"
echo
read -p "Tekan ENTER untuk memulai pengecekan..."

##############################################
# PENGECEKAN
##############################################

check_interface() {
    if ip link show "$1" &>/dev/null
    then
        printf "[PASS] %-15s\n" "$1"
        score=$((score+20))
    else
        printf "[FAIL] %-15s\n" "$1"
    fi
}

echo
echo "Checking virtual interfaces..."
echo

check_interface "$BASE:1"
check_interface "$BASE:2"
check_interface "$BASE:3"
check_interface "$BASE:4"
check_interface "$BASE:5"

echo
echo "-------------------------------------------------"
echo "Score : $score / 100"
echo "-------------------------------------------------"
echo

echo "Achievements"

if [ $score -ge 20 ]; then
    echo "✔ First Interface"
fi

if [ $score -ge 40 ]; then
    echo "✔ Interface Builder"
fi

if [ $score -ge 60 ]; then
    echo "✔ Network Explorer"
fi

if [ $score -ge 80 ]; then
    echo "✔ Linux Apprentice"
fi

if [ $score -eq 100 ]; then
    echo "★ Perfect Configuration"
fi

echo

case $score in
100)
    rank="A"
    title="Linux Networking Master"
    ;;
80)
    rank="B"
    title="Linux Administrator"
    ;;
60)
    rank="C"
    title="Junior Administrator"
    ;;
40)
    rank="D"
    title="Linux Beginner"
    ;;
*)
    rank="E"
    title="Need More Practice"
    ;;
esac

echo "Rank  : $rank"
echo "Title : $title"

echo

if [ $score -eq 100 ]; then
cat << "EOF"
=========================================
        MISSION COMPLETE
=========================================

Congratulations!

You have successfully completed
the Guided Practice.

Reward:
+100 XP

Next Mission:
Unguided Practice (LOTS)

EOF

else

echo "Mission Status : INCOMPLETE"
echo
echo "Hint:"
echo "- Jalankan 'ip a' untuk memastikan semua virtual interface muncul."
echo "- Periksa kembali file /etc/network/interfaces."
echo "- Restart layanan networking setelah mengubah konfigurasi."

fi
