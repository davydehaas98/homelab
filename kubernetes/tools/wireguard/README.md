# WireGuard

Not deployed (`deploy: false`). WireGuard VPN with a web interface (wg-easy). The VPN port is UDP 51820 on
`192.168.1.61`, a LoadBalancer address. The admin interface (port 51821) has no route: use
`kubectl -n wireguard port-forward statefulset/wireguard 51821`.

The private gateway holds `.61` now, so choose another free address of the Cilium pool first.

Setup, in order:

1. Sync the Cilium app, if the address needs a change in its pool.
2. Set `deploy: true` in `argocd.yaml`, push, and open the interface through the port-forward. The setup wizard asks for
   the admin account, the public host and the port.
3. Check the interface settings: the device should be `eth0`, and turn IPv6 off if the pod has none.
4. Forward UDP 51820 to `192.168.1.61`, on the UniFi gateway and on any modem in front of it.
5. Add the clients in the interface.
