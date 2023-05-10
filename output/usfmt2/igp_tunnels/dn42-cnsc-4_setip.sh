#!/bin/bash
ip link set dn42-cnsc-4 up
ip link set mtu 1440 dev dn42-cnsc-4

ip addr add 192.168.42.20/27 dev dn42-cnsc-4 metric 4294967295

ip addr add fd07:d159:fc38:14::1/128 dev dn42-cnsc-4

ip addr add fe80::1817:14/64 dev dn42-cnsc-4 scope link