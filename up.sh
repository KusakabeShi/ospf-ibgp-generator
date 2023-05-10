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

ip link add dummy-{{ netname }} type dummy || true
ip link set dummy-{{ netname }} up || true
{% if ipv4 is defined and ipv4 != None %}ip addr add {{ self_ip.v4 }}/32 dev dummy-{{ netname }} || true{% endif %}
{% if ipv4 is defined and ipv6 != None %}ip addr add {{ self_ip.v6 }}/128 dev dummy-{{ netname }} || true{% endif %}

{% for up in ups -%}
{{ up }}
{% endfor %}


