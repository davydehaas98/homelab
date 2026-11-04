terraform {
  required_version = "~> 1.17"

  required_providers {
    lidarr = {
      source  = "devopsarr/lidarr"
      version = "1.13.0"
    }
    prowlarr = {
      source  = "devopsarr/prowlarr"
      version = "3.2.2"
    }
    radarr = {
      source  = "devopsarr/radarr"
      version = "2.5.0"
    }
    sonarr = {
      source  = "devopsarr/sonarr"
      version = "3.5.0"
    }
  }
}

# On the private gateway, so an apply needs the home network or the VPN
provider "lidarr" {
  url     = "https://lidarr.lan.davydehaas.dev"
  api_key = var.lidarr_api_key
}

provider "prowlarr" {
  url     = "https://prowlarr.lan.davydehaas.dev"
  api_key = var.prowlarr_api_key
}

provider "radarr" {
  url     = "https://radarr.lan.davydehaas.dev"
  api_key = var.radarr_api_key
}

provider "sonarr" {
  url     = "https://sonarr.lan.davydehaas.dev"
  api_key = var.sonarr_api_key
}
