
wireguard-tools:
  pkg.installed


{%- for ifname, config in wireguard.get(grains["id"], {}).items() %}

  {% set keepalive = config.get("defaults", wireguard.get("defaults", {})).get("keepalive","0") %}
  {% set rttable = config.get("defaults", wireguard.get("defaults", {})).get("rttable","off") %}

  {%- for p in config.get("peer",[]) %}

    {%- do p.setdefault("keepalive", keepalive) %}
    {%- do p.setdefault("rttable", rttable) %}

    {%- if "interconnect" in p %}

      {%- set int_peer_info = p.pop("interconnect").split(":") %}
      {%- set int_peer_name = int_peer_info[0] %}
      {%- if int_peer_info | length == 1 %}
         {%- set int_peer_ifname = wireguard.get(int_peer_name,{}).keys() | first %}
      {%- else %}
         {%- set int_peer_ifname = int_peer_info[1] %}
      {%- endif %}
      {%- set int_peer_ifconf = wireguard.get(int_peer_name,{}).get(int_peer_ifname, none) %}
      {%- if not int_peer_ifconf %}
          {{ raise("Error in interconnection settings! Seems interconnect peer '"~ int_peer_name ~"' has no '"~ int_peer_ifname ~"' interface.") }}
      {%- endif %}


      {%- do p.setdefault("comment", int_peer_name) %}
      {%- do p.setdefault("publickey", int_peer_ifconf["publickey"]) %}
      {%- do p.setdefault("allowedips", int_peer_ifconf["address"].split("/")[0] ~ "/32") %}
      {%- if "endpoint" in int_peer_ifconf.keys() %}
        {%- do p.setdefault("endpoint", int_peer_ifconf["endpoint"] ~ ":" ~ int_peer_ifconf["listen"]) %}
      {%- endif %}

    {%- endif %}
  {%- endfor %}

  {% if config.get("type","systemd") == "systemd" %}
/etc/systemd/network/{{ ifname }}.network:
  file.managed:
    - source: salt://wireguard/{{ version }}/network.tmpl
    - template: jinja
    - context:
        ifname: {{ ifname }}
        config: {{ config }}

/etc/systemd/network/{{ ifname }}.netdev:
  file.managed:
    - source: salt://wireguard/{{ version }}/netdev.tmpl
    - template: jinja
    - context:
        ifname: {{ ifname }}
        config: {{ config }}

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

  {% elif config.get("type") == "wg-quick" %}

/etc/wireguard/{{ ifname }}.conf:
  file.managed:
    - source: salt://wireguard/{{ version }}/wg-quick.tmpl
    - template: jinja
    - context:
        ifname: {{ ifname }}
        config: {{ config }}

systemd_enable_wg-quick_{{ ifname }}:
  cmd.run:
    - name: "systemctl enable wg-quick@{{ ifname }}; systemctl restart wg-quick@{{ ifname }}"
    - onchanges:
      - file: /etc/wireguard/{{ ifname }}.conf
  {% endif %}

{%- endfor %}
