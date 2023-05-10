#!/bin/bash
set -x

ip link del dummy-dn42 || true


ip link del dn42-tw-4
ip link del dn42-jp-4
ip link del dn42-hk-4
ip link del dn42-usfmt-4
ip link del dn42-cnjs-4
ip link del dn42-cnzj-4
ip link del dn42-cnwh-4
ip link del dn42-cncs-4
ip link del dn42-de-4
ip link del dn42-cngd-4
ip link del dn42-de2-4
kill $(cat igp_tunnels/dn42-cnsc-4.pid)
