# The ports of the USW Lite 8 PoE whose native network is not the LAN; the other ports keep their settings in the UI,
# and a device on one of them gets its network from its reservation in clients.tf.
locals {
  switch_mac = "d0:21:f9:75:48:1c"

  switch_ports = {
    # The Turing Pi with the RK1 nodes and the BMC. Untagged, as the Turing Pi's switch drops VLAN tags: with another
    # native network here the nodes drop off the Servers VLAN.
    3 = { name = "Turing Pi", network_id = unifi_network.servers.id, poe_mode = "auto" }
    4 = { name = "vanaheim-0", network_id = unifi_network.servers.id, poe_mode = "auto" }
    7 = { name = "KPN TV Box", network_id = unifi_network.iptv.id, poe_mode = null }
  }
}

resource "unifi_device_port" "switch" {
  for_each = local.switch_ports

  device_mac            = local.switch_mac
  index                 = each.key
  name                  = each.value.name
  native_networkconf_id = each.value.network_id
  forward               = "customize"
  tagged_vlan_mgmt      = "auto"
  # The values the switch has; left out, the provider clears them
  poe_mode           = each.value.poe_mode
  setting_preference = "auto"
  stp_edge_state     = "auto"
}
