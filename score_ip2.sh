#!/bin/bash

clear

score=0
CFG="/etc/network/interfaces"

echo "================================================="
echo "        Linux Networking Practice Checker"
echo "================================================="
echo

##############################################
# CHECK DHCP
##############################################

check_dhcp(){

ALIAS=$1

if grep -Eq "^iface .*:${ALIAS} inet dhcp" "$CFG"
then
    echo "[PASS] Virtual Interface :$ALIAS DHCP"
    score=$((score+10))
else
    echo "[FAIL] Virtual Interface :$ALIAS DHCP"
fi

}

##############################################
# CHECK STATIC
##############################################

check_static(){

ALIAS=$1
IP=$2

if grep -Eq "^iface .*:${ALIAS} inet static" "$CFG"
then

    if grep -A3 -E "^iface .*:${ALIAS} inet static" "$CFG" | grep -q "address $IP"
    then
        echo "[PASS] Virtual Interface :$ALIAS Static ($IP)"
        score=$((score+20))
    else
        echo "[FAIL] Virtual Interface :$ALIAS IP Salah"
    fi

else

    echo "[FAIL] Virtual Interface :$ALIAS Bukan Static"

fi

}

##############################################
# CHECKING
##############################################

check_dhcp 10
check_static 11 "192.168.50.10"
check_dhcp 12
check_static 13 "10.10.10.13"
check_static 14 "172.16.100.14"

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

Congratulations!

You have successfully completed
the LOTS Practice.

Reward:
+150 XP

Next Mission:
HOTS Practice

EOF

else

echo "Mission Status : INCOMPLETE"

echo
echo "Hint:"
echo "- Periksa kembali file /etc/network/interfaces."
echo "- Pastikan :10 dan :12 menggunakan DHCP."
echo "- Pastikan :11, :13 dan :14 menggunakan Static."
echo "- Pastikan alamat IP sesuai requirement."

fi
