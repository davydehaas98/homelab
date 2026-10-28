variable "lidarr_api_key" {
  description = "Lidarr API key"
  sensitive   = true
}

variable "lidarr_discord_web_hook_url" {
  description = "Discord webhook URL for the Lidarr notifications"
  sensitive   = true
}

variable "nzbgeek_api_key" {
  description = "NZBgeek API key, for the indexer in Prowlarr"
  sensitive   = true
}

variable "prowlarr_api_key" {
  description = "Prowlarr API key"
  sensitive   = true
}

variable "radarr_api_key" {
  description = "Radarr API key"
  sensitive   = true
}

variable "radarr_discord_web_hook_url" {
  description = "Discord webhook URL for the Radarr notifications"
  sensitive   = true
}

variable "sabnzbd_api_key" {
  description = "SABnzbd API key"
  sensitive   = true
}

variable "sonarr_api_key" {
  description = "Sonarr API key"
  sensitive   = true
}

variable "sonarr_discord_web_hook_url" {
  description = "Discord webhook URL for the Sonarr notifications"
  sensitive   = true
}
