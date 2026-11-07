variable "unifi_api_key" {
  description = "API key of the UniFi Network application on the gateway"
  sensitive   = true
}

variable "guest_wifi_passphrase" {
  description = "Passphrase of the guest Wi-Fi; raise passphrase_wo_version in wlan.tf to apply a new one"
  sensitive   = true
  ephemeral   = true
}
