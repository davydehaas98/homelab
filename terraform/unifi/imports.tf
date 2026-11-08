# Adopts the settings on the gateway, so a lost state is rebuilt without duplicates; the IDs come from ids.sh. The
# clients need none, as allow_existing adopts them.

import {
  to = unifi_network.lan
  id = "68adf0094834f137f22b4277"
}

import {
  to = unifi_network.servers
  id = "6aef38a590a452520c7d65a5"
}

import {
  to = unifi_network.iptv
  id = "68b2cc39a5d9826f9b4723e9"
}

import {
  to = unifi_network.iot
  id = "68b2cd9ba5d9826f9b472450"
}

import {
  to = unifi_network.guest
  id = "6aef3be890a452520c7d6736"
}

import {
  to = unifi_wlan.main
  id = "68ae1b9238cccc0bd7e12911"
}

import {
  to = unifi_wlan.iot
  id = "69b7fa76ced232b12fe23d36"
}

import {
  to = unifi_wlan.guest
  id = "6aef3c4b90a452520c7d6766"
}

import {
  to = unifi_port_forward.yggdrasil
  id = "68ae189e38cccc0bd7e128bd"
}

import {
  to = unifi_port_forward.plex
  id = "6adc8a7a49d0991b2082328a"
}

import {
  to = unifi_bgp.cilium
  id = "6aef08e190a452520c7d5a4f"
}

import {
  to = unifi_firewall_policy.midgard_to_iot
  id = "6aef962f90a452520c7d80f9"
}

import {
  to = unifi_firewall_policy.iot_to_mosquitto
  id = "6aef962f90a452520c7d80ff"
}

import {
  to = unifi_firewall_policy.lan_to_iot
  id = "6aef96fa90a452520c7d813a"
}

import {
  for_each = local.switch_ports

  to = unifi_device_port.switch[each.key]
  id = "${local.switch_mac}/${each.key}"
}
