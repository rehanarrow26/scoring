#!/bin/bash

clear

score=0
CFG="/etc/network/interfaces"

echo "================================================="
echo "      Guided Practice Checker - IP Address"
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
    score=$((score+20))
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

check_dhcp 1
check_static 2 "192.168.10.2"
check_dhcp 3
check_static 4 "172.16.20.2"
check_dhcp 5

echo
echo "-------------------------------------------------"
echo "Score : $score / 100"
echo "-------------------------------------------------"
echo

echo "Achievements"

[ $score -ge 20 ] && echo "✔ First Interface"
[ $score -ge 40 ] && echo "✔ Interface Builder"
[ $score -ge 60 ] && echo "✔ Network Explorer"
[ $score -ge 80 ] && echo "✔ Linux Apprentice"
[ $score -eq 100 ] && echo "★ Perfect Configuration"

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
echo "- Periksa kembali file /etc/network/interfaces."
echo "- Pastikan interface :1, :3 dan :5 menggunakan DHCP."
echo "- Pastikan interface :2 dan :4 menggunakan Static."
echo "- Pastikan alamat IP sesuai dengan instruksi."

fi
