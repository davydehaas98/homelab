# The networks of the gateway, with the settings that differ between them written out; the rest keeps its value in the
# UI. All but Guest are in the Internal zone. The WireGuard server is a VPN, not a network this resource covers.

locals {
  # The gateway's address and prefix per network; the DHCP ranges and fixed addresses are hosts in it
  subnets = {
    lan     = "192.168.1.1/24"
    servers = "192.168.10.1/24"
    iptv    = "192.168.14.1/24"
    iot     = "192.168.15.1/24"
    guest   = "192.168.20.1/24"
  }
}

data "unifi_firewall_zone" "internal" {
  name = "Internal"
}

data "unifi_firewall_zone" "hotspot" {
  name = "Hotspot"
}

# The clients; DHCP hands out the gateway as DNS server
resource "unifi_network" "lan" {
  name             = "Default"
  purpose          = "corporate"
  subnet           = local.subnets.lan
  domain_name      = "localdomain"
  firewall_zone_id = data.unifi_firewall_zone.internal.id

  auto_scale        = false
  igmp_snooping     = false
  internet_access   = true
  multicast_dns     = true
  network_isolation = false

  dhcp_server = {
    enabled           = true
    start             = cidrhost(local.subnets.lan, 100)
    stop              = cidrhost(local.subnets.lan, 199)
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
  subnet           = local.subnets.servers
  firewall_zone_id = data.unifi_firewall_zone.internal.id

  igmp_snooping     = false
  internet_access   = true
  multicast_dns     = true
  network_isolation = false

  dhcp_server = {
    enabled           = true
    start             = cidrhost(local.subnets.servers, 100)
    stop              = cidrhost(local.subnets.servers, 200)
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
  subnet           = local.subnets.iptv
  firewall_zone_id = data.unifi_firewall_zone.internal.id

  auto_scale = true
  # The TV channels are multicast; this sends a stream only to the box that asked for it
  igmp_snooping     = true
  internet_access   = true
  multicast_dns     = false
  network_isolation = false

  dhcp_server = {
    enabled           = true
    start             = cidrhost(local.subnets.iptv, 6)
    stop              = cidrhost(local.subnets.iptv, 254)
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
  subnet           = local.subnets.iot
  firewall_zone_id = data.unifi_firewall_zone.internal.id

  auto_scale        = true
  igmp_snooping     = false
  internet_access   = true
  multicast_dns     = false
  network_isolation = true

  dhcp_server = {
    enabled           = true
    start             = cidrhost(local.subnets.iot, 100)
    stop              = cidrhost(local.subnets.iot, 199)
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

# Guests reach the internet only: the Hotspot zone blocks the other networks and the gateway's management
resource "unifi_network" "guest" {
  name             = "Guest"
  purpose          = "guest"
  vlan             = 20
  subnet           = local.subnets.guest
  firewall_zone_id = data.unifi_firewall_zone.hotspot.id

  igmp_snooping     = false
  internet_access   = true
  multicast_dns     = false
  network_isolation = false

  dhcp_server = {
    enabled = true
    start   = cidrhost(local.subnets.guest, 6)
    stop    = cidrhost(local.subnets.guest, 254)
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
