#!/bin/bash
set -x

ip link del dummy-dn42 || true


kill $(cat igp_tunnels/dn42-tw-4.pid)
kill $(cat igp_tunnels/dn42-jp-4.pid)
kill $(cat igp_tunnels/dn42-hk-4.pid)
kill $(cat igp_tunnels/dn42-usfmt-4.pid)
ip link del dn42-cnjs-4
ip link del dn42-cnzj-4
ip link del dn42-cnwh-4
ip link del dn42-cncs-4
kill $(cat igp_tunnels/dn42-usfmt2-4.pid)
kill $(cat igp_tunnels/dn42-de2-4.pid)
kill $(cat igp_tunnels/dn42-de-4.pid)
ip link del dn42-cngd-4
