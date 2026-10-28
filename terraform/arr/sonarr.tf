resource "sonarr_root_folder" "sonarr" {
  path = "/series"
}

resource "sonarr_naming" "sonarr" {
  anime_episode_format       = "{Series TitleYear} - S{season:00}E{episode:00} - {absolute:000} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}[{Mediainfo AudioCodec} { Mediainfo AudioChannels}]{MediaInfo AudioLanguages}{-Release Group}"
  colon_replacement_format   = 3
  daily_episode_format       = "{Series TitleYear} - {Air-Date} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{MediaInfo AudioLanguages}{[MediaInfo VideoCodec]}{-Release Group}"
  multi_episode_style        = 5
  rename_episodes            = true
  replace_illegal_characters = true
  season_folder_format       = "Season {season:00}"
  series_folder_format       = "{Series TitleYear} {[ImdbId]}"
  specials_folder_format     = "Specials"
  standard_episode_format    = "{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{MediaInfo AudioLanguages}{[MediaInfo VideoCodec]}{-Release Group}"
}

resource "sonarr_media_management" "sonarr" {
  chmod_folder                = "755"
  chown_group                 = ""
  create_empty_folders        = false
  delete_empty_folders        = true
  download_propers_repacks    = "preferAndUpgrade"
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

resource "sonarr_download_client_config" "sonarr" {
  auto_redownload_failed             = true
  enable_completed_download_handling = true
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

resource "sonarr_indexer_config" "sonarr" {
  maximum_size      = 0
  minimum_age       = 0
  retention         = 0
  rss_sync_interval = 15
}

resource "sonarr_delay_profile" "default" {
  bypass_if_above_custom_format_score = false
  bypass_if_highest_quality           = false
  enable_torrent                      = true
  enable_usenet                       = true
  minimum_custom_format_score         = 0
  order                               = 2147483647
  preferred_protocol                  = "usenet"
  tags                                = []
  torrent_delay                       = 10
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

resource "sonarr_custom_format" "hevc" {
  include_custom_format_when_renaming = true
  name                                = "HEVC"
  specifications = [
    {
      implementation = "ReleaseTitleSpecification"
      name           = "HEVC"
      negate         = false
      required       = true
      value          = "(((X|H)\\.?265)|(HEVC))"
    },
  ]
}

resource "sonarr_custom_format" "avc" {
  include_custom_format_when_renaming = true
  name                                = "AVC"
  specifications = [
    {
      implementation = "ReleaseTitleSpecification"
      name           = "AVC"
      negate         = false
      required       = true
      value          = "((X|H)\\.?264)|(AVC)"
    },
  ]
}

resource "sonarr_custom_format" "surround_sound" {
  include_custom_format_when_renaming = true
  name                                = "SS"
  specifications = [
    {
      implementation = "ReleaseTitleSpecification"
      name           = "Surround Sound"
      negate         = false
      required       = true
      value          = "DTS.?(HD|ES|X(?!\\D))|TRUEHD|ATMOS|DD(\\+|P)?.?([5-9])|EAC3.?([5-9])"
    },
  ]
}

resource "sonarr_custom_format" "ten_bit" {
  include_custom_format_when_renaming = true
  name                                = "10 bit"
  specifications = [
    {
      implementation = "ReleaseTitleSpecification"
      name           = "10 bit"
      negate         = false
      required       = true
      value          = "10BIT"
    },
  ]
}

resource "sonarr_custom_format" "hdr" {
  include_custom_format_when_renaming = true
  name                                = "HDR"
  specifications = [
    {
      implementation = "ReleaseTitleSpecification"
      name           = "HDR"
      negate         = false
      required       = true
      value          = "\\bHDR(?!Rip)"
    },
  ]
}

resource "sonarr_quality_profile" "hd" {
  cutoff              = 7
  cutoff_format_score = 40
  format_items = [
    {
      format = sonarr_custom_format.hevc.id
      name   = "HEVC"
      score  = 32
    },
    {
      format = sonarr_custom_format.avc.id
      name   = "AVC"
      score  = 16
    },
    {
      format = sonarr_custom_format.surround_sound.id
      name   = "SS"
      score  = 8
    },
    {
      format = sonarr_custom_format.ten_bit.id
      name   = "10 bit"
      score  = 4
    },
    {
      format = sonarr_custom_format.hdr.id
      name   = "HDR"
      score  = 2
    },
  ]
  min_format_score         = 0
  min_upgrade_format_score = 1
  name                     = "1080p/720p"
  quality_groups = [
    {
      qualities = [
        {
          id         = 7
          name       = "Bluray-1080p"
          resolution = 1080
          source     = "bluray"
        },
      ]
    },
    {
      id   = 1002
      name = "WEB 1080p"
      qualities = [
        {
          id         = 15
          name       = "WEBRip-1080p"
          resolution = 1080
          source     = "webRip"
        },
        {
          id         = 3
          name       = "WEBDL-1080p"
          resolution = 1080
          source     = "web"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 9
          name       = "HDTV-1080p"
          resolution = 1080
          source     = "television"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 6
          name       = "Bluray-720p"
          resolution = 720
          source     = "bluray"
        },
      ]
    },
    {
      id   = 1001
      name = "WEB 720p"
      qualities = [
        {
          id         = 14
          name       = "WEBRip-720p"
          resolution = 720
          source     = "webRip"
        },
        {
          id         = 5
          name       = "WEBDL-720p"
          resolution = 720
          source     = "web"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 4
          name       = "HDTV-720p"
          resolution = 720
          source     = "television"
        },
      ]
    },
  ]
  upgrade_allowed = true
}

resource "sonarr_quality_profile" "uhd" {
  cutoff              = 19
  cutoff_format_score = 40
  format_items = [
    {
      format = sonarr_custom_format.hevc.id
      name   = "HEVC"
      score  = 32
    },
    {
      format = sonarr_custom_format.avc.id
      name   = "AVC"
      score  = 16
    },
    {
      format = sonarr_custom_format.surround_sound.id
      name   = "SS"
      score  = 8
    },
    {
      format = sonarr_custom_format.ten_bit.id
      name   = "10 bit"
      score  = 4
    },
    {
      format = sonarr_custom_format.hdr.id
      name   = "HDR"
      score  = 2
    },
  ]
  min_format_score         = 0
  min_upgrade_format_score = 1
  name                     = "2160p"
  quality_groups = [
    {
      qualities = [
        {
          id         = 19
          name       = "Bluray-2160p"
          resolution = 2160
          source     = "bluray"
        },
      ]
    },
    {
      id   = 1003
      name = "WEB 2160p"
      qualities = [
        {
          id         = 17
          name       = "WEBRip-2160p"
          resolution = 2160
          source     = "webRip"
        },
        {
          id         = 18
          name       = "WEBDL-2160p"
          resolution = 2160
          source     = "web"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 16
          name       = "HDTV-2160p"
          resolution = 2160
          source     = "television"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 7
          name       = "Bluray-1080p"
          resolution = 1080
          source     = "bluray"
        },
      ]
    },
    {
      id   = 1002
      name = "WEB 1080p"
      qualities = [
        {
          id         = 15
          name       = "WEBRip-1080p"
          resolution = 1080
          source     = "webRip"
        },
        {
          id         = 3
          name       = "WEBDL-1080p"
          resolution = 1080
          source     = "web"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 9
          name       = "HDTV-1080p"
          resolution = 1080
          source     = "television"
        },
      ]
    },
  ]
  upgrade_allowed = true
}
