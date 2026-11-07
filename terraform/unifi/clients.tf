# Fixed addresses of the nodes and the Turing Pi's BMC on the Servers VLAN, keeping the last part of their old LAN
# address. The RK1 nodes and the BMC share switch port 3, which is untagged Servers as the Turing Pi's switch drops VLAN
# tags. The provider cannot move a reservation back to the LAN: forget the client in the UI and recreate it there.
locals {
  nodes = {
    "jotunheim-0" = { mac = "42:a3:a2:79:b6:fa", host = 50 }
    "jotunheim-1" = { mac = "26:e1:b4:9c:50:00", host = 51 }
    "jotunheim-2" = { mac = "ee:9f:ac:f3:14:a5", host = 52 }
    "jotunheim-3" = { mac = "22:f5:26:e3:b3:16", host = 53 }
    "turingpi"    = { mac = "02:00:4a:d1:bd:cf", host = 54 }
    "midgard-0"   = { mac = "a8:a1:59:26:4c:4a", host = 44 }
    "vanaheim-0"  = { mac = "dc:a6:32:bf:45:b4", host = 45 }
  }
}

resource "unifi_client" "node" {
  for_each = local.nodes

  mac            = each.value.mac
  name           = each.key
  network_id     = unifi_network.servers.id
  fixed_ip       = "192.168.10.${each.value.host}"
  allow_existing = true
}

# Smart devices on the IoT VLAN, keeping the last part of their LAN address. A device moves at the apply, by its MAC,
# and needs a new lease there: reconnect it, or restart it when wired.
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
