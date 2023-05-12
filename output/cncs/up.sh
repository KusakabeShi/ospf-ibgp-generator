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
set -x

python3 update_cost.py --cost 9999

ip link add dummy-dn42 type dummy || true
ip link set dummy-dn42 up || true
ip addr add 192.168.42.19/32 dev dummy-dn42 || true
ip addr add fd07:d159:fc38:13::1/128 dev dummy-dn42 || true

ip_tw_4=$(resolveip 4.tw.kskb.moe)
ip link add dev dn42-tw-4 type wireguard
wg setconf dn42-tw-4 igp_tunnels/dn42-tw-4.conf
ip link set dn42-tw-4 up
ip link set mtu 1432 dev dn42-tw-4
ip addr add 192.168.42.19/27 dev dn42-tw-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-tw-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-tw-4
ip addr add fe80::1817:13/64 dev dn42-tw-4 scope link

ip_jp_4=$(resolveip 4.jp.kskb.moe)
ip link add dev dn42-jp-4 type wireguard
wg setconf dn42-jp-4 igp_tunnels/dn42-jp-4.conf
ip link set dn42-jp-4 up
ip link set mtu 1440 dev dn42-jp-4
ip addr add 192.168.42.19/27 dev dn42-jp-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-jp-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-jp-4
ip addr add fe80::1817:13/64 dev dn42-jp-4 scope link

ip_hk_4=$(resolveip 4.hk.kskb.moe)
ip link add dev dn42-hk-4 type wireguard
wg setconf dn42-hk-4 igp_tunnels/dn42-hk-4.conf
ip link set dn42-hk-4 up
ip link set mtu 1440 dev dn42-hk-4
ip addr add 192.168.42.19/27 dev dn42-hk-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-hk-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-hk-4
ip addr add fe80::1817:13/64 dev dn42-hk-4 scope link

ip_usfmt_4=$(resolveip 4.us.kskb.moe)
ip link add dev dn42-usfmt-4 type wireguard
wg setconf dn42-usfmt-4 igp_tunnels/dn42-usfmt-4.conf
ip link set dn42-usfmt-4 up
ip link set mtu 1440 dev dn42-usfmt-4
ip addr add 192.168.42.19/27 dev dn42-usfmt-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-usfmt-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-usfmt-4
ip addr add fe80::1817:13/64 dev dn42-usfmt-4 scope link

ip_cnjs_4=$(resolveip cnjs.kskb.moe)
ip link add dev dn42-cnjs-4 type wireguard
wg setconf dn42-cnjs-4 igp_tunnels/dn42-cnjs-4.conf
ip link set dn42-cnjs-4 up
ip link set mtu 1440 dev dn42-cnjs-4
ip addr add 192.168.42.19/27 dev dn42-cnjs-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-cnjs-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-cnjs-4
ip addr add fe80::1817:13/64 dev dn42-cnjs-4 scope link

ip_cnzj_4=$(resolveip 4.cnzj.kskb.moe)
ip link add dev dn42-cnzj-4 type wireguard
wg setconf dn42-cnzj-4 igp_tunnels/dn42-cnzj-4.conf
ip link set dn42-cnzj-4 up
ip link set mtu 1420 dev dn42-cnzj-4
ip addr add 192.168.42.19/27 dev dn42-cnzj-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-cnzj-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-cnzj-4
ip addr add fe80::1817:13/64 dev dn42-cnzj-4 scope link

ip_cnwh_4=$(resolveip 4.cnwh.kskb.moe)
ip link add dev dn42-cnwh-4 type wireguard
wg setconf dn42-cnwh-4 igp_tunnels/dn42-cnwh-4.conf
ip link set dn42-cnwh-4 up
ip link set mtu 1432 dev dn42-cnwh-4
ip addr add 192.168.42.19/27 dev dn42-cnwh-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-cnwh-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-cnwh-4
ip addr add fe80::1817:13/64 dev dn42-cnwh-4 scope link

ip link add dev dn42-de-4 type wireguard
wg setconf dn42-de-4 igp_tunnels/dn42-de-4.conf
ip link set dn42-de-4 up
ip link set mtu 1440 dev dn42-de-4
ip addr add 192.168.42.19/27 dev dn42-de-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-de-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-de-4
ip addr add fe80::1817:13/64 dev dn42-de-4 scope link

ip link add dev dn42-cngd-4 type wireguard
wg setconf dn42-cngd-4 igp_tunnels/dn42-cngd-4.conf
ip link set dn42-cngd-4 up
ip link set mtu 1360 dev dn42-cngd-4
ip addr add 192.168.42.19/27 dev dn42-cngd-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-cngd-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-cngd-4
ip addr add fe80::1817:13/64 dev dn42-cngd-4 scope link

ip_usfmt2_4=$(resolveip 4.yi.us.kskb.moe)
ip link add dev dn42-usfmt2-4 type wireguard
wg setconf dn42-usfmt2-4 igp_tunnels/dn42-usfmt2-4.conf
ip link set dn42-usfmt2-4 up
ip link set mtu 1420 dev dn42-usfmt2-4
ip addr add 192.168.42.19/27 dev dn42-usfmt2-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-usfmt2-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-usfmt2-4
ip addr add fe80::1817:13/64 dev dn42-usfmt2-4 scope link

ip_de2_4=$(resolveip hz.moe.de.kskb.moe)
ip link add dev dn42-de2-4 type wireguard
wg setconf dn42-de2-4 igp_tunnels/dn42-de2-4.conf
ip link set dn42-de2-4 up
ip link set mtu 1440 dev dn42-de2-4
ip addr add 192.168.42.19/27 dev dn42-de2-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-de2-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-de2-4
ip addr add fe80::1817:13/64 dev dn42-de2-4 scope link

ip_cnsc_4=$(resolveip 4.cnsc.kskb.moe)
ip link add dev dn42-cnsc-4 type wireguard
wg setconf dn42-cnsc-4 igp_tunnels/dn42-cnsc-4.conf
ip link set dn42-cnsc-4 up
ip link set mtu 1440 dev dn42-cnsc-4
ip addr add 192.168.42.19/27 dev dn42-cnsc-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-cnsc-4
ip addr add fd07:d159:fc38:13::1/128 dev dn42-cnsc-4
ip addr add fe80::1817:13/64 dev dn42-cnsc-4 scope link



