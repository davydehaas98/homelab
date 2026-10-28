resource "sonarr_root_folder" "sonarr" {
  path = "/series"
}

resource "sonarr_naming" "sonarr" {
  anime_episode_format       = "{Series TitleYear} - S{season:00}E{episode:00} - {absolute:000} - {Episode CleanTitle} [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}[{Mediainfo AudioCodec} { Mediainfo AudioChannels}]{MediaInfo AudioLanguages}{-Release Group}"
  colon_replacement_format   = 3
  daily_episode_format       = "{Series TitleYear} - {Air-Date} - {Episode CleanTitle} [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{MediaInfo AudioLanguages}{[MediaInfo VideoCodec]}{-Release Group}"
  multi_episode_style        = 5
  rename_episodes            = true
  replace_illegal_characters = true
  season_folder_format       = "Season {season:00}"
  series_folder_format       = "{Series TitleYear} {[ImdbId]}"
  specials_folder_format     = "Specials"
  standard_episode_format    = "{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{MediaInfo AudioLanguages}{[MediaInfo VideoCodec]}{-Release Group}"
}

resource "sonarr_media_management" "sonarr" {
  chmod_folder                = "755"
  chown_group                 = ""
  create_empty_folders        = false
  delete_empty_folders        = true
  download_propers_repacks    = "doNotPrefer"
  enable_media_info           = true
  episode_title_required      = "bulkSeasonReleases"
  extra_file_extensions       = "srt"
  file_date                   = "none"
  hardlinks_copy              = true
  import_extra_files          = false
  minimum_free_space          = 100
  recycle_bin_days            = 7
  recycle_bin_path            = ""
  rescan_after_refresh        = "always"
  set_permissions             = false
  skip_free_space_check       = false
  unmonitor_previous_episodes = false
}

resource "sonarr_download_client_sabnzbd" "sabnzbd" {
  api_key                    = var.sabnzbd_api_key
  enable                     = true
  host                       = "sabnzbd"
  name                       = "SABnzbd"
  older_tv_priority          = 0
  port                       = 8080
  priority                   = 1
  recent_tv_priority         = 1
  remove_completed_downloads = true
  remove_failed_downloads    = true
  tags                       = []
  tv_category                = "series"
  use_ssl                    = false
}

resource "sonarr_delay_profile" "default" {
  bypass_if_above_custom_format_score = false
  bypass_if_highest_quality           = false
  enable_torrent                      = false
  enable_usenet                       = true
  minimum_custom_format_score         = 0
  order                               = 2147483647
  preferred_protocol                  = "usenet"
  tags                                = []
  torrent_delay                       = 0
  usenet_delay                        = 0
}

resource "sonarr_notification_discord" "discord" {
  grab_fields                        = [0, 1, 2, 3, 5, 6, 7, 8, 9]
  import_fields                      = [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12]
  include_health_warnings            = true
  name                               = "Discord"
  on_application_update              = false
  on_download                        = true
  on_episode_file_delete             = true
  on_episode_file_delete_for_upgrade = true
  on_grab                            = true
  on_health_issue                    = true
  on_health_restored                 = false
  on_import_complete                 = false
  on_manual_interaction_required     = false
  on_rename                          = true
  on_series_add                      = false
  on_series_delete                   = true
  on_upgrade                         = true
  tags                               = []
  web_hook_url                       = var.sonarr_discord_web_hook_url
}

resource "sonarr_metadata" "plex" {
  config_contract = "PlexMetadataSettings"
  enable          = true
  implementation  = "PlexMetadata"
  name            = "Plex"
  tags            = []
}

# Minimum sizes in MB per minute against fake and mislabelled releases, kept low as small HEVC encodes of series go
# down to about 4 at 1080p. A maximum of 1000 is no limit in practice; the provider cannot leave it empty.
locals {
  sonarr_quality_definitions = {
    "HDTV-720p"    = { id = 7, min_size = 3, preferred_size = 95, max_size = 125 }
    "WEBRip-720p"  = { id = 10, min_size = 3, preferred_size = 95, max_size = 130 }
    "WEBDL-720p"   = { id = 11, min_size = 3, preferred_size = 95, max_size = 130 }
    "Bluray-720p"  = { id = 12, min_size = 4, preferred_size = 95, max_size = 130 }
    "HDTV-1080p"   = { id = 8, min_size = 4, preferred_size = 95, max_size = 125 }
    "WEBRip-1080p" = { id = 13, min_size = 4, preferred_size = 95, max_size = 1000 }
    "WEBDL-1080p"  = { id = 14, min_size = 4, preferred_size = 95, max_size = 1000 }
    "Bluray-1080p" = { id = 15, min_size = 4, preferred_size = 95, max_size = 1000 }
    "HDTV-2160p"   = { id = 17, min_size = 35, preferred_size = 250, max_size = 1000 }
    "WEBRip-2160p" = { id = 18, min_size = 35, preferred_size = 250, max_size = 1000 }
    "WEBDL-2160p"  = { id = 19, min_size = 35, preferred_size = 250, max_size = 1000 }
    "Bluray-2160p" = { id = 20, min_size = 35, preferred_size = 250, max_size = 1000 }
  }
}

resource "sonarr_quality_definition" "this" {
  for_each = local.sonarr_quality_definitions

  id             = each.value.id
  title          = each.key
  min_size       = each.value.min_size
  preferred_size = each.value.preferred_size
  max_size       = each.value.max_size
}
