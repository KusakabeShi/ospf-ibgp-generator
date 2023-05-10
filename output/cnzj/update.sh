#!/bin/bash

resolveip()
{
  : ${1:?Usage: resolve name}
  (
    PATH=$PATH:/usr/bin
    lookupresult=$(getent ahostsv4 "$1")
    if [ $? -eq 0 ]; then
        resultaddr=$(echo $lookupresult | head -n 1 | awk '{print $1}')
        echo $resultaddr
        return 0
    fi
    lookupresult=$(getent ahostsv6 $1)
    if [ $? -eq 0 ]; then
        resultaddr=$(echo $lookupresult | head -n 1 | awk '{print $1}')
        echo "[$resultaddr]"
        return 0
    fi
    echo "0.0.0.0"
    return 127
  )
}

get_wg_peer_down () {
    #1:name, 2:peer key, 3:peer endpoint, 4:confpath
    current_time=$(date +%s)
    last_handshake=$(wg show "$1" latest-handshakes | grep "$2" | awk "{print \$2}")
    if [ -z "$last_handshake" ]; then
        last_handshake=0
        wg setconf "$1" "$4"
    fi
    last_to_now=$(("$current_time"-"$last_handshake"))
    if [ "$last_to_now" -gt "180" ]; then
        return 0 #success, means down
    fi
        return 1 #fail, means up
}

update_wg_peer() {
    if get_wg_peer_down "$1" "$2" "$3" "$4"; then
        wg set "$1" listen-port "5$(head /dev/urandom | tr -dc "0123456789" | head -c4)"
        wg set "$1" peer "$2" endpoint "$3"
    fi
}

get_ip_down () {
    #1:ip 2:ifname
    if ! ping -c 1 -W 3 "$1" -I "$2" >/dev/null 
    then
        return 0 #success, means down
    fi
    return 1 # fail. means up
}

ip_tw_4=$(resolveip 4.tw.kskb.moe)
ip_jp_4=$(resolveip 4.jp.kskb.moe)
ip_jp_6=$(resolveip 6.jp.kskb.moe)
ip_hk_4=$(resolveip 4.hk.kskb.moe)
ip_hk_6=$(resolveip 6.hk.kskb.moe)
ip_usfmt_4=$(resolveip 4.us.kskb.moe)
ip_usfmt_6=$(resolveip 6.us.kskb.moe)
ip_de_6=$(resolveip 6.de.kskb.moe)
ip_cnjs_4=$(resolveip cnjs.kskb.moe)
ip_cnwh_4=$(resolveip 4.cnwh.kskb.moe)
ip_cngd_6=$(resolveip 6.cngd.kskb.moe)
ip_cncs_4=$(resolveip 4.cncs.kskb.moe)
ip_usfmt2_4=$(resolveip 4.yi.us.kskb.moe)
ip_de2_4=$(resolveip hz.moe.de.kskb.moe)
ip_de2_6=$(resolveip 6.moe.de.kskb.moe)
ip_cnsc_4=$(resolveip 4.cnsc.kskb.moe)




