# Fixed addresses of the nodes and the Turing Pi's BMC, keeping the last part of the address on either network. A node
# moves to the Servers VLAN by setting servers = true when its switch port goes to untagged VLAN 10, not before: a
# reservation holds one network, and the node would lose its LAN address on the next lease. The RK1 nodes and the BMC
# share switch port 3 (the Turing Pi's switch drops VLAN tags), so they move together. A reservation on the LAN has no
# network_id, as the gateway refuses one for the default network, and the provider cannot move one back from Servers.
locals {
  nodes = {
    "jotunheim-0" = { mac = "42:a3:a2:79:b6:fa", host = 50, servers = true }
    "jotunheim-1" = { mac = "26:e1:b4:9c:50:00", host = 51, servers = true }
    "jotunheim-2" = { mac = "ee:9f:ac:f3:14:a5", host = 52, servers = true }
    "jotunheim-3" = { mac = "22:f5:26:e3:b3:16", host = 53, servers = true }
    "turingpi"    = { mac = "02:00:4a:d1:bd:cf", host = 54, servers = true }
    "midgard-0"   = { mac = "a8:a1:59:26:4c:4a", host = 44, servers = true }
    "vanaheim-0"  = { mac = "dc:a6:32:bf:45:b4", host = 45, servers = true }
  }
}

resource "unifi_client" "node" {
  for_each = local.nodes

  mac            = each.value.mac
  name           = each.key
  network_id     = each.value.servers ? unifi_network.servers.id : null
  fixed_ip       = "${each.value.servers ? "192.168.10" : "192.168.1"}.${each.value.host}"
  allow_existing = true
}

moved {
  from = unifi_client.jotunheim_3
  to   = unifi_client.node["jotunheim-3"]
}

moved {
  from = unifi_client.vanaheim_0
  to   = unifi_client.node["vanaheim-0"]
}

# Smart devices on the IoT VLAN, keeping the last part of their LAN address. Like a node, a device moves at the apply,
# by its MAC, and needs a new lease there: reconnect it, or restart it when wired.
locals {
  iot_devices = {
    "SLZB-06"                   = { mac = "94:54:c5:ea:2e:0f", host = 30 }
    "Smart-Gateways-P1"         = { mac = "2c:bc:bb:92:ec:dc", host = 172 }
    "Smart-Gateways-Watermeter" = { mac = "c0:5d:89:b1:c3:34", host = 196 }
  }
}

resource "unifi_client" "iot" {
  for_each = local.iot_devices

  mac            = each.value.mac
  name           = each.key
  network_id     = unifi_network.iot.id
  fixed_ip       = "192.168.15.${each.value.host}"
  allow_existing = true
}
