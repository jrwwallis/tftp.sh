#/bin/bash

###############################################################################
#
# Bash-based implementation of the TFTP protocol
# John Wallis 2019
# GPLv3
# https://github.com/jrwwallis/tftp.sh
#
###############################################################################

port=69

pkt_type_e=(NULL RRQ WRQ DATA ACK ERROR)

shopt -u nocasematch

function die () {
    printf "%s\n" "$1" 1>&2
    exit 1
}

function hs2nhex () {
    hs=$1
    printf "\\\x%02x\\\x%02x" $((hs/256)) $((hs%256))
}

function nsread () {
    read -u ${tftp_cp[0]} hexa
    read -u ${tftp_cp[0]} hexb
    echo $((0x${hexa// }${hexb// }))
}

function cstrread () {
    str=
    while read -u ${tftp_cp[0]} hex; do
	if [ "$hex" = "00" ]; then
	    break
	fi
	printf -v char "\\\x%s" "$hex"
	str+="$char"
    done
    printf "$str"
}

function tx_ack () {
    blocknum=$1
    printf "$(hs2nhex 4)$(hs2nhex ${blocknum})"
}

function dataread () {
    data=
    sz=0
    while :; do
	read -t0.1 -u ${tftp_cp[0]} hex
        readerr=$?
	if (( readerr )); then
	    break
	fi
	printf -v char "%s" "\\x$hex"
	data+="$char"
	((sz++))
	if ((sz >= 512)); then
	    break
	fi
    done
    
    printf "$data"
    return $readerr
}

function rx_data () {
    acknum=$1
    pkttype=${pkt_type_e[$(nsread)]}
    if [ ! "$pkttype" = "DATA" ]; then
        die "Not data"
    fi
    blocknum=$(nsread)
    if (( blocknum != acknum )); then
        die "Wrong block $blocknum != $acknum"
    fi

    dataread
}

function rx_wrq () {
    blocknum=0
    while true; do
        tx_ack $blocknum >&${tftp_cp[1]}
        ((blocknum++))
        if ! rx_data $blocknum; then
            break
        fi
    done
    tx_ack $blocknum >&${tftp_cp[1]}
}

function rx_rrq () {
    die RRQ serve not yet supported
}

function fini() {
    kill -term $tftp_cp_PID
}


function read_req () {
    pkttype=${pkt_type_e[$(nsread)]}
    file=$(cstrread)
    mode=$(cstrread)

    shopt -s nocasematch
    case "$mode" in
    "octet")
        : ;;
    "netascii")
        : ;;
    *)
        die "Only octet or netascii mode supported"
    esac
    shopt -u nocasematch

    file="${file#/}"

    case "$pkttype" in
    "RRQ")
        rx_rrq < "${rootdir}/${file}"
        ;;
    "WRQ")
        rx_wrq > "${rootdir}/${file}"
        ;;
    *)
        die "Unknown packet type $pkttype"
    esac
}

function serve () {
    port="$1"
    rootdir="$2"

    trap fini EXIT

    coproc tftp_cp { nc -l -u $port | stdbuf -oL od -An -tx1 -w1 -v ; }
    read_req
}

function get () {
    die "GET not yet supported"
}

function put () {
    die "PUT not yet supported"
}

function usage() {
echo "\
Usage:
$0 [OPTION] -R <server root dir>
$0 [OPTION] -G <GET filename> <server host/address>
$0 [OPTION] -P <PUT filename> <server host/address>
    -p <port>             port number
" 1>&2; exit 1
}

servecmd=$((2**0))
getcmd=$((2**1))
putcmd=$((2**2))

while getopts ":R:G:P:p:" o; do
    case "${o}" in
    R)
        ((cmd|=$servecmd))
        rootdir=${OPTARG}
        ;;
    G)
        ((cmd|=$getcmd))
        getfile=${OPTARG}
        ;;
    P)
        ((cmd|=$putcmd))
        putfile=${OPTARG}
        ;;
    p)
        port=${OPTARG}
        ;;
    *)
        usage
        ;;
    esac
done
shift $((OPTIND-1))

case "$cmd" in
$servecmd)
    if (( $# == 0 )); then
        serve "$port" "$rootdir"
    else
        usage
    fi
    ;;
$getcmd)
    if (( $# == 1 )); then
        get "$1" "$port" "$getfile"
    else
        usage
    fi
    ;;
$putcmd)
    if (( $# == 1 )); then
        put "$host" "$port" "$putfile"
    else
        usage
    fi
    ;;
*)
    usage
    ;;
esac
