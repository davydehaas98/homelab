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
  download_propers_and_repacks                = "doNotPrefer"
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

# Minimum sizes in MB per minute against fake and mislabelled releases. The smallest real encodes in the library are
# about 7.5 at 720p, 8.6 at 1080p and 43 at 2160p. A maximum of 1000 is no limit in practice; the provider cannot
# leave it empty.
locals {
  radarr_quality_definitions = {
    "HDTV-720p"    = { id = 15, min_size = 5, preferred_size = 95, max_size = 100 }
    "WEBDL-720p"   = { id = 16, min_size = 5, preferred_size = 95, max_size = 100 }
    "WEBRip-720p"  = { id = 17, min_size = 5, preferred_size = 95, max_size = 100 }
    "Bluray-720p"  = { id = 18, min_size = 5, preferred_size = 95, max_size = 100 }
    "HDTV-1080p"   = { id = 19, min_size = 10, preferred_size = 95, max_size = 100 }
    "WEBDL-1080p"  = { id = 20, min_size = 10, preferred_size = 95, max_size = 100 }
    "WEBRip-1080p" = { id = 21, min_size = 10, preferred_size = 95, max_size = 100 }
    "Bluray-1080p" = { id = 22, min_size = 10, preferred_size = 95, max_size = 1000 }
    "HDTV-2160p"   = { id = 24, min_size = 30, preferred_size = 250, max_size = 1000 }
    "WEBDL-2160p"  = { id = 25, min_size = 30, preferred_size = 250, max_size = 1000 }
    "WEBRip-2160p" = { id = 26, min_size = 30, preferred_size = 250, max_size = 1000 }
    "Bluray-2160p" = { id = 27, min_size = 30, preferred_size = 250, max_size = 1000 }
  }
}

resource "radarr_quality_definition" "this" {
  for_each = local.radarr_quality_definitions

  id             = each.value.id
  title          = each.key
  min_size       = each.value.min_size
  preferred_size = each.value.preferred_size
  max_size       = each.value.max_size
}
