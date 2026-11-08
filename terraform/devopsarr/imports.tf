# Adopts the settings on the apps, so a lost state is rebuilt without duplicates; the IDs are those in the apps' API

import {
  to = sonarr_root_folder.sonarr
  id = "2"
}

import {
  to = sonarr_naming.sonarr
  id = "1"
}

import {
  to = sonarr_media_management.sonarr
  id = "1"
}

import {
  to = sonarr_download_client_sabnzbd.sabnzbd
  id = "2"
}

import {
  to = sonarr_delay_profile.default
  id = "1"
}

import {
  to = sonarr_notification_discord.discord
  id = "1"
}

import {
  to = sonarr_metadata.plex
  id = "4"
}

import {
  to = radarr_root_folder.radarr
  id = "2"
}

import {
  to = radarr_naming.radarr
  id = "1"
}

import {
  to = radarr_media_management.radarr
  id = "1"
}

import {
  to = radarr_download_client_sabnzbd.sabnzbd
  id = "2"
}

import {
  to = radarr_delay_profile.default
  id = "1"
}

import {
  to = radarr_notification_discord.discord
  id = "1"
}

import {
  to = lidarr_root_folder.lidarr
  id = "2"
}

import {
  to = lidarr_quality_profile.lossless
  id = "2"
}

import {
  to = lidarr_naming.lidarr
  id = "1"
}

import {
  to = lidarr_media_management.lidarr
  id = "1"
}

import {
  to = lidarr_notification_discord.discord
  id = "1"
}

import {
  to = prowlarr_application_sonarr.sonarr
  id = "2"
}

import {
  to = prowlarr_application_radarr.radarr
  id = "1"
}

import {
  to = prowlarr_application_lidarr.lidarr
  id = "3"
}

import {
  to = prowlarr_sync_profile.usenet
  id = "2"
}

import {
  to = prowlarr_indexer.nzbgeek
  id = "6"
}

import {
  for_each = {
    hevc                  = 1
    avc                   = 2
    surround_sound        = 3
    ten_bit               = 4
    hdr                   = 5
    dv_without_hdr        = 6
    low_quality           = 7
    br_disk               = 8
    three_d               = 9
    not_original_language = 10
    av1                   = 11
    upscaled              = 12
    sdr                   = 13
    repack_proper         = 14
    multi_audio           = 15
  }

  to = sonarr_custom_format.this[each.key]
  id = each.value
}

import {
  for_each = {
    hd  = 4
    uhd = 5
  }

  to = sonarr_quality_profile.this[each.key]
  id = each.value
}

import {
  for_each = local.sonarr_quality_definitions

  to = sonarr_quality_definition.this[each.key]
  id = each.value.id
}

import {
  for_each = {
    ten_bit               = 2
    hevc                  = 3
    surround_sound        = 4
    avc                   = 5
    hdr                   = 6
    br_disk               = 7
    dv_without_hdr        = 8
    av1                   = 9
    low_quality           = 10
    three_d               = 11
    upscaled              = 12
    sdr                   = 13
    repack_proper         = 14
    not_original_language = 15
    multi_audio           = 16
  }

  to = radarr_custom_format.this[each.key]
  id = each.value
}

import {
  for_each = {
    hd  = 4
    uhd = 7
  }

  to = radarr_quality_profile.this[each.key]
  id = each.value
}

import {
  for_each = local.radarr_quality_definitions

  to = radarr_quality_definition.this[each.key]
  id = each.value.id
}
