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
ip_hk_4=$(resolveip 4.hk.kskb.moe)
ip_usfmt_4=$(resolveip 4.us.kskb.moe)
ip_usfmt_6=$(resolveip 6.us.kskb.moe)
ip_de_6=$(resolveip 6.de.kskb.moe)
ip_cnjs_4=$(resolveip cnjs.kskb.moe)
ip_cnzj_4=$(resolveip 4.cnzj.kskb.moe)
ip_cncs_4=$(resolveip 4.cncs.kskb.moe)
ip_usfmt2_4=$(resolveip 4.yi.us.kskb.moe)
ip_de2_4=$(resolveip hz.moe.de.kskb.moe)
ip_de2_6=$(resolveip 6.moe.de.kskb.moe)
ip_cnsc_4=$(resolveip 4.cnsc.kskb.moe)


if get_ip_down "fe80::1817:1" "dn42-tw-4"; then
    update_wg_peer dn42-tw-4 "Tc/3q7oLM1YijV5NPRml7twAzKFseQ+9t0k376Ws3Aw=" "$ip_tw_4:18001" "igp_tunnels/dn42-tw-4.conf"
fi
if get_ip_down "fe80::1817:4" "dn42-jp-4"; then
    update_wg_peer dn42-jp-4 "S758btS+yGAPN3ZUK9uwBytx9v8lBKlKdO/V9Nil/Cw=" "$ip_jp_4:18003" "igp_tunnels/dn42-jp-4.conf"
fi
if get_ip_down "fe80::1817:5" "dn42-hk-4"; then
    update_wg_peer dn42-hk-4 "PBeqRWWbRkK2J7eZM+Fks5CX7V60ModeFO+sNEz2aWQ=" "$ip_hk_4:18005" "igp_tunnels/dn42-hk-4.conf"
fi
if get_ip_down "fe80::1817:8" "dn42-usfmt-4"; then
    update_wg_peer dn42-usfmt-4 "/ITn6sdA5luUrPoWFfWtLNbJic5WKL9smFomCLXuQDE=" "$ip_usfmt_4:18007" "igp_tunnels/dn42-usfmt-4.conf"
fi
if get_ip_down "fe80::1817:8" "dn42-usfmt-6"; then
    update_wg_peer dn42-usfmt-6 "/ITn6sdA5luUrPoWFfWtLNbJic5WKL9smFomCLXuQDE=" "$ip_usfmt_6:18008" "igp_tunnels/dn42-usfmt-6.conf"
fi
if get_ip_down "fe80::1817:a" "dn42-de-6"; then
    update_wg_peer dn42-de-6 "bEGjgZ0gabtfilwb4Z+2IV4ytlTgEu0VhAtvl1V+mSk=" "$ip_de_6:18004" "igp_tunnels/dn42-de-6.conf"
fi
if get_ip_down "fe80::1817:c" "dn42-cnjs-4"; then
    update_wg_peer dn42-cnjs-4 "OPfWD88pEx4nWIn/YB836bmw/I7a+P4TyuAgGmOGPys=" "$ip_cnjs_4:42075" "igp_tunnels/dn42-cnjs-4.conf"
fi
if get_ip_down "fe80::1817:10" "dn42-cnzj-4"; then
    update_wg_peer dn42-cnzj-4 "+g0GBYWJLj4/48IdRNsNtgWrQGqwr5q0bJHySW3qBjs=" "$ip_cnzj_4:14880" "igp_tunnels/dn42-cnzj-4.conf"
fi
if get_ip_down "fe80::1817:13" "dn42-cncs-4"; then
    update_wg_peer dn42-cncs-4 "j5xSk2xuVKgAADdT+3R4L//CWAMfgM3Wy9vcIF2TQQM=" "$ip_cncs_4:31984" "igp_tunnels/dn42-cncs-4.conf"
fi
if get_ip_down "fe80::1817:14" "dn42-usfmt2-4"; then
    update_wg_peer dn42-usfmt2-4 "AQJPoutD8D0YMUS2BOrhE0Drlzce4LQOO2ZK1UY8JRg=" "$ip_usfmt2_4:18004" "igp_tunnels/dn42-usfmt2-4.conf"
fi
if get_ip_down "fe80::1817:15" "dn42-de2-4"; then
    update_wg_peer dn42-de2-4 "aHAbIRzMq9y9w48hMOhS4/HwhVD6zU6Jn3ESFbFxDHE=" "$ip_de2_4:13490" "igp_tunnels/dn42-de2-4.conf"
fi
if get_ip_down "fe80::1817:15" "dn42-de2-6"; then
    update_wg_peer dn42-de2-6 "aHAbIRzMq9y9w48hMOhS4/HwhVD6zU6Jn3ESFbFxDHE=" "$ip_de2_6:13491" "igp_tunnels/dn42-de2-6.conf"
fi


wg set dn42-tw-4 peer "Tc/3q7oLM1YijV5NPRml7twAzKFseQ+9t0k376Ws3Aw=" endpoint "$ip_tw_4:18001"
wg set dn42-cnzj-4 peer "+g0GBYWJLj4/48IdRNsNtgWrQGqwr5q0bJHySW3qBjs=" endpoint "$ip_cnzj_4:14880"
