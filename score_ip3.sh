#!/bin/bash

clear

score=0
CFG="/etc/network/interfaces"

echo "================================================="
echo "        Linux Networking Practice Checker"
echo "================================================="
echo

##############################################
# 1. Virtual Interface
##############################################

count=$(grep -Ec "^iface .*:[0-9]+ inet" "$CFG")

if [ "$count" -eq 5 ]
then
    echo "[PASS] Jumlah Virtual Interface = 5"
    score=$((score+25))
else
    echo "[FAIL] Jumlah Virtual Interface = $count (Seharusnya 5)"
fi

##############################################
# 2. DHCP
##############################################

dhcp=$(grep -Ec "^iface .*:[0-9]+ inet dhcp" "$CFG")

if [ "$dhcp" -eq 2 ]
then
    echo "[PASS] DHCP = 2"
    score=$((score+25))
else
    echo "[FAIL] DHCP = $dhcp (Seharusnya 2)"
fi

##############################################
# 3. Static
##############################################

static=$(grep -Ec "^iface .*:[0-9]+ inet static" "$CFG")

if [ "$static" -eq 3 ]
then
    echo "[PASS] Static = 3"
    score=$((score+25))
else
    echo "[FAIL] Static = $static (Seharusnya 3)"
fi

##############################################
# 4. Network
##############################################

network=0

grep -Eq "^address 192\.168\." "$CFG" && network=$((network+1))
grep -Eq "^address 172\.16\." "$CFG" && network=$((network+1))
grep -Eq "^address 10\." "$CFG" && network=$((network+1))

if [ "$network" -eq 3 ]
then
    echo "[PASS] Menggunakan Network 192.168.x.x, 172.16.x.x, dan 10.x.x.x"
    score=$((score+25))
else
    echo "[FAIL] Network belum memenuhi syarat"
fi

echo
echo "-------------------------------------------------"
echo "Score : $score / 100"
echo "-------------------------------------------------"
echo

echo "Achievements"

[ $score -ge 25 ] && echo "✔ Interface Builder"
[ $score -ge 50 ] && echo "✔ Network Explorer"
[ $score -ge 75 ] && echo "✔ Linux Administrator"
[ $score -eq 100 ] && echo "★ Linux Networking Master"

echo

case $score in
100)
    rank="A"
    title="Linux Networking Master"
    ;;
75)
    rank="B"
    title="Linux Administrator"
    ;;
50)
    rank="C"
    title="Junior Administrator"
    ;;
25)
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

Congratulations!

You have successfully completed
the HOTS Practice.

Reward:
+200 XP

EOF

else

echo "Mission Status : INCOMPLETE"

echo
echo "Hint:"
echo "- Pastikan hanya ada 5 virtual interface."
echo "- Pastikan terdapat 2 DHCP."
echo "- Pastikan terdapat 3 Static."
echo "- Pastikan menggunakan network 192.168.x.x, 172.16.x.x, dan 10.x.x.x."

fi
