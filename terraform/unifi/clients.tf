# Fixed addresses of the nodes, on the network each one is on. The nodes moved to the Servers VLAN keep the last part
# of their LAN address; the rest still have the reservation they got in the UI.
resource "unifi_client" "jotunheim_3" {
  mac            = "22:f5:26:e3:b3:16"
  name           = "jotunheim-3"
  network_id     = unifi_network.servers.id
  fixed_ip       = "192.168.10.53"
  allow_existing = true
}
