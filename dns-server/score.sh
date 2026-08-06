#!/bin/bash

clear

########################################
# CONFIG
########################################

SERVER_IP="lms.teknolojia.my.id"

DOMAIN="coba.lan"

ZONE_FILE="/etc/bind/db.coba"

NAMED_LOCAL="/etc/bind/named.conf.local"

LAB_DIR="$HOME/.lab"

RESULT_FILE="$LAB_DIR/result.json"

mkdir -p "$LAB_DIR"

########################################
# SCORE
########################################

score=0

STATUS="failed"

########################################
# RESULT
########################################

BIND_RESULT="FAIL"
SERVICE_RESULT="FAIL"

ZONE_RESULT="FAIL"
TYPE_RESULT="FAIL"
FILE_RESULT="FAIL"

SOA_RESULT="FAIL"
NS_RESULT="FAIL"

NS1_RESULT="FAIL"
NS2_RESULT="FAIL"

WWW_RESULT="FAIL"
MAIL_RESULT="FAIL"

MX_RESULT="FAIL"

CHECKCONF_RESULT="FAIL"
CHECKZONE_RESULT="FAIL"

RESOLV_RESULT="FAIL"

PING_RESULT="FAIL"

########################################
# HEADER
########################################

echo "========================================="
echo "        DNS PRIMARY CHECKER"
echo "========================================="
echo

########################################
# FUNCTION
########################################

pass(){

    echo "[PASS]"

}

fail(){

    echo "[FAIL]"

}

########################################
# CHECK BIND9
########################################

echo -n "Checking Bind9 Installation......"

if dpkg -s bind9 >/dev/null 2>&1
then

    pass

    score=$((score+10))

    BIND_RESULT="PASS"

else

    fail

fi

########################################
# CHECK SERVICE
########################################

echo -n "Checking Bind9 Service..........."

if systemctl is-active --quiet bind9
then

    pass

    score=$((score+10))

    SERVICE_RESULT="PASS"

else

    fail

fi

########################################
# PART 2 END
########################################

echo
echo "Current Score : $score"
echo

# Part 3 dimulai dari sini...
########################################
# CHECK named.conf.local
########################################

echo -n "Checking DNS Zone................."

if grep -Eq '^[[:space:]]*zone[[:space:]]+"coba\.lan"' "$NAMED_LOCAL"
then

    pass

    score=$((score+15))

    ZONE_RESULT="PASS"

else

    fail

fi

########################################
# CHECK TYPE MASTER
########################################

echo -n "Checking Zone Type............... "

if grep -A3 'zone[[:space:]]*"coba\.lan"' "$NAMED_LOCAL" \
| grep -q 'type[[:space:]]*master'
then

    pass

    score=$((score+5))

    TYPE_RESULT="PASS"

else

    fail

fi

########################################
# CHECK DB FILE
########################################

echo -n "Checking Zone File............... "

if grep -A5 'zone[[:space:]]*"coba\.lan"' "$NAMED_LOCAL" \
| grep -q '/etc/bind/db.coba'
then

    pass

    score=$((score+5))

    FILE_RESULT="PASS"

else

    fail

fi

########################################
# CHECK FILE EXISTS
########################################

echo -n "Checking db.coba................ "

if [ -f "$ZONE_FILE" ]
then

    pass

    score=$((score+10))

else

    fail

fi

########################################
# PART 3 END
########################################

echo
echo "Current Score : $score"
echo

# Part 4 dimulai dari sini...
########################################
# CHECK SOA
########################################

echo -n "Checking SOA Record.............."

if grep -q "SOA.*coba.lan." "$ZONE_FILE"
then

    pass

    score=$((score+5))

    SOA_RESULT="PASS"

else

    fail

fi

########################################
# CHECK NS RECORD
########################################

echo -n "Checking NS Record..............."

if grep -Eq '^[[:space:]]*@.*NS.*ns1\.coba\.lan\.' "$ZONE_FILE"
then

    pass

    score=$((score+5))

    NS_RESULT="PASS"

else

    fail

fi

########################################
# CHECK NS1
########################################

echo -n "Checking ns1 Record.............."

if grep -Eq '^[[:space:]]*ns1.*A.*192\.168\.10\.5' "$ZONE_FILE"
then

    pass

    score=$((score+5))

    NS1_RESULT="PASS"

else

    fail

fi

########################################
# CHECK NS2
########################################

echo -n "Checking ns2 Record.............."

