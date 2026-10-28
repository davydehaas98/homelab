resource "prowlarr_application_sonarr" "sonarr" {
  anime_sync_categories = [5070]
  api_key               = var.sonarr_api_key
  base_url              = "http://sonarr:8989"
  name                  = "Sonarr"
  prowlarr_url          = "http://prowlarr:9696"
  sync_categories       = [5000, 5010, 5020, 5030, 5040, 5045, 5050]
  sync_level            = "fullSync"
  tags                  = []
}

resource "prowlarr_application_radarr" "radarr" {
  api_key         = var.radarr_api_key
  base_url        = "http://radarr:7878"
  name            = "Radarr"
  prowlarr_url    = "http://prowlarr:9696"
  sync_categories = [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060, 2070, 2080]
  sync_level      = "fullSync"
  tags            = []
}

resource "prowlarr_application_lidarr" "lidarr" {
  api_key         = var.lidarr_api_key
  base_url        = "http://lidarr:8686"
  name            = "Lidarr"
  prowlarr_url    = "http://prowlarr:9696"
  sync_categories = [3000, 3010, 3030, 3040, 3050, 3060]
  sync_level      = "fullSync"
  tags            = []
}

resource "prowlarr_sync_profile" "usenet" {
  enable_automatic_search   = true
  enable_interactive_search = true
  enable_rss                = true
  minimum_seeders           = 0
  name                      = "Usenet"
}

resource "prowlarr_indexer" "nzbgeek" {
  app_profile_id  = prowlarr_sync_profile.usenet.id
  config_contract = "NewznabSettings"
  enable          = true
  fields = [
    {
      name            = "apiKey"
      sensitive_value = var.nzbgeek_api_key
    },
    {
      name       = "apiPath"
      text_value = "/api"
    },
    {
      name         = "baseSettings.limitsUnit"
      number_value = 0
    },
    {
      name       = "baseUrl"
      text_value = "https://api.nzbgeek.info"
    },
    {
      name = "vipExpiration"
    },
  ]
  implementation = "Newznab"
  name           = "NZBgeek"
  priority       = 10
  protocol       = "usenet"
  redirect       = true
  tags           = []
}

