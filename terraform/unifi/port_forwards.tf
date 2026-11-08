# To the public Envoy Gateway (kubernetes/core/envoy-gateway) on its L2 address on the Servers VLAN: the gateway does not
# forward to an address outside its own networks, such as Envoy's BGP address; UDP 443 is HTTP/3
resource "unifi_port_forward" "yggdrasil" {
  name     = "yggdrasil"
  protocol = "tcp_udp"

  wan = {
    interface = "wan"
    port      = "80,443"
  }

  forward = {
    ip   = cidrhost(local.subnets.servers, 56)
    port = "80,443"
  }
}

# To Plex on midgard-0's host network (kubernetes/media-server/plex)
resource "unifi_port_forward" "plex" {
  name     = "Plex"
  protocol = "tcp_udp"

  wan = {
    interface = "wan"
    port      = "32400"
  }

  forward = {
    ip   = local.midgard_ip
    port = "32400"
  }
}
