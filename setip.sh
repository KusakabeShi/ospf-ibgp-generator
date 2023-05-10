ip link set {{ ifname }} up
{% if MTU > 0 -%}
ip link set mtu {{ MTU }} dev {{ ifname }}
{% endif %}
{% if ipv4 is defined and ipv4 != None -%}
ip addr add {{ ipv4 }}/{{ v4_prefixlen }} dev {{ ifname }} metric 4294967295
{% endif %}
{% if ipv6 is defined -%}
ip addr add {{ ipv6 }}/128 dev {{ ifname }}
{% endif %}
ip addr add {{ ipv6ll }}/64 dev {{ ifname }} scope link
