# The Wi-Fi networks of the U7 Lite. The passphrases are set in the UI and left out here, so they stay out of git.

locals {
  # The site's default user group, without bandwidth limits
  default_user_group_id = "68adf0094834f137f22b4278"

  # The default AP group, of all access points; the provider needs it set or a new WLAN fails its apply
  all_access_points = {
    ids  = ["68adf0094834f137f22b427d"]
    mode = "all"
  }
}

# WPA2 and WPA3 side by side: newer clients use WPA3, older ones keep WPA2. PMF is optional, as WPA3 requires.
resource "unifi_wlan" "main" {
  name          = "Bierdopje"
  security      = "wpapsk"
  network_id    = unifi_network.lan.id
  user_group_id = local.default_user_group_id
  ap_group      = local.all_access_points
  wlan_bands    = ["2g", "5g"]

  pmf_mode = "optional"

  wpa = {
    mode = "wpa2"
  }

  wpa3 = {
    support    = true
    transition = true
  }
}

# WPA2 only and without PMF, as many smart devices handle neither WPA3 nor PMF; enhanced IoT connectivity keeps it so
resource "unifi_wlan" "iot" {
  name          = "Bierdopje IoT"
  security      = "wpapsk"
  network_id    = unifi_network.iot.id
  user_group_id = local.default_user_group_id
  ap_group      = local.all_access_points
  wlan_bands    = ["2g"]

  enhanced_iot = true
  pmf_mode     = "disabled"

  wpa = {
    mode = "wpa2"
  }

  wpa3 = {
    support    = false
    transition = false
  }
}

# Guests can't see each other either; the passphrase comes from terraform.tfvars and is never written to the state
resource "unifi_wlan" "guest" {
  name          = "Bierdopje Guest"
  security      = "wpapsk"
  network_id    = unifi_network.guest.id
  user_group_id = local.default_user_group_id
  ap_group      = local.all_access_points
  wlan_bands    = ["2g", "5g"]
  is_guest      = true
  l2_isolation  = true

  passphrase_wo         = var.guest_wifi_passphrase
  passphrase_wo_version = 1

  pmf_mode = "optional"

  wpa = {
    mode = "wpa2"
  }

  wpa3 = {
    support    = true
    transition = true
  }
}
