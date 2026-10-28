resource "radarr_root_folder" "radarr" {
  path = "/movies"
}

resource "radarr_naming" "radarr" {
  colon_replacement_format   = "spaceDashSpace"
  movie_folder_format        = "{Movie Title} {(Release Year)} {[ImdbId]}"
  rename_movies              = true
  replace_illegal_characters = true
  standard_movie_format      = "{Movie Title} {(Release Year)} {Edition Tags} {[Quality Full]}{[MediaInfo 3D]}{[MediaInfo VideoDynamicRangeType]}{[MediaInfo AudioCodec}{ MediaInfo AudioChannels]}{[MediaInfo VideoCodec]}{-Release Group}"
}

resource "radarr_media_management" "radarr" {
  auto_rename_folders                         = false
  auto_unmonitor_previously_downloaded_movies = false
  chmod_folder                                = "755"
  chown_group                                 = ""
  copy_using_hardlinks                        = true
  create_empty_movie_folders                  = false
  delete_empty_folders                        = true
  download_propers_and_repacks                = "preferAndUpgrade"
  enable_media_info                           = true
  extra_file_extensions                       = "srt"
  file_date                                   = "none"
  import_extra_files                          = false
  minimum_free_space_when_importing           = 100
  paths_default_static                        = false
  recycle_bin                                 = ""
  recycle_bin_cleanup_days                    = 7
  rescan_after_refresh                        = "always"
  set_permissions_linux                       = false
  skip_free_space_check_when_importing        = false
}

resource "radarr_download_client_config" "radarr" {
  auto_redownload_failed               = true
  check_for_finished_download_interval = 1
  enable_completed_download_handling   = true
}

resource "radarr_download_client_sabnzbd" "sabnzbd" {
  api_key                    = var.sabnzbd_api_key
  enable                     = true
  host                       = "sabnzbd"
  movie_category             = "movies"
  name                       = "SABnzbd"
  older_movie_priority       = 0
  port                       = 8080
  priority                   = 1
  recent_movie_priority      = 1
  remove_completed_downloads = true
  remove_failed_downloads    = true
  tags                       = []
  use_ssl                    = false
}

resource "radarr_indexer_config" "radarr" {
  allow_hardcoded_subs       = false
  availability_delay         = 0
  maximum_size               = 0
  minimum_age                = 0
  prefer_indexer_flags       = false
  retention                  = 0
  rss_sync_interval          = 15
  whitelisted_hardcoded_subs = ""
}

resource "radarr_delay_profile" "default" {
  bypass_if_highest_quality = true
  enable_torrent            = false
  enable_usenet             = true
  order                     = 2147483647
  preferred_protocol        = "usenet"
  tags                      = []
  torrent_delay             = 0
  usenet_delay              = 0
}

resource "radarr_notification_discord" "discord" {
  grab_fields                      = [0, 1, 2, 3, 5, 6, 7, 8, 9]
  import_fields                    = [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12]
  include_health_warnings          = true
  name                             = "Discord"
  on_application_update            = false
  on_download                      = true
  on_grab                          = true
  on_health_issue                  = true
  on_health_restored               = false
  on_manual_interaction_required   = false
  on_movie_delete                  = true
  on_movie_file_delete             = true
  on_movie_file_delete_for_upgrade = true
  on_rename                        = true
  on_upgrade                       = true
  tags                             = []
  web_hook_url                     = var.radarr_discord_web_hook_url
}

resource "radarr_quality_profile" "hd" {
  cutoff              = 7
  cutoff_format_score = 35
  format_items = [
    for key, format in radarr_custom_format.this : {
      format = format.id
      name   = format.name
      score  = local.custom_formats[key].score_hd
    }
    # The apps leave formats scored 0 out of a profile
    if local.custom_formats[key].score_hd != 0
  ]
  language = {
    id   = -2
    name = "Original"
  }
  min_format_score         = 0
  min_upgrade_format_score = 10
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
          source     = "webrip"
        },
        {
          id         = 3
          name       = "WEBDL-1080p"
          resolution = 1080
          source     = "webdl"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 9
          name       = "HDTV-1080p"
          resolution = 1080
          source     = "tv"
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
          source     = "webrip"
        },
        {
          id         = 5
          name       = "WEBDL-720p"
          resolution = 720
          source     = "webdl"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 4
          name       = "HDTV-720p"
          resolution = 720
          source     = "tv"
        },
      ]
    },
  ]
  upgrade_allowed = true
}

resource "radarr_quality_profile" "uhd" {
  cutoff              = 19
  cutoff_format_score = 35
  format_items = [
    for key, format in radarr_custom_format.this : {
      format = format.id
      name   = format.name
      score  = local.custom_formats[key].score_uhd
    }
    # The apps leave formats scored 0 out of a profile
    if local.custom_formats[key].score_uhd != 0
  ]
  language = {
    id   = -2
    name = "Original"
  }
  min_format_score         = 0
  min_upgrade_format_score = 10
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
          source     = "webrip"
        },
        {
          id         = 18
          name       = "WEBDL-2160p"
          resolution = 2160
          source     = "webdl"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 16
          name       = "HDTV-2160p"
          resolution = 2160
          source     = "tv"
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
          source     = "webrip"
        },
        {
          id         = 3
          name       = "WEBDL-1080p"
          resolution = 1080
          source     = "webdl"
        },
      ]
    },
    {
      qualities = [
        {
          id         = 9
          name       = "HDTV-1080p"
          resolution = 1080
          source     = "tv"
        },
      ]
    },
  ]
  upgrade_allowed = true
}
