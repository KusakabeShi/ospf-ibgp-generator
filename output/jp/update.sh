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
ip_tw_6=$(resolveip 6.tw.kskb.moe)
ip_hk_4=$(resolveip 4.hk.kskb.moe)
ip_hk_6=$(resolveip 6.hk.kskb.moe)
ip_usfmt_4=$(resolveip 4.us.kskb.moe)
ip_usfmt_6=$(resolveip 6.us.kskb.moe)
ip_de_6=$(resolveip 6.de.kskb.moe)
ip_cnjs_4=$(resolveip cnjs.kskb.moe)
ip_cnzj_4=$(resolveip 4.cnzj.kskb.moe)
ip_cnzj_6=$(resolveip 6.cnzj.kskb.moe)
ip_cnwh_4=$(resolveip 4.cnwh.kskb.moe)
ip_cngd_6=$(resolveip 6.cngd.kskb.moe)
ip_cncs_4=$(resolveip 4.cncs.kskb.moe)
ip_usfmt2_4=$(resolveip 4.yi.us.kskb.moe)
ip_de2_4=$(resolveip hz.moe.de.kskb.moe)
ip_de2_6=$(resolveip 6.moe.de.kskb.moe)
ip_cnsc_4=$(resolveip 4.cnsc.kskb.moe)


if get_ip_down "fe80::1817:5" "dn42-hk-4"; then
    update_wg_peer dn42-hk-4 "CiVRSlRHj1NCaBGYtFvy3EtU4OkEEE8rF83Mfaykyl0=" "$ip_hk_4:18002" "igp_tunnels/dn42-hk-4.conf"
fi
if get_ip_down "fe80::1817:5" "dn42-hk-6"; then
    update_wg_peer dn42-hk-6 "CiVRSlRHj1NCaBGYtFvy3EtU4OkEEE8rF83Mfaykyl0=" "$ip_hk_6:18003" "igp_tunnels/dn42-hk-6.conf"
fi
if get_ip_down "fe80::1817:8" "dn42-usfmt-4"; then
    update_wg_peer dn42-usfmt-4 "7hb3TPpacgb9xsCtuPcQdP4r1zQx+N9mceaSJ0jF/hY=" "$ip_usfmt_4:18002" "igp_tunnels/dn42-usfmt-4.conf"
fi
if get_ip_down "fe80::1817:8" "dn42-usfmt-6"; then
    update_wg_peer dn42-usfmt-6 "7hb3TPpacgb9xsCtuPcQdP4r1zQx+N9mceaSJ0jF/hY=" "$ip_usfmt_6:18003" "igp_tunnels/dn42-usfmt-6.conf"
fi
if get_ip_down "fe80::1817:a" "dn42-de-6"; then
    update_wg_peer dn42-de-6 "QVCvhxPMyCLPsMyR4eoJfGBO0SES4QS7u5KN+H4K3y4=" "$ip_de_6:18001" "igp_tunnels/dn42-de-6.conf"
fi
if get_ip_down "fe80::1817:c" "dn42-cnjs-4"; then
    update_wg_peer dn42-cnjs-4 "ufa7Qg2MfpU1LW+EuykuAML7x6bhEFmIbmE0hNJnl1o=" "$ip_cnjs_4:42071" "igp_tunnels/dn42-cnjs-4.conf"
fi
if get_ip_down "fe80::1817:10" "dn42-cnzj-4"; then
    update_wg_peer dn42-cnzj-4 "e/lg8d/pOJA3sEBqrdTNZ6dMd5ZRCXR0oNfXQW5KIjw=" "$ip_cnzj_4:14871" "igp_tunnels/dn42-cnzj-4.conf"
fi
if get_ip_down "fe80::1817:10" "dn42-cnzj-6"; then
    update_wg_peer dn42-cnzj-6 "e/lg8d/pOJA3sEBqrdTNZ6dMd5ZRCXR0oNfXQW5KIjw=" "$ip_cnzj_6:14872" "igp_tunnels/dn42-cnzj-6.conf"
fi
if get_ip_down "fe80::1817:12" "dn42-cngd-6"; then
    update_wg_peer dn42-cngd-6 "7WZMs3Qh6gon+PX6Iz5IzBTIeE+TQMwWVu/PAG1OH0I=" "$ip_cngd_6:18001" "igp_tunnels/dn42-cngd-6.conf"
fi
if get_ip_down "fe80::1817:13" "dn42-cncs-4"; then
    update_wg_peer dn42-cncs-4 "NueWyuYQYZo8lB6X8Jd/mShJeNH4UlboiAJ8kZdZFXM=" "$ip_cncs_4:31981" "igp_tunnels/dn42-cncs-4.conf"
fi
if get_ip_down "fe80::1817:14" "dn42-usfmt2-4"; then
    update_wg_peer dn42-usfmt2-4 "lkJVxOPx1EIt2YINSpTD+jFcN36pnCvHWXD6QG3DqjM=" "$ip_usfmt2_4:18001" "igp_tunnels/dn42-usfmt2-4.conf"
fi
if get_ip_down "fe80::1817:15" "dn42-de2-4"; then
    update_wg_peer dn42-de2-4 "2JYyWk0jF4PA6c77t6BZRgGP9qqw8Df5ixTiFPQX8yY=" "$ip_de2_4:13483" "igp_tunnels/dn42-de2-4.conf"
fi
if get_ip_down "fe80::1817:15" "dn42-de2-6"; then
    update_wg_peer dn42-de2-6 "2JYyWk0jF4PA6c77t6BZRgGP9qqw8Df5ixTiFPQX8yY=" "$ip_de2_6:13484" "igp_tunnels/dn42-de2-6.conf"
fi


wg set dn42-cnzj-4 peer "e/lg8d/pOJA3sEBqrdTNZ6dMd5ZRCXR0oNfXQW5KIjw=" endpoint "$ip_cnzj_4:14871"
wg set dn42-cnzj-6 peer "e/lg8d/pOJA3sEBqrdTNZ6dMd5ZRCXR0oNfXQW5KIjw=" endpoint "$ip_cnzj_6:14872"
