resource "lidarr_root_folder" "lidarr" {
  metadata_profile_id     = 1 # Standard
  monitor_option          = "all"
  name                    = "music"
  new_item_monitor_option = "all"
  path                    = "/music"
  quality_profile_id      = 3 # Standard
  tags                    = []
}

resource "lidarr_naming" "lidarr" {
  artist_folder_format       = "{Artist Name}"
  multi_disc_track_format    = "{Album Title} ({Release Year})/{Medium Format} {medium:00}/{Artist Name} - {Album Title} - {track:00} - {Track Title}"
  rename_tracks              = false
  replace_illegal_characters = true
  standard_track_format      = "{Album Title} ({Release Year})/{Artist Name} - {Album Title} - {track:00} - {Track Title}"
}

resource "lidarr_media_management" "lidarr" {
  allow_fingerprinting      = "newFiles"
  chmod_folder              = "755"
  chown_group               = ""
  create_empty_folders      = false
  delete_empty_folders      = true
  download_propers_repacks  = "preferAndUpgrade"
  extra_file_extensions     = "srt"
  file_date                 = "none"
  hardlinks_copy            = true
  import_extra_files        = false
  minimum_free_space        = 100
  recycle_bin_days          = 7
  recycle_bin_path          = ""
  rescan_after_refresh      = "always"
  set_permissions           = false
  skip_free_space_check     = false
  unmonitor_previous_tracks = false
  watch_library_for_changes = true
}

resource "lidarr_notification_discord" "discord" {
  grab_fields             = [0, 1, 2, 3, 5, 6, 7, 8, 9]
  import_fields           = [0, 1, 2, 3, 5, 6, 7, 8, 9]
  include_health_warnings = true
  name                    = "Discord"
  on_album_delete         = false
  on_application_update   = false
  on_artist_delete        = false
  on_download_failure     = true
  on_grab                 = true
  on_health_issue         = true
  on_health_restored      = false
  on_import_failure       = true
  on_release_import       = true
  on_rename               = true
  on_track_retag          = true
  on_upgrade              = true
  tags                    = []
  web_hook_url            = var.lidarr_discord_web_hook_url
}
