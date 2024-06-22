{% if pillar.get("wireguard") %}

  {% set wireguard = pillar["wireguard"] %}
  {% set version = wireguard.setdefault("version", "legacy") %}
  {% include "wireguard/" ~ version ~ "/init.sls" with context %}

{% endif %}
