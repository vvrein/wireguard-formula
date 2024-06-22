# pillar example

systemd case
```
wireguard:
  version: v20240330

  defaults: # optional
    keepalive: 60
    rttable: "off"

  hostname:
    ifname:
      defaults: # optional, per interface
        keepalive: 40
        rttable: "off"
      type: systemd # optional, the default
      listen: 51820 # optional, required for interconnection
      endpoint: <host or ip> # optional, requiered for interconnection
      privatekey: xxxx # required
      publickey: xxxx # optional
      address: x.x.x.x/x # required
      systemd.network: # optional, for systemd case. Can be used all sections from the `man systemd.network'
        RoutingPolicyRule: # creates routing table for routes 
          - Table: 1000 
        Route: # creates routes
          - Destination: 192.168.90.0/24 # required
            Gateway: 192.168.68.103 # optional
      peer:
        - comment: some peer comment # optional
          publickey: xxxx # required
          allowedips: x.x.x.x/x # required
          endpoint: x.x.x.x:51820 # optional
          keepalive: 25 # optional
          rttable: "off" # otional, does nothing in wg-quick mode

        - interconnect: hostname:ifname # :ifname can be ommited, then first ifname will be used from target 
          # interconnect will take [endpoint, pubblickey, address/32] from peer
          # any option can be overriden inplace

```

wg-quick case
```
wireguard:
  version: v20240330

  defaults: # optional
    keepalive: 60

  hostname:
    ifname:
      type: wg-quick # required for wg-quick
      listen: 51820 # optional, required for interconnection
      endpoint: <host or ip> # optional, requiered for interconnection
      privatekey: xxxx # required
      publickey: xxxx # optional
      address: x.x.x.x/x # required
      config: # for wg-quick case. Can be used all sections from the `man wg-quick'
        Table: main
        SaveConfig: true
        PostUp: ip rule add ....; iptables -A
        PostDown: ip rule del ....; iptables -D
      peer:
        - comment: some peer comment # optional
          publickey: xxxx # required
          allowedips: x.x.x.x/x # required
          endpoint: x.x.x.x:51820 # optional
          keepalive: 25 # optional
```
