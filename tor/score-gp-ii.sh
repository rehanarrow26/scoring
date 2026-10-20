#!/bin/bash
# ================================================================
# AUTOMATED GRADER: ALERTMANAGER & PROMETHEUS ALERTING
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
echo "  GRADER: ALERTMANAGER & PROMETHEUS ALERTING"
echo "================================================="
echo

# 1. CEK INSTALASI & STATUS ALERTMANAGER (25 Pts)
echo -n "Step 1: Memeriksa Layanan Alertmanager (Port 9093) (25 pts)..."
AM_ACTIVE=$(systemctl is-active --quiet alertmanager 2>/dev/null && echo "yes" || echo "no")
AM_PORT=$(ss -tlnp 2>/dev/null | grep -q ":9093" && echo "yes" || echo "no")

if [ "$AM_ACTIVE" = "yes" ] && [ "$AM_PORT" = "yes" ]; then
    pass_check 25
else
    fail_check "Layanan Alertmanager tidak aktif atau port 9093 tidak terbuka."
fi

# 2. CEK VALIDITAS KONFIGURASI ALERTMANAGER.YML (25 Pts)
echo -n "Step 2: Memeriksa Validitas Konfigurasi Alertmanager via amtool (25 pts)..."
AM_CONF="/etc/alertmanager/alertmanager.yml"

if [ -f "$AM_CONF" ]; then
    # Menguji file konfigurasi menggunakan amtool check-config
    AM_CHECK=$(amtool check-config "$AM_CONF" 2>&1 | grep -i "SUCCESS" || echo "")
    
    if [ -n "$AM_CHECK" ]; then
        pass_check 25
    else
        fail_check "Konfigurasi alertmanager.yml tidak valid atau gagal divalidasi oleh amtool."
    fi
else
    fail_check "Berkas konfigurasi $AM_CONF tidak ditemukan."
fi

# 3. CEK FILE ATURAN ALERT (ALERT.RULES.YML) & PROMETHEUS (25 Pts)
echo -n "Step 3: Memeriksa Aturan Alert & Validasi promtool (25 pts)..."
RULES_FILE="/etc/prometheus/alert.rules.yml"
PROM_CONF="/etc/prometheus/prometheus.yml"

if [ -f "$RULES_FILE" ] && [ -f "$PROM_CONF" ]; then
    # Validasi alert rules dengan promtool
    RULES_CHECK=$(promtool check rules "$RULES_FILE" 2>&1 | grep -i "SUCCESS" || echo "")
    # Cek apakah rule_files dan alerting sudah terdaftar di prometheus.yml
    HAS_RULE_REF=$(grep -E '/etc/prometheus/alert\.rules\.yml' "$PROM_CONF" >/dev/null && echo "yes" || echo "no")
    HAS_AM_REF=$(grep -E 'localhost:9093' "$PROM_CONF" >/dev/null && echo "yes" || echo "no")

    if [ -n "$RULES_CHECK" ] && [ "$HAS_RULE_REF" = "yes" ] && [ "$HAS_AM_REF" = "yes" ]; then
        pass_check 25
    else
        REASON=""
        [ -z "$RULES_CHECK" ] && REASON="Sintaks alert.rules.yml tidak valid (gagal promtool). "
        [ "$HAS_RULE_REF" = "no" ] && REASON="${REASON}rule_files belum dimasukkan ke prometheus.yml. "
        [ "$HAS_AM_REF" = "no" ] && REASON="${REASON}Blok alerting target localhost:9093 belum dimasukkan ke prometheus.yml."
        fail_check "$REASON"
    fi
else
    fail_check "Berkas alert.rules.yml atau prometheus.yml tidak ditemukan."
fi

# 4. CEK INTEGRASI ALERTMANAGER DENGAN PROMETHEUS (API STATUS) (25 Pts)
echo -n "Step 4: Memeriksa Konektivitas Prometheus ke Alertmanager (25 pts)..."
# Memeriksa endpoint API status alertmanagers pada Prometheus lokal
PROM_AM_STATUS=$(curl -s http://localhost:9090/api/v1/alertmanagers | grep -oi "http://localhost:9093" || echo "")

if [ -n "$PROM_AM_STATUS" ]; then
    pass_check 25
else
    fail_check "Prometheus tidak terhubung ke Alertmanager (pastikan service Prometheus sudah direstart)."
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
  "chapter_id": "lab-prometheus-alerting-discord-ch75",
  "score": $score,
  "status": "$status"
}
EOF
