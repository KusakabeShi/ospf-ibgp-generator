#!/bin/bash
ip link set dn42-usfmt-4 up
ip link set mtu 1460 dev dn42-usfmt-4

ip addr add 192.168.42.22/27 dev dn42-usfmt-4 metric 4294967295

ip addr add fd07:d159:fc38:16::1/128 dev dn42-usfmt-4

ip addr add fe80::1817:16/64 dev dn42-usfmt-4 scope link