resource "lidarr_root_folder" "lidarr" {
  metadata_profile_id     = 1 # Standard
  monitor_option          = "all"
  name                    = "music"
  new_item_monitor_option = "all"
  path                    = "/data/music/library"
  quality_profile_id      = lidarr_quality_profile.lossless.id
  tags                    = []
}

# Groups from highest to lowest. Lossy and Unknown (no format in the release name) are fallbacks that upgrade until
# lossless turns up; the quality of an Unknown release is read from its files on import.
resource "lidarr_quality_profile" "lossless" {
  cutoff              = 1005
  cutoff_format_score = 0
  format_items        = []
  min_format_score    = 0
  name                = "Lossless"
  quality_groups = [
    {
      id   = 1005
      name = "Lossless"
      qualities = [
        {
          id   = 7
          name = "ALAC"
        },
        {
          id   = 6
          name = "FLAC"
        },
        {
          id   = 35
          name = "APE"
        },
        {
          id   = 36
          name = "WavPack"
        },
        {
          id   = 21
          name = "FLAC 24bit"
        },
        {
          id   = 37
          name = "ALAC 24bit"
        },
      ]
    },
    {
      id   = 1004
      name = "High Quality Lossy"
      qualities = [
        {
          id   = 2
          name = "MP3-VBR-V0"
        },
        {
          id   = 12
          name = "AAC-VBR"
        },
        {
          id   = 4
          name = "MP3-320"
        },
        {
          id   = 15
          name = "OGG Vorbis Q9"
        },
        {
          id   = 11
          name = "AAC-320"
        },
        {
          id   = 14
          name = "OGG Vorbis Q10"
        },
      ]
    },
    {
      qualities = [
        {
          id   = 0
          name = "Unknown"
        },
      ]
    },
  ]
  upgrade_allowed = true
}

resource "lidarr_naming" "lidarr" {
  artist_folder_format       = "{Artist Name}"
  multi_disc_track_format    = "{Album Title} ({Release Year})/{Medium Format} {medium:00}/{Artist Name} - {Album Title} - {track:00} - {Track Title}"
  rename_tracks              = true
  replace_illegal_characters = true
  standard_track_format      = "{Album Title} ({Release Year})/{Artist Name} - {Album Title} - {track:00} - {Track Title}"
}

resource "lidarr_media_management" "lidarr" {
  allow_fingerprinting     = "newFiles"
  chmod_folder             = "755"
  chown_group              = ""
  create_empty_folders     = false
  delete_empty_folders     = true
  download_propers_repacks = "preferAndUpgrade"
  extra_file_extensions    = "lrc"
  file_date                = "none"
  hardlinks_copy           = true
  # Keeps the lyrics that come with a release
  import_extra_files = true
  minimum_free_space = 100
  recycle_bin_days   = 7
  # Next to the library, so Plex and Jellyfin do not see it; emptied after recycle_bin_days
  recycle_bin_path          = "/data/music/recycle"
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
