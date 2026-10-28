resource "lidarr_root_folder" "lidarr" {
  metadata_profile_id     = lidarr_metadata_profile.standard.id
  monitor_option          = "all"
  name                    = "music"
  new_item_monitor_option = "all"
  path                    = "/music"
  quality_profile_id      = lidarr_quality_profile.standard.id
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

resource "lidarr_metadata_config" "lidarr" {
  scrub_audio_tags = false
  write_audio_tags = "no"
}

resource "lidarr_download_client_config" "lidarr" {
  auto_redownload_failed             = true
  enable_completed_download_handling = true
}

resource "lidarr_indexer_config" "lidarr" {
  maximum_size      = 0
  minimum_age       = 0
  retention         = 0
  rss_sync_interval = 15
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

resource "lidarr_metadata_profile" "standard" {
  name                  = "Standard"
  primary_album_types   = [0]
  release_statuses      = [0]
  secondary_album_types = [0]
}

resource "lidarr_quality_profile" "any" {
  cutoff              = 0
  cutoff_format_score = 0
  format_items = [
  ]
  min_format_score = 0
  name             = "Any"
  quality_groups = [
    {
      qualities = [
        {
          id   = 13
          name = "WAV"
        },
      ]
    },
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
      id   = 1003
      name = "Mid Quality Lossy"
      qualities = [
        {
          id   = 17
          name = "OGG Vorbis Q7"
        },
        {
          id   = 8
          name = "MP3-VBR-V2"
        },
        {
          id   = 3
          name = "MP3-256"
        },
        {
          id   = 16
          name = "OGG Vorbis Q8"
        },
        {
          id   = 10
          name = "AAC-256"
        },
      ]
    },
    {
      id   = 1002
      name = "Low Quality Lossy"
      qualities = [
        {
          id   = 1
          name = "MP3-192"
        },
        {
          id   = 18
          name = "OGG Vorbis Q6"
        },
        {
          id   = 9
          name = "AAC-192"
        },
        {
          id   = 20
          name = "WMA"
        },
        {
          id   = 34
          name = "MP3-224"
        },
      ]
    },
    {
      id   = 1001
      name = "Poor Quality Lossy"
      qualities = [
        {
          id   = 23
          name = "MP3-96"
        },
        {
          id   = 33
          name = "MP3-112"
        },
        {
          id   = 22
          name = "MP3-128"
        },
        {
          id   = 19
          name = "OGG Vorbis Q5"
        },
        {
          id   = 5
          name = "MP3-160"
        },
      ]
    },
    {
      id   = 1000
      name = "Trash Quality Lossy"
      qualities = [
        {
          id   = 32
          name = "MP3-8"
        },
        {
          id   = 31
          name = "MP3-16"
        },
        {
          id   = 30
          name = "MP3-24"
        },
        {
          id   = 29
          name = "MP3-32"
        },
        {
          id   = 28
          name = "MP3-40"
        },
        {
          id   = 27
          name = "MP3-48"
        },
        {
          id   = 26
          name = "MP3-56"
        },
        {
          id   = 25
          name = "MP3-64"
        },
        {
          id   = 24
          name = "MP3-80"
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
  upgrade_allowed = false
}

resource "lidarr_quality_profile" "lossless" {
  cutoff              = 1005
  cutoff_format_score = 0
  format_items = [
  ]
  min_format_score = 0
  name             = "Lossless"
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
  ]
  upgrade_allowed = false
}

resource "lidarr_quality_profile" "standard" {
  cutoff              = 1002
  cutoff_format_score = 0
  format_items = [
  ]
  min_format_score = 0
  name             = "Standard"
  quality_groups = [
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
      id   = 1003
      name = "Mid Quality Lossy"
      qualities = [
        {
          id   = 17
          name = "OGG Vorbis Q7"
        },
        {
          id   = 8
          name = "MP3-VBR-V2"
        },
        {
          id   = 3
          name = "MP3-256"
        },
        {
          id   = 16
          name = "OGG Vorbis Q8"
        },
        {
          id   = 10
          name = "AAC-256"
        },
      ]
    },
    {
      id   = 1002
      name = "Low Quality Lossy"
      qualities = [
        {
          id   = 1
          name = "MP3-192"
        },
        {
          id   = 18
          name = "OGG Vorbis Q6"
        },
        {
          id   = 9
          name = "AAC-192"
        },
        {
          id   = 20
          name = "WMA"
        },
        {
          id   = 34
          name = "MP3-224"
        },
      ]
    },
  ]
  upgrade_allowed = false
}
