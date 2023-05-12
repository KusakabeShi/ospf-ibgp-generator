import jinja2
import yaml
import os
import json
import shutil
import string
import ipaddress

import ruamel.yaml
from ruamel.yaml.constructor import SafeConstructor

os.umask(0o022)

class PrettySafeLoader(yaml.SafeLoader):
    def construct_python_tuple(self, node):
        return tuple(self.construct_sequence(node))

PrettySafeLoader.add_constructor(
    u'tag:yaml.org,2002:python/tuple',
    PrettySafeLoader.construct_python_tuple)
yaml.Dumper.ignore_aliases = lambda *args : True

if not os.path.isfile("input/all_node.yaml"):
    print("WARN: input/all_node.yaml not found, using default template")
    shutil.copyfile("all_node.yaml", "input/all_node.yaml", follow_symlinks=True)
    
if not os.path.isfile("input/generate_config_func.py"):
    print("WARN: input/generate_config_func.py not found, using default template")
    shutil.copyfile("generate_config_func.py", "input/generate_config_func.py", follow_symlinks=True)

from input.generate_config_func import *
    
gen_conf = ruamel.yaml.safe_load(open("input/all_node.yaml").read())

if os.path.isfile("input/state.yaml"):
    vars_load(yaml.load(open("input/state.yaml").read(), Loader=PrettySafeLoader))

for k,v in gen_conf["node_list"].items():
    gen_conf["node_list"][k]["param"] = {}
    for dk, dv in gen_conf["defaults"].items():
        if dk not in gen_conf["node_list"][k]:
            gen_conf["node_list"][k][dk] = dv
        elif type(dv) == dict:
            gen_conf["node_list"][k][dk] = {**dv, **gen_conf["node_list"][k][dk]}

net4 = IPv4Network(gen_conf["network"]["v4"]) if gen_conf["network"]["v4"]!= None else None
net6 = IPv6Network(gen_conf["network"]["v6"])
net6ll = IPv6Address(gen_conf["network"]["v6ll"])

def prefixlen(net):
    if net == None:
        return None
    return net.prefixlen

result = {gen_conf["node_list"][n]["name"]:{"igp_tunnels":{},"peers_iface":{},"bird/ibgp.conf":[],"bird/ibgp.conf.j2":"","resolvips":{},"ups":{},"updates":{},"reconnects":{},"downs":{},"self_net":{}} for n in gen_conf["node_list"]}

def get_iface_full(name,af):
    n = gen_conf["iface_prefix"] + "-" + name + af
    if len(n) >= 16:
        raise ValueError(f"The interface name: {n} must be less than 16 (IFNAMSIZ) bytes.")
    return n

def get_tun(af,node, id2):
    node_tun_info = {**gen_conf["defaults"]["tunnel"][af], **node["tunnel"][af]}
    if id2 not in node_tun_info:
        return node_tun_info[-1] , 1
    return node_tun_info[id2] , 0

def get_bash_var_name(strin):
    allowed = set( string.ascii_letters + string.digits + "_" )
    return "".join(map(lambda x: x if x in allowed else "_" , strin))

for id, node in gen_conf["node_list"].items():
    os.makedirs(gen_conf["output_dir"] + "/" + node["name"], exist_ok=True)
    os.makedirs(gen_conf["output_dir"] + "/" + node["name"] + "/igp_tunnels", exist_ok=True)
    os.makedirs(gen_conf["output_dir"] + "/" + node["name"] + "/bird", exist_ok=True)

def get_net(ip,length):
    if ip == None:
        return None
    return ipaddress.ip_interface(str(ip) + "/" + str(length)).network

