# WireGuard

Not deployed (`deploy: false`). WireGuard VPN with a web interface (wg-easy), replacing the one on the home server
(`home-stack/compose.wireguard.yaml`). It starts empty: the old interface, clients and keys are not copied, so every client gets a new configuration. The VPN
port is UDP 51820 on `192.168.1.61`, a LoadBalancer address. The admin interface (port 51821) has no route: use
`kubectl -n wireguard port-forward statefulset/wireguard 51821`.

Setup, in order:

1. `sudo sh lun.sh create wireguard 1G` on yggdrasil, and sync the Cilium app (its pool now includes `.61`).
2. Set `deploy: true` in `argocd.yaml`, push, and open the interface through the port-forward. The setup wizard asks for the admin
   account; set the host to `wireguard.davydehaas.nl` (it points at the public address) and the port to 51820.
3. Check the interface settings: the device should be `eth0`, and turn IPv6 off if the pod has none.
4. Forward UDP 51820 in UniFi to `192.168.1.61`; the only forward now has 22, 80, 443 and 32400, so there is none for
   51820. If the modem in front of UniFi does not pass UDP, forward it there to the UniFi WAN address too.
5. Add the clients in the interface and remove `compose.wireguard.yaml` from `home-server`, or its next deploy starts the
   old container again.
