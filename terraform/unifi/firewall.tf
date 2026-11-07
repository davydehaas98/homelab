# Exceptions to the isolation of the IoT VLAN: for midgard-0, whose host network Home Assistant, Zigbee2MQTT and
# Mosquitto use (pods leave the node with its address), and for the LAN. Policies come before the gateway's own
# "Isolated Networks" block.

# Home Assistant and Zigbee2MQTT to the devices, such as the SLZB-06 coordinator; the replies are allowed with it
resource "unifi_firewall_policy" "midgard_to_iot" {
  name                 = "midgard-0 to IoT"
  action               = "ALLOW"
  protocol             = "tcp_udp"
  ip_version           = "IPV4"
  create_allow_respond = true

  source = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "IP"
    ips                = ["192.168.10.44"]
    port_matching_type = "ANY"
  }
  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.iot.id]
    port_matching_type = "ANY"
  }
}

# The meter gateways publish to Mosquitto on midgard-0's hostPort (kubernetes/home/mosquitto)
resource "unifi_firewall_policy" "iot_to_mosquitto" {
  name                 = "IoT to Mosquitto"
  action               = "ALLOW"
  protocol             = "tcp"
  ip_version           = "IPV4"
  create_allow_respond = true

  source = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.iot.id]
    port_matching_type = "ANY"
  }
  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "IP"
    ips                = ["192.168.10.44"]
    port_matching_type = "SPECIFIC"
    port               = "1883"
  }
}

# The clients on the LAN to the devices' web pages and apps; the devices still can't start a connection to the LAN
resource "unifi_firewall_policy" "lan_to_iot" {
  name                 = "LAN to IoT"
  action               = "ALLOW"
  protocol             = "tcp_udp"
  ip_version           = "IPV4"
  create_allow_respond = true

  source = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.lan.id]
    port_matching_type = "ANY"
  }
  destination = {
    zone_id            = data.unifi_firewall_zone.internal.id
    matching_target    = "NETWORK"
    network_ids        = [unifi_network.iot.id]
    port_matching_type = "ANY"
  }
}
