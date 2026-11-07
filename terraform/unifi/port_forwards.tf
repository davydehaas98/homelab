# To the public Envoy Gateway (kubernetes/core/envoy-gateway); UDP 443 is HTTP/3
resource "unifi_port_forward" "yggdrasil" {
  name     = "yggdrasil"
  protocol = "tcp_udp"

  wan = {
    interface = "wan"
    port      = "80,443"
  }

  forward = {
    ip   = "192.168.1.56"
    port = "80,443"
  }
}

# To Plex on midgard-0's host network (kubernetes/media-server/plex)
resource "unifi_port_forward" "plex" {
  name     = "Home server"
  protocol = "tcp_udp"

  wan = {
    interface = "wan"
    port      = "32400"
  }

  forward = {
    ip   = "192.168.1.44"
    port = "32400"
  }
}
