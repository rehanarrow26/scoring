#!/bin/bash
clear
score=0

echo "================================================="
echo "        Linux Networking Practice Checker"
echo "================================================="
echo

interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$'))

echo "Pilih interface yang digunakan pada praktikum:"
echo
for i in "${!interfaces[@]}"; do
  echo "[$((i+1))] ${interfaces[$i]}"
done
echo
while true; do
  read -p "Masukkan nomor interface : " pilih
  if [[ "$pilih" =~ ^[0-9]+$ ]] && [ "$pilih" -ge 1 ] && [ "$pilih" -le "${#interfaces[@]}" ]; then
    BASE="${interfaces[$((pilih-1))]}"
    break
  fi
done

check_ip(){
  if ip addr show "$1" | grep -qw "$2"; then
    printf "[PASS] %-10s -> %s\n" "$1" "$2"
    score=$((score+20))
  else
    printf "[FAIL] %-10s -> %s\n" "$1" "$2"
  fi
}

echo
echo "Checking IP Address..."
check_ip "$BASE" "192.168.10.10"
check_ip "$BASE" "192.168.20.10"
check_ip "$BASE" "172.16.10.10"
check_ip "$BASE" "172.16.20.10"
check_ip "$BASE" "10.10.10.10"

echo
echo "Score : $score / 100"