for id, node in gen_conf["node_list"].items():
    for id2, node2 in gen_conf["node_list"].items():
        if id == id2:
            continue
        result[node["name"]]["bird/ibgp.conf"] += [{ "name": get_bash_var_name(gen_conf["iface_prefix"] + "-" + node2["name"]) ,"ip":get_v6(id2,net6) }]

        for af, end in node["endpoints"].items():
            if af not in node2["endpoints"]: # process only if both side has same af
                continue
            if node["endpoints"][af] == "NAT" and node2["endpoints"][af] == "NAT": # skip if both side are NATed
                continue
            tuntype1, wildcard1 = get_tun(af,node,id2)
            tuntype2, wildcard2 = get_tun(af,node2,id)
            if (wildcard1,tunnelist.index(tuntype1)) > (wildcard2,tunnelist.index(tuntype2)):
                tuntype = tuntype2
            else:
                tuntype = tuntype1
            if tuntype1 != tuntype2:
                print("WARN: {af}: Tunnel type not match: {s}->{e}:{t1} , {e}->{s}:{t2}, selecting {tun}".format(af=af,s=node["name"],e=node2["name"],t1=tuntype1,t2=tuntype2,tun=tuntype))
            if tuntype == None:
                continue
            #print(node["name"],">",node2["name"])
            side_a = {
                **node,
                "id": id,
                "ifname": get_iface_full(node["name"],af),
                "endpoint": node["endpoints"][af],
                "endpoint_ip": "$ip_" + get_bash_var_name(node["name"] + af),
                "params": node["param"][tuntype] if tuntype in node["param"] else None
            }
            side_b = {
                **node2,
                "id": id2,
                "ifname": get_iface_full(node2["name"],af),
                "endpoint": node2["endpoints"][af],
                "endpoint_ip": "$ip_" + get_bash_var_name(node2["name"] + af),
                "params": node2["param"][tuntype] if tuntype in node2["param"] else None
            }
            
            setiptemplate = jinja2.Template(open('setip.sh').read())
            MTU = min(node["MTU"],node2["MTU"])
            MTU -= af_info[af]["MTU"]
            if side_a["endpoint"] == "NAT":
                continue
            try:
                if side_b["endpoint"] == "NAT" or (node["server_perf"],id) >= (node2["server_perf"],id2):
                    aconf, bconf = tunnels[tuntype](side_a,side_b)
                else:
                    bconf, aconf = tunnels[tuntype](side_b,side_a)
                MTU -= aconf["MTU"]
                def postprocess(conf,side,idd,nod,side2):
                    integrate_up = True
                    if "{{setupippath}}" in conf["up"].replace(" ",""):
                        integrate_up = False
                    conf["up"] = f'{get_bash_var_name(side2["endpoint_ip"][1:])}=$(resolveip {side2["endpoint"]})\n' + conf["up"] if side2["endpoint"] != "NAT" else conf["up"]
                    if integrate_up:
                        conf["up"] += "\n" + setiptemplate.render(ifname=side2["ifname"],MTU=MTU,ipv4=get_v4(idd,net4),ipv4net= get_v4(0,net4),ipv6=get_v6(idd,net6),ipv6ll=get_v6ll(idd,net6ll),v4_prefixlen=prefixlen(net4))
                    else:
                        setupipsh = "#!/bin/bash\n"
                        setupipsh += setiptemplate.render(ifname=side2["ifname"],MTU=MTU,ipv4=get_v4(idd,net4),ipv4net= get_v4(0,net4),ipv6=get_v6(idd,net6),ipv6ll=get_v6ll(idd,net6ll),v4_prefixlen=prefixlen(net4))
                        setupipsh = jinja2.Template(setupipsh).render(confpath = side2["ifname"],setupippath="igp_tunnels/" + side2["ifname"]+"_setip.sh",v4_prefixlen=prefixlen(net4))
                        conf["confs"]["_setip.sh"] = setupipsh
                    # resolvip
                    conf["resolvip"] = ""
                    if side2["endpoint"] != "NAT":
                        conf["resolvip"] = f'{get_bash_var_name(side2["endpoint_ip"][1:])}=$(resolveip {side2["endpoint"]})'
                    # up
                    conf["up"] = jinja2.Template(conf["up"]).render(confpath = "igp_tunnels/" + side2["ifname"],setupippath="igp_tunnels/" + side2["ifname"]+"_setip.sh",v4_prefixlen=prefixlen(net4))
                    conf["up"] = "\n".join(filter(None,conf["up"].split("\n"))) + "\n"
                    # update
                    if side2["DDNS"] == True:
                        conf["update"] = "\n".join(filter(None,conf["update"].split("\n"))) + "\n"
                        conf["update"] = jinja2.Template(conf["update"]).render(confpath = "igp_tunnels/" + side2["ifname"])
                    else:
                        conf["update"] = ""
                    # down
                    conf["down"] = jinja2.Template(conf["down"]).render(confpath = "igp_tunnels/" + side2["ifname"])
                    # reconnect
                    conf["reconnect"] = "\n".join(filter(None,conf["reconnect"].split("\n"))) + "\n"
                    conf["reconnect"] = jinja2.Template(conf["reconnect"]).render(confpath = "igp_tunnels/" + side2["ifname"])
                    conf["reconnect_info"] = {"ip":get_v6ll(side2["id"] ,net6ll),"ifname":side2["ifname"],"script":conf["reconnect"]}
                    for ck,cv in conf["confs"].items():
                        conf["confs"][ck] = jinja2.Template(cv).render(confpath = "igp_tunnels/" + side2["ifname"])
                postprocess(aconf,side_a,id,node,side_b)
                postprocess(bconf,side_b,id2,node2,side_a)
            except ValueError as e:
                print("WARN: " + str(e))
                continue
            if "confs" in aconf:
                result[gen_conf["node_list"][id ]["name"]]["igp_tunnels"][side_b["ifname"]] = aconf["confs"]
                result[gen_conf["node_list"][id ]["name"]]["peers_iface"][side_b["ifname"]] = str(get_v6ll(id2,net6ll))
            if "confs" in bconf:
                result[gen_conf["node_list"][id2]["name"]]["igp_tunnels"][side_a["ifname"]] = bconf["confs"]
                result[gen_conf["node_list"][id2]["name"]]["peers_iface"][side_a["ifname"]] = str(get_v6ll(id ,net6ll))
            result[gen_conf["node_list"][id ]["name"]]["id"] = id
            result[gen_conf["node_list"][id2]["name"]]["id"] = id2
            result[gen_conf["node_list"][id ]["name"]]["ups"][str(id2).zfill(3) + af] = aconf["up"]
            result[gen_conf["node_list"][id2]["name"]]["ups"][str(id ).zfill(3) + af] = bconf["up"]
            result[gen_conf["node_list"][id ]["name"]]["resolvips"][str(id2).zfill(3) + af] = aconf["resolvip"]
            result[gen_conf["node_list"][id2]["name"]]["resolvips"][str(id ).zfill(3) + af] = bconf["resolvip"]
            result[gen_conf["node_list"][id ]["name"]]["updates"][str(id2).zfill(3) + af] = aconf["update"]
            result[gen_conf["node_list"][id2]["name"]]["updates"][str(id ).zfill(3) + af] = bconf["update"]
            result[gen_conf["node_list"][id ]["name"]]["reconnects"][str(id2).zfill(3) + af] = aconf["reconnect_info"]
            result[gen_conf["node_list"][id2]["name"]]["reconnects"][str(id ).zfill(3) + af] = bconf["reconnect_info"]
            result[gen_conf["node_list"][id ]["name"]]["downs"][str(id2).zfill(3) + af] = aconf["down"]
            result[gen_conf["node_list"][id2]["name"]]["downs"][str(id ).zfill(3) + af] = bconf["down"]
            result[gen_conf["node_list"][id2]["name"]]["self_net"] = {"v4": str(get_net(get_v4(id2,net4) , 32)) , "v6": str(get_net(get_v6(id2,net6), 64))}
            result[gen_conf["node_list"][id2]["name"]]["self_ip"] = {"v4": get_v4(id2,net4) , "v6": get_v6(id2,net6)}


