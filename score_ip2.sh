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
# CHECKING
##############################################

check_ip(){

IFACE=$1
IP=$2

if ip addr show "$IFACE" 2>/dev/null | grep -q "$IP"
then
    echo "[PASS] $IFACE -> $IP"
    score=$((score+20))
else
    echo "[FAIL] $IFACE"
fi

}

check_ip "$BASE:11" "192.168.50.10"
check_ip "$BASE:13" "10.10.10.13"
check_ip "$BASE:14" "172.16.100.14"

if ip link show "$BASE:10" >/dev/null 2>&1
then
echo "[PASS] $BASE:10"
score=$((score+10))
else
echo "[FAIL] $BASE:10"
fi

if ip link show "$BASE:12" >/dev/null 2>&1
then
echo "[PASS] $BASE:12"
score=$((score+10))
else
echo "[FAIL] $BASE:12"
fi

echo
echo "-------------------------------------------------"
echo "Score : $score / 100"
echo "-------------------------------------------------"
echo

echo "Achievements"

[ $score -ge 20 ] && echo "✔ Interface Builder"
[ $score -ge 40 ] && echo "✔ DHCP Explorer"
[ $score -ge 60 ] && echo "✔ Static Explorer"
[ $score -ge 80 ] && echo "✔ Linux Apprentice"
[ $score -eq 100 ] && echo "★ Requirement Completed"

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

if [ $score -eq 100 ]
then

cat << EOF

=========================================
        MISSION COMPLETE
=========================================

Reward

+150 XP

Next Mission

Unguided Practice (HOTS)

EOF

else

echo "Mission Status : INCOMPLETE"

fi
