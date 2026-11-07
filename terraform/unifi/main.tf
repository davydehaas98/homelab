terraform {
  required_version = "~> 1.17"

  required_providers {
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.65.0"
    }
  }
}

# The Gateway Ultra itself, on the home network; its certificate is self-signed
provider "unifi" {
  api_url        = "https://192.168.1.1"
  api_key        = var.unifi_api_key
  allow_insecure = true
}