for s,sps in result.items():
    for e , confs in sps["igp_tunnels"].items():
        for ext, content in confs.items():
            open(gen_conf["output_dir"] + "/" + s + "/igp_tunnels/" + e + ext , "w").write(content)
            if ext.endswith(".sh"):
                os.chmod(gen_conf["output_dir"] + "/" + s + "/igp_tunnels/" + e + ext, 0o755)
    render_params = {
        'allow_nets_v4': gen_conf["network"]["v4"],
        'allow_nets_v6': gen_conf["network"]["v6"],
        'ipv4': get_v4(sps["id"],net4),
        'ipv4net': get_v4(0,net4),
        'ipv6': get_v6(sps["id"],net6),
        'v4_prefixlen': prefixlen(net4),
        'v6_prefixlen': prefixlen(net6),
        'netname': gen_conf["iface_prefix"],
        'area_id': gen_conf["area_id"],
        'interfaces': [{ "name": iface,"cost": 100 } for iface in sps["igp_tunnels"].keys()],
        'resolvips' : list(filter(None,sps["resolvips"].values())),
        'updates' : list(filter(None,sps["updates"].values())),
        'reconns' : list(filter(lambda x:x["script"] != "",sps["reconnects"].values())),
        'downs' : list(sps["downs"].values()),
        'interfaces_ibgp' : sps["bird/ibgp.conf"],
        'ups' : list(sps["ups"].values()),
        'self_ip' : sps["self_ip"],

    }
    ospftemplate = jinja2.Template(open('ospf.conf').read())
    ospfconf = ospftemplate.render(**render_params)
    render_params['interfaces'] = [{ "name": iface,"cost":"{{ cost." + iface.replace("-","_") + " }}"} for iface in sps["igp_tunnels"].keys()]
    ospfconf_temp = ospftemplate.render(**render_params)
    open(gen_conf["output_dir"] + "/" + s + "/bird/ospf_" + gen_conf["iface_prefix"] + ".conf" , "w").write(ospfconf)
    open(gen_conf["output_dir"] + "/" + s + "/bird/ospf_" + gen_conf["iface_prefix"] + ".conf.j2" , "w").write(ospfconf_temp)
    open(gen_conf["output_dir"] + "/" + s + "/up.sh" , "w").write( jinja2.Template(open('up.sh').read()).render(**render_params))
    os.chmod(gen_conf["output_dir"] + "/" + s + "/up.sh" , 0o755)
    open(gen_conf["output_dir"] + "/" + s + "/update.sh" , "w").write( jinja2.Template(open('update.sh').read()).render(**render_params))
    os.chmod(gen_conf["output_dir"] + "/" + s + "/update.sh" , 0o755)
    open(gen_conf["output_dir"] + "/" + s + "/down.sh" , "w").write( jinja2.Template(open('down.sh').read()).render(**render_params))
    os.chmod(gen_conf["output_dir"] + "/" + s + "/down.sh" , 0o755)
    open(gen_conf["output_dir"] + "/" + s + "/bird/ibgp_" + gen_conf["iface_prefix"] +".conf" , "w").write( jinja2.Template(open('bird_ibgp.conf').read()).render( **render_params ) )
    
    update_cost_template = jinja2.Template(open('update_cost.py').read())
    update_cost = update_cost_template.render(net_name= gen_conf["iface_prefix"],clients= json.dumps(sps["peers_iface"]))
    open(gen_conf["output_dir"] + "/" + s + "/update_cost.py" , "w").write(update_cost)
    os.chmod(gen_conf["output_dir"] + "/" + s + "/update_cost.py" , 0o755)
    open(gen_conf["output_dir"] + "/" + s + "/.gitignore" , "w").write("bird/ospf_" + gen_conf["iface_prefix"] + ".conf\n")

open("input/state.yaml","w").write(ruamel.yaml.dump(vars_dump()))
