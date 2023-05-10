#!/usr/bin/python3
import re
import argparse
import jinja2
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--cost", help="set cost", default=0, type=int)
args = parser.parse_args()

max_cost = 9999

clients = {{ clients }}
cost = {}

def ping(ifname,address):
    ping_cmd = subprocess.run(["ping", address, "-I", ifname, "-c", "20", "-f", "-i", "0.2"], capture_output=True)
    ping_stats, errs = ping_cmd.stdout.decode("utf8"), ping_cmd.stderr.decode("utf8")
    packet_loss = re.search(r'(\d+)% packet loss', ping_stats).group(1)
    latency = re.search(r'(\d+\.\d+)/(\d+\.\d+)/(\d+\.\d+)/(\d+\.\d+)', ping_stats)
    
    if latency:
        latency = {
            'min': float(latency.group(1)),
            'avg': float(latency.group(2)),
            'max': float(latency.group(3)),
            'mdev': float(latency.group(4))
        }
    else:
        latency = {}

    return {
        'packet_loss': float(packet_loss)/100,
        'latency': latency
    }

def get_cost(ifname,address):
    if args.cost != 0:
        return args.cost
    result = ping(ifname,address)
    if result["packet_loss"] == 1 or result["latency"] == {}:
        return max_cost
    cost = int(result["latency"]["avg"] * (1/1-result["packet_loss"]))
    return min(max(1,cost),max_cost)

for ifname,address in clients.items():
    cost[ifname.replace("-","_")] = get_cost(ifname,address)
    
ospftemplate = jinja2.Template(open('bird/ospf_{{ net_name }}.conf.j2').read())
ospfconf = ospftemplate.render(cost = cost)
open("bird/ospf_{{ net_name }}.conf" , "w").write(ospfconf)