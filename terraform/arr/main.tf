terraform {
  required_version = "~> 1.15"

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

# The API is not behind the Authentik login (oidc.bypassPaths of the apps)
provider "lidarr" {
  url     = "https://lidarr.davydehaas.dev"
  api_key = var.lidarr_api_key
}

provider "prowlarr" {
  url     = "https://prowlarr.davydehaas.dev"
  api_key = var.prowlarr_api_key
}

provider "radarr" {
  url     = "https://radarr.davydehaas.dev"
  api_key = var.radarr_api_key
}

provider "sonarr" {
  url     = "https://sonarr.davydehaas.dev"
  api_key = var.sonarr_api_key
}
