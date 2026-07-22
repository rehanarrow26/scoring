#!/bin/bash
clear
score=0
CFG=/etc/network/interfaces

count=$(grep -Ec "^iface .*:[0-9]+ inet" "$CFG")
[ "$count" -eq 5 ] && echo "[PASS] 5 Virtual Interface" && score=$((score+40)) || echo "[FAIL] Virtual Interface"

dhcp=$(grep -Ec "^iface .*:[0-9]+ inet dhcp" "$CFG")
[ "$dhcp" -eq 2 ] && echo "[PASS] DHCP=2" && score=$((score+20)) || echo "[FAIL] DHCP=$dhcp"

static=$(grep -Ec "^iface .*:[0-9]+ inet static" "$CFG")
[ "$static" -eq 3 ] && echo "[PASS] Static=3" && score=$((score+20)) || echo "[FAIL] Static=$static"

net=0
grep -Eq "^address 192\.168\." "$CFG" && net=$((net+1))
grep -Eq "^address 172\.16\." "$CFG" && net=$((net+1))
grep -Eq "^address 10\." "$CFG" && net=$((net+1))
[ "$net" -eq 3 ] && echo "[PASS] Network" && score=$((score+20)) || echo "[FAIL] Network"

echo "Score : $score / 100"
