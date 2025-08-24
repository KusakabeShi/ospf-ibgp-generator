ip link set {{ ifname }} up
{% if MTU > 0 -%}
ip link set mtu {{ MTU }} dev {{ ifname }} || true
{% endif %}
{% if ipv4 is defined and ipv4 != None -%}
ip addr add {{ ipv4 }}/{{ v4_prefixlen }} dev {{ ifname }} metric 4294967295 || true
ip route del broadcast {{ ipv4net }} dev {{ ifname }} || true
{% endif %}
{% if ipv6 is defined -%}
ip addr add {{ ipv6 }}/128 dev {{ ifname }} || true
{% endif %}
ip addr add {{ ipv6ll }}/64 dev {{ ifname }} scope link || true
