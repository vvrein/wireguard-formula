wireguard-tools:
  pkg.installed

{%- if pillar["wireguard"] is defined %}

  {%- for ifname, config in pillar["wireguard"].get("systemd",{}).items() %}
      {%- for p in config.get("peer",[]) %}
        {%- if "interconnect" in p.keys() %}
           {%- set inter_p = p.pop("interconnect") %}
           {%- do p.setdefault("publickey", inter_p["publickey"]) %}
           {%- do p.setdefault("allowedips", inter_p["address"].split("/")[0] ~ "/32") %}
           {%- if "endpoint"  in inter_p.keys() %}
             {%- do p.setdefault("endpoint", inter_p["endpoint"] ~ ":" ~ inter_p["listen"]) %}
           {%- endif %}
        {%- endif %}
      {%- endfor %}


/etc/systemd/network/{{ ifname }}.network:
  file.managed:
    - source: salt://wireguard/{{ ver }}/network.tmpl
    - template: jinja
    - context:
        ifname: {{ ifname }}
        config: {{ config | tojson }}

/etc/systemd/network/{{ ifname }}.netdev:
  file.managed:
    - source: salt://wireguard/{{ ver }}/netdev.tmpl
    - template: jinja
    - context:
        ifname: {{ ifname }}
        config: {{ config | tojson }}

{%- if pillar.get("with_delete", False) %}
networkctl_delete_{{ ifname }}:
  cmd.run:
    - name: networkctl delete {{ ifname }}
    - onchanges:
      - file: /etc/systemd/network/{{ ifname }}.network
      - file: /etc/systemd/network/{{ ifname }}.netdev
{%- endif %}

networkctl_reload_{{ ifname }}:
  cmd.run:
    - name: networkctl reload
    - onchanges:
      - file: /etc/systemd/network/{{ ifname }}.network
      - file: /etc/systemd/network/{{ ifname }}.netdev

wg_syncconf_for_{{ ifname }}:
  cmd.run:
    - name: "wg syncconf {{ ifname }} <(sed -nEe 's/WireGuardPeer/Peer/gp;s/WireGuard/Interface/gp;/ListenPort|PrivateKey|PublicKey|AllowedIPs|Endpoint|PersistentKeepalive/p'  /etc/systemd/network/{{ ifname }}.netdev)"
    - onchanges:
      - file: /etc/systemd/network/{{ ifname }}.network
      - file: /etc/systemd/network/{{ ifname }}.netdev

  {%- endfor %}

  {%- for ifname, config in pillar["wireguard"].get("wg-quick",{}).items() %}
      {%- for p in config.get("peer",[]) %}
        {%- if "interconnect" in p.keys() %}
           {%- set inter_p = p.pop("interconnect") %}
           {%- do p.setdefault("publickey", inter_p["publickey"]) %}
           {%- do p.setdefault("allowedips", inter_p["address"].split("/")[0] ~ "/32") %}
           {%- if "endpoint"  in inter_p.keys() %}
             {%- do p.setdefault("endpoint", inter_p["endpoint"]) %}
           {%- endif %}
        {%- endif %}
      {%- endfor %}

/etc/wireguard/{{ ifname }}.conf:
  file.managed:
    - source: salt://wireguard/{{ ver }}/wg-quick.tmpl
    - template: jinja
    - context:
        ifname: {{ ifname }}
        config: {{ config | tojson }}

systemd_enable_wg-quick_{{ ifname }}:
  cmd.run:
    - name: "systemctl enable wg-quick@{{ ifname }}; systemctl restart wg-quick@{{ ifname }}"
    - onchanges:
      - file: /etc/wireguard/{{ ifname }}.conf

  {%- endfor %}
{%- endif %}
