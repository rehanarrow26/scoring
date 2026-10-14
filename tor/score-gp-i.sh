#!/bin/bash
# ================================================================
# AUTOMATED GRADER: MONITORING SERVER (PROMETHEUS & GRAFANA)
# Total Max Score: 100 Pts
# ================================================================

clear
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$SCRIPT_DIR/../result.json"

score=0

pass_check() {
    echo -e "\e[32m[PASS]\e[0m"
    score=$((score + $1))
}

fail_check() {
    local reason="$1"
    echo -e "\e[31m[FAIL]\e[0m"
    echo -e "    \e[33m└─> Alasan: $reason\e[0m"
}

echo "================================================="
echo "  GRADER: MONITORING SERVER (PROMETHEUS & GRAFANA)"
echo "================================================="
echo

# 1. CEK INSTALASI & STATUS PROMETHEUS (25 Pts)
echo -n "Step 1: Memeriksa Layanan Prometheus (Port 9090) (25 pts)..."
PROM_ACTIVE=$(systemctl is-active --quiet prometheus 2>/dev/null && echo "yes" || echo "no")
PROM_PORT=$(ss -tlnp 2>/dev/null | grep -q ":9090" && echo "yes" || echo "no")

if [ "$PROM_ACTIVE" = "yes" ] && [ "$PROM_PORT" = "yes" ]; then
    pass_check 25
else
    fail_check "Layanan Prometheus tidak aktif atau port 9090 tidak terbuka."
fi

# 2. CEK KONFIGURASI PROMETHEUS SCRAPE TARGETS (25 Pts)
echo -n "Step 2: Memeriksa Target Scrape Node Exporter (192.168.10.10:9100) di prometheus.yml (25 pts)..."
PROM_CONF="/etc/prometheus/prometheus.yml"

if [ -f "$PROM_CONF" ]; then
    # Validasi sintaks yaml/testparm jika ada, atau cek isi string target
    HAS_TARGET=$(grep -E '192\.168\.10\.10:9100' "$PROM_CONF" >/dev/null && echo "yes" || echo "no")
    
    if [ "$HAS_TARGET" = "yes" ]; then
        pass_check 25
    else
        fail_check "Target '192.168.10.10:9100' belum dikonfigurasi di dalam $PROM_CONF."
    fi
else
    fail_check "Berkas konfigurasi $PROM_CONF tidak ditemukan."
fi

# 3. CEK INSTALASI & STATUS GRAFANA-SERVER (25 Pts)
echo -n "Step 3: Memeriksa Layanan Grafana (Port 3000) (25 pts)..."
GRAFANA_ACTIVE=$(systemctl is-active --quiet grafana-server 2>/dev/null && echo "yes" || echo "no")
GRAFANA_PORT=$(ss -tlnp 2>/dev/null | grep -q ":3000" && echo "yes" || echo "no")

if [ "$GRAFANA_ACTIVE" = "yes" ] && [ "$GRAFANA_PORT" = "yes" ]; then
    pass_check 25
else
    fail_check "Layanan Grafana tidak aktif atau port 3000 tidak terbuka."
fi

# 4. CEK KONEKSI PROMETHEUS KE NODE EXPORTER TARGET (25 Pts)
echo -n "Step 4: Memeriksa Konektivitas Prometheus API ke Target Node Exporter (25 pts)..."
# Menguji endpoint API prometheus untuk melihat target scrape node_exporter
API_TARGET_UP=$(curl -s http://localhost:9090/api/v1/targets | grep -oi "up" | head -n 1 || echo "")

if [ -n "$API_TARGET_UP" ]; then
    pass_check 25
else
    fail_check "Prometheus belum berhasil melakukan scrape (target Node Exporter di 192.168.10.10 mungkin DOWN)."
fi

# Limit Max Score 100
[ "$score" -gt 100 ] && score=100

echo
echo "================================================="
if [ "$score" -eq 100 ]; then
    echo -e "\e[32mMISSION COMPLETE! Total Score: $score/100\e[0m"
    status="PASS"
else
    echo -e "\e[31mMISSION INCOMPLETE. Total Score: $score/100\e[0m"
    status="FAIL"
fi
echo "================================================="

# Menulis Luaran JSON untuk Sistem Scoring Lab
mkdir -p "$(dirname "$RESULT_FILE")"
cat > "$RESULT_FILE" <<EOF
{
  "chapter_id": "lab-monitoring-prometheus-grafana-ch74",
  "score": $score,
  "status": "$status"
}
EOF
