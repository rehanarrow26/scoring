#!/bin/bash

clear

score=0

echo "================================================="
echo "        Linux Networking Practice Checker"
echo "================================================="
echo

##############################################
# CHECKING
##############################################

CFG="/etc/network/interfaces"

# 1. Jumlah Virtual Interface (40)
count=$(grep -Ec "^iface .*:[0-9]+ inet" "$CFG")

if [ "$count" -eq 5 ]
then
    echo "[PASS] 5 Virtual Interface"
    score=$((score+40))
else
    echo "[FAIL] Jumlah Virtual Interface = $count (Seharusnya 5)"
fi

# 2. Jumlah Virtual Interface DHCP (20)
dhcp=$(grep -Ec "^iface .*:[0-9]+ inet dhcp" "$CFG")

if [ "$dhcp" -eq 2 ]
then
    echo "[PASS] DHCP = 2"
    score=$((score+20))
else
    echo "[FAIL] DHCP = $dhcp (Seharusnya 2)"
fi

# 3. Jumlah Virtual Interface Static (20)
static=$(grep -Ec "^iface .*:[0-9]+ inet static" "$CFG")

if [ "$static" -eq 3 ]
then
    echo "[PASS] Static = 3"
    score=$((score+20))
else
    echo "[FAIL] Static = $static (Seharusnya 3)"
fi

# 4. Menggunakan 3 Network Berbeda (20)
network=0

grep -Eq "^address 192\.168\." "$CFG" && network=$((network+1))
grep -Eq "^address 172\.16\." "$CFG" && network=$((network+1))
grep -Eq "^address 10\." "$CFG" && network=$((network+1))

if [ "$network" -eq 3 ]
then
    echo "[PASS] Menggunakan Network 192, 172 dan 10"
    score=$((score+20))
else
    echo "[FAIL] Network belum memenuhi syarat"
fi

echo
echo "-------------------------------------------------"
echo "Score : $score / 100"
echo "-------------------------------------------------"
echo

echo "Achievements"

[ $score -ge 20 ] && echo "✔ Interface Builder"
[ $score -ge 40 ] && echo "✔ Linux Explorer"
[ $score -ge 60 ] && echo "✔ Network Planner"
[ $score -ge 80 ] && echo "✔ Linux Administrator"
[ $score -eq 100 ] && echo "★ Perfect Solution"

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
echo "- Pastikan terdapat tepat 5 virtual interface."
echo "- Pastikan hanya ada 2 virtual interface DHCP."
echo "- Pastikan hanya ada 3 virtual interface Static."
echo "- Pastikan menggunakan network 192.168.x.x, 172.16.x.x, dan 10.x.x.x."

fi
