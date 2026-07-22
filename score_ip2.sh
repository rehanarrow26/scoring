#!/bin/bash
clear
score=0
CFG=/etc/network/interfaces

interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$'))
echo "Pilih interface:"
for i in "${!interfaces[@]}"; do echo "[$((i+1))] ${interfaces[$i]}"; done
read -p "Nomor: " pilih
BASE="${interfaces[$((pilih-1))]}"

check_static(){
 if ip addr show "$1" | grep -qw "$2"; then
   echo "[PASS] $2"
   score=$((score+20))
 else
   echo "[FAIL] $2"
 fi
}

check_static "$BASE" "192.168.50.10"
check_static "$BASE" "10.10.10.13"
check_static "$BASE" "172.16.100.14"

dhcp=$(grep -Ec "^iface .*:1(0|2) inet dhcp|^iface .*:(10|12) inet dhcp" "$CFG")
if [ "$dhcp" -eq 2 ]; then echo "[PASS] DHCP"; score=$((score+20)); else echo "[FAIL] DHCP"; fi

echo "Score : $score / 100"
