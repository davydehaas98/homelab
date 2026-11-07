# The networks of the gateway, with the settings that differ between them written out; the rest keeps its value in the
# UI. All are in the Internal zone. The WireGuard server is a VPN, not a network this resource covers.

data "unifi_firewall_zone" "internal" {
  name = "Internal"
}

# The clients; DHCP hands out the gateway as DNS server
resource "unifi_network" "lan" {
  name             = "Default"
  purpose          = "corporate"
  subnet           = "192.168.1.1/24"
  domain_name      = "localdomain"
  firewall_zone_id = data.unifi_firewall_zone.internal.id

  auto_scale        = false
  igmp_snooping     = false
  internet_access   = true
  multicast_dns     = true
  network_isolation = false

  dhcp_server = {
    enabled           = true
    start             = "192.168.1.100"
    stop              = "192.168.1.199"
    leasetime         = "24h0m0s"
    conflict_checking = true

    dns = {
      enabled = false
    }
  }

  ipv6 = {
    interface_type = "none"
  }
}

# The nodes, apart from the clients, so traffic to the BGP addresses passes the gateway both ways; they get
# reservations below the DHCP range
resource "unifi_network" "servers" {
  name             = "Servers"
  purpose          = "corporate"
  vlan             = 10
  subnet           = "192.168.10.1/24"
  firewall_zone_id = data.unifi_firewall_zone.internal.id

  igmp_snooping     = false
  internet_access   = true
  multicast_dns     = true
  network_isolation = false

  dhcp_server = {
    enabled           = true
    start             = "192.168.10.100"
    stop              = "192.168.10.200"
    leasetime         = "24h0m0s"
    conflict_checking = true

    dns = {
      enabled = false
    }
  }

  ipv6 = {
    interface_type = "none"
  }
}

resource "unifi_network" "iptv" {
  name             = "IPTV"
  purpose          = "corporate"
  vlan             = 4
  subnet           = "192.168.14.1/24"
  firewall_zone_id = data.unifi_firewall_zone.internal.id

  auto_scale = true
  # The TV channels are multicast; this sends a stream only to the box that asked for it
  igmp_snooping     = true
  internet_access   = true
  multicast_dns     = true
  network_isolation = false

  dhcp_server = {
    enabled           = true
    start             = "192.168.14.6"
    stop              = "192.168.14.254"
    leasetime         = "24h0m0s"
    conflict_checking = true

    dns = {
      enabled = false
    }
  }

  ipv6 = {
    interface_type = "none"
  }
}

# Isolated: its devices reach the internet, not each other or the other networks, apart from firewall.tf
resource "unifi_network" "iot" {
  name             = "IoT"
  purpose          = "corporate"
  vlan             = 2
  subnet           = "192.168.15.1/24"
  firewall_zone_id = data.unifi_firewall_zone.internal.id

  auto_scale        = true
  igmp_snooping     = false
  internet_access   = true
  multicast_dns     = true
  network_isolation = true

  dhcp_server = {
    enabled           = true
    start             = "192.168.15.6"
    stop              = "192.168.15.254"
    leasetime         = "24h0m0s"
    conflict_checking = true

    dns = {
      enabled = false
    }
  }

  ipv6 = {
    interface_type = "none"
  }
}

data "unifi_firewall_zone" "hotspot" {
  name = "Hotspot"
}

# Guests reach the internet only: the Hotspot zone blocks the other networks and the gateway's management
resource "unifi_network" "guest" {
  name             = "Guest"
  purpose          = "guest"
  vlan             = 20
  subnet           = "192.168.20.1/24"
  firewall_zone_id = data.unifi_firewall_zone.hotspot.id

  igmp_snooping     = false
  internet_access   = true
  multicast_dns     = false
  network_isolation = false

  dhcp_server = {
    enabled = true
    start   = "192.168.20.6"
    stop    = "192.168.20.254"
    # The gateway keeps a guest network at the default lease time
    leasetime         = "24h0m0s"
    conflict_checking = true

    dns = {
      enabled = false
    }
  }

  ipv6 = {
    interface_type = "none"
  }
}
