# Adopts the settings on the gateway, so a lost state is rebuilt without duplicates; the IDs come from ids.sh. The
# clients need none, as allow_existing adopts them.

import {
  to = unifi_network.lan
  id = "82c2d7ea-c038-4dae-814f-4b4408797d5c"
}

import {
  to = unifi_network.servers
  id = "5a6e544a-7fcf-4120-82ba-7725ef9b44db"
}

import {
  to = unifi_network.iptv
  id = "e797a8fd-38c4-4ca5-b1b5-f1a4d9f738e1"
}

import {
  to = unifi_network.iot
  id = "8a9541c1-2338-46f1-8ce1-776a20aab394"
}

import {
  to = unifi_network.guest
  id = "55a73b17-d13f-42eb-af58-bad8d690a813"
}

import {
  to = unifi_wlan.main
  id = "28543a19-707a-4b0c-b07c-af3232d5824a"
}

import {
  to = unifi_wlan.iot
  id = "1085e16f-dc0f-4cd0-b81b-f6ad0108ed11"
}

import {
  to = unifi_wlan.guest
  id = "9d857fb0-f5b1-4248-8f09-4149732d6dc5"
}

import {
  to = unifi_port_forward.yggdrasil
  id = "bc12aedd-7a66-4588-b18c-b20ef6ec8e93"
}

import {
  to = unifi_port_forward.plex
  id = "e6456f0b-6a33-46fe-83e3-f15c346aff37"
}

import {
  to = unifi_bgp.cilium
  id = "aa61468f-4ec1-41f1-bcd5-013ffe5400a7"
}

import {
  to = unifi_firewall_policy.midgard_to_iot
  id = "862c2bdf-b62f-4155-aec7-82e85934c4d2"
}

import {
  to = unifi_firewall_policy.iot_to_mosquitto
  id = "a3a48436-ac71-4c8f-953d-ff373236a80c"
}

import {
  to = unifi_firewall_policy.lan_to_iot
  id = "c6bb063f-bc5c-4466-a758-a00f6ae59fc3"
}

import {
  for_each = local.switch_ports

  to = unifi_device_port.switch[each.key]
  id = "${local.switch_mac}/${each.key}"
}
