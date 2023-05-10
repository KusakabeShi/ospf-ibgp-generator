#!/bin/bash
set -x

ip link del dummy-{{ netname }} || true


{% for down in downs -%}
{{ down }}
{% endfor %}