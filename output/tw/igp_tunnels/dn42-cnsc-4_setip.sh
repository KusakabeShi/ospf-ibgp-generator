#!/bin/bash
ip link set dn42-cnsc-4 up
ip link set mtu 1452 dev dn42-cnsc-4

ip addr add 192.168.42.1/27 dev dn42-cnsc-4 metric 4294967295
ip route del broadcast 192.168.42.0 dev dn42-cnsc-4

ip addr add fd07:d159:fc38:1::1/128 dev dn42-cnsc-4

ip addr add fe80::1817:1/64 dev dn42-cnsc-4 scope link