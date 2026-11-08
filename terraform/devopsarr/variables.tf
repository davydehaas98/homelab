variable "lidarr_api_key" {
  description = "Lidarr API key"
  type        = string
  sensitive   = true
}

variable "lidarr_discord_web_hook_url" {
  description = "Discord webhook URL for the Lidarr notifications"
  type        = string
  sensitive   = true
}

variable "nzbgeek_api_key" {
  description = "NZBgeek API key, for the indexer in Prowlarr"
  type        = string
  sensitive   = true
}

variable "prowlarr_api_key" {
  description = "Prowlarr API key"
  type        = string
  sensitive   = true
}

variable "radarr_api_key" {
  description = "Radarr API key"
  type        = string
  sensitive   = true
}

variable "radarr_discord_web_hook_url" {
  description = "Discord webhook URL for the Radarr notifications"
  type        = string
  sensitive   = true
}

variable "sabnzbd_api_key" {
  description = "SABnzbd API key"
  type        = string
  sensitive   = true
}

variable "sonarr_api_key" {
  description = "Sonarr API key"
  type        = string
  sensitive   = true
}

variable "sonarr_discord_web_hook_url" {
  description = "Discord webhook URL for the Sonarr notifications"
  type        = string
  sensitive   = true
}
