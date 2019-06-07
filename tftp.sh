#/bin/bash

###############################################################################
#
# Bash-based implementation of the TFTP protocol
# John Wallis 2019
# GPLv3
# https://github.com/jrwwallis/tftp.sh
#
###############################################################################

TFTPPORT=6969

pkt_type_e=(NULL RRQ WRQ DATA ACK ERROR)

function die () {
    printf "%s\n" "$1" 1>&2
    exit 1
}

function hs2nhex () {
    hs=$1
    printf "\\\x%02x\\\x%02x" $((hs/256)) $((hs%256))
}

function nsread () {
    hex=$(od -An -N2 -tx1)
    echo $((0x${hex// }))
}

function cstrread () {
    IFS= read -r -d '' str
    printf "%s" "$str"
}

function tx_ack () {
    blocknum=$1
    printf "$(hs2nhex 4)$(hs2nhex ${blocknum})" > /tmp/tftpin
}

function dataread () {
    dd bs=512 count=1 < /tmp/tftpout 2>/tmp/ddstats &
    ddpid=$!

    while :; do
        read -t0.1 sz stat _
        readerr=$?
        if (( readerr )); then
            kill -term $ddpid
            sz=0
            break
        fi
        if [ "${stat::4}" = "byte" ]; then
            break
        fi
    done < /tmp/ddstats
    wait $ddpid 2>/dev/null
    if (( sz == 512 )); then
        return 1
    fi
    return 0
}

function rx_data () {
    acknum=$1
    pkttype=${pkt_type_e[$(nsread < /tmp/tftpout)]}
    if [ ! "$pkttype" = "DATA" ]; then
        die "Not data"
    fi
    blocknum=$(nsread < /tmp/tftpout)
    if (( blocknum != acknum )); then
        die "Wrong block $blocknum != $acknum"
    fi

    dataread < /tmp/tftpout
}

function rx_wrq () {
    blocknum=0
    while true; do
        tx_ack $blocknum
        ((blocknum++))
        if rx_data $blocknum; then
            break
        fi
    done
    tx_ack $blocknum
}



function fini() {
    rm /tmp/ddstats
    rm /tmp/tftp{in,out}
}

mkfifo /tmp/tftp{in,out}
mkfifo /tmp/ddstats

trap fini EXIT

nc -l -u $TFTPPORT > /tmp/tftpout <> /tmp/tftpin &

pkttype=${pkt_type_e[$(nsread < /tmp/tftpout)]}
file=$(cstrread < /tmp/tftpout)
mode=$(cstrread < /tmp/tftpout)
mode=${mode,,}

if [ ! "$mode" = "octet" ]; then
    die "Only octet mode supported"
fi

file="${file#/}"

case "$pkttype" in
"RRQ")
    rx_rrq "$file"
    ;;
"WRQ")
    rx_wrq "$file" > "$file"
    ;;
*)
    die "Unknown packet type $pkttype"
esac