if grep -Eq '^[[:space:]]*ns2.*A.*192\.168\.10\.5' "$ZONE_FILE"
then

    pass

    score=$((score+5))

    NS2_RESULT="PASS"

else

    fail

fi

########################################
# CHECK WWW
########################################

echo -n "Checking WWW Record.............."

if grep -Eq '^[[:space:]]*www.*A.*192\.168\.10\.5' "$ZONE_FILE"
then

    pass

    score=$((score+5))

    WWW_RESULT="PASS"

else

    fail

fi

########################################
# CHECK MAIL
########################################

echo -n "Checking Mail Record............."

if grep -Eq '^[[:space:]]*mail.*A.*192\.168\.10\.5' "$ZONE_FILE"
then

    pass

    score=$((score+5))

    MAIL_RESULT="PASS"

else

    fail

fi

########################################
# CHECK MX
########################################

echo -n "Checking MX Record..............."

if grep -Eq '^[[:space:]]*@.*MX.*mail\.coba\.lan\.' "$ZONE_FILE"
then

    pass

    score=$((score+5))

    MX_RESULT="PASS"

else

    fail

fi

########################################
# PART 4 END
########################################

echo
echo "Current Score : $score"
echo

# Part 5 dimulai dari sini...

########################################
# CHECK named-checkconf
########################################
systemctl restart bind9
echo -n "Checking named-checkconf........."

CHECKCONF_OUTPUT=$(named-checkconf 2>&1)

if [ $? -eq 0 ]
then

    pass

    score=$((score+5))

    CHECKCONF_RESULT="PASS"

    CHECKCONF_MESSAGE="Configuration OK"

else

    fail

    CHECKCONF_MESSAGE="$CHECKCONF_OUTPUT"

fi

########################################
# CHECK named-checkzone
########################################

echo -n "Checking named-checkzone........."

CHECKZONE_OUTPUT=$(named-checkzone coba.lan "$ZONE_FILE" 2>&1)

if [ $? -eq 0 ]
then

    pass

    score=$((score+5))

    CHECKZONE_RESULT="PASS"

    CHECKZONE_MESSAGE="Zone OK"

else

    fail

    CHECKZONE_MESSAGE="$CHECKZONE_OUTPUT"

fi



########################################
# FINAL STATUS
########################################

if [ "$score" -eq 100 ]
then

    STATUS="done"

else

    STATUS="failed"

fi

########################################
# SAVE RESULT
########################################

cat > "$RESULT_FILE" <<EOF
{
    "score": $score,
    "status": "$STATUS",
    "detail": {

        "Bind9": {
            "status":"$BIND_RESULT",
            "score":10
        },

        "Service": {
            "status":"$SERVICE_RESULT",
            "score":10
        },

        "Zone": {
            "status":"$ZONE_RESULT",
            "score":15
        },

        "TypeMaster": {
            "status":"$TYPE_RESULT",
            "score":5
        },

        "ZoneFile": {
            "status":"$FILE_RESULT",
            "score":5
        },

        "SOA": {
            "status":"$SOA_RESULT",
            "score":5
        },

        "NS": {
            "status":"$NS_RESULT",
            "score":5
        },

        "NS1": {
            "status":"$NS1_RESULT",
            "score":5
        },

        "NS2": {
            "status":"$NS2_RESULT",
            "score":5
        },

        "WWW": {
            "status":"$WWW_RESULT",
            "score":5
        },

        "MAIL": {
            "status":"$MAIL_RESULT",
            "score":5
        },

        "MX": {
            "status":"$MX_RESULT",
            "score":5
        },

        "named-checkconf": {
            "status":"$CHECKCONF_RESULT",
            "score":5,
            "message":"$CHECKCONF_MESSAGE"
        },

        "named-checkzone": {
            "status":"$CHECKZONE_RESULT",
            "score":5,
            "message":"$CHECKZONE_MESSAGE"
        }

       

    }
}
EOF

########################################
# FINAL
########################################

echo
echo "========================================="
echo "Score : $score /100"
echo "========================================="

if [ "$STATUS" = "done" ]
then

    echo
    echo "MISSION COMPLETE"
    echo
    echo "DNS Primary Server berhasil dikonfigurasi."

else

    echo
    echo "MISSION FAILED"
    echo
    echo "Periksa kembali konfigurasi DNS."

fi

echo
echo "Result saved : $RESULT_FILE"
echo
