# Quality profiles of Sonarr and Radarr. Both apps use the same quality ids, but name the sources differently.
locals {
  qualities = {
    bluray_720p  = { id = 6, name = "Bluray-720p", resolution = 720, source = "bluray" }
    webrip_720p  = { id = 14, name = "WEBRip-720p", resolution = 720, source = "webrip" }
    webdl_720p   = { id = 5, name = "WEBDL-720p", resolution = 720, source = "webdl" }
    hdtv_720p    = { id = 4, name = "HDTV-720p", resolution = 720, source = "tv" }
    bluray_1080p = { id = 7, name = "Bluray-1080p", resolution = 1080, source = "bluray" }
    webrip_1080p = { id = 15, name = "WEBRip-1080p", resolution = 1080, source = "webrip" }
    webdl_1080p  = { id = 3, name = "WEBDL-1080p", resolution = 1080, source = "webdl" }
    hdtv_1080p   = { id = 9, name = "HDTV-1080p", resolution = 1080, source = "tv" }
    bluray_2160p = { id = 19, name = "Bluray-2160p", resolution = 2160, source = "bluray" }
    webrip_2160p = { id = 17, name = "WEBRip-2160p", resolution = 2160, source = "webrip" }
    webdl_2160p  = { id = 18, name = "WEBDL-2160p", resolution = 2160, source = "webdl" }
    hdtv_2160p   = { id = 16, name = "HDTV-2160p", resolution = 2160, source = "tv" }
  }

  quality_sources = {
    sonarr = { bluray = "bluray", webrip = "webRip", webdl = "web", tv = "television" }
    radarr = { bluray = "bluray", webrip = "webrip", webdl = "webdl", tv = "tv" }
  }

  # Groups from best to worst. Groups with a name share a rank (the WEB groups ids are the apps' own).
  quality_profiles = {
    hd = {
      name   = "1080p/720p"
      cutoff = 7
      groups = [
        { qualities = ["bluray_1080p"] },
        { id = 1002, name = "WEB 1080p", qualities = ["webrip_1080p", "webdl_1080p"] },
        { qualities = ["hdtv_1080p"] },
        { qualities = ["bluray_720p"] },
        { id = 1001, name = "WEB 720p", qualities = ["webrip_720p", "webdl_720p"] },
        { qualities = ["hdtv_720p"] },
      ]
    }
    uhd = {
      name   = "2160p"
      cutoff = 19
      groups = [
        { qualities = ["bluray_2160p"] },
        { id = 1003, name = "WEB 2160p", qualities = ["webrip_2160p", "webdl_2160p"] },
        { qualities = ["hdtv_2160p"] },
        { qualities = ["bluray_1080p"] },
        { id = 1002, name = "WEB 1080p", qualities = ["webrip_1080p", "webdl_1080p"] },
        { qualities = ["hdtv_1080p"] },
      ]
    }
  }
}

resource "sonarr_quality_profile" "this" {
  for_each = local.quality_profiles

  cutoff              = each.value.cutoff
  cutoff_format_score = 35
  format_items = [
    for key, format in sonarr_custom_format.this : {
      format = format.id
      name   = format.name
      score  = local.custom_formats[key]["score_${each.key}"]
    }
    # The apps leave formats scored 0 out of a profile
    if local.custom_formats[key]["score_${each.key}"] != 0
  ]
  min_format_score         = 0
  min_upgrade_format_score = 10
  name                     = each.value.name
  quality_groups = [
    for group in each.value.groups : {
      id   = try(group.id, null)
      name = try(group.name, null)
      qualities = [
        for quality in group.qualities : merge(local.qualities[quality], {
          source = local.quality_sources.sonarr[local.qualities[quality].source]
        })
      ]
    }
  ]
  upgrade_allowed = true
}

resource "radarr_quality_profile" "this" {
  for_each = local.quality_profiles

  cutoff              = each.value.cutoff
  cutoff_format_score = 35
  format_items = [
    for key, format in radarr_custom_format.this : {
      format = format.id
      name   = format.name
      score  = local.custom_formats[key]["score_${each.key}"]
    }
    # The apps leave formats scored 0 out of a profile
    if local.custom_formats[key]["score_${each.key}"] != 0
  ]
  # Radarr filters on language here, Sonarr through the Not Original custom format
  language = {
    id   = -2
    name = "Original"
  }
  min_format_score         = 0
  min_upgrade_format_score = 10
  name                     = each.value.name
  quality_groups = [
    for group in each.value.groups : {
      id   = try(group.id, null)
      name = try(group.name, null)
      qualities = [
        for quality in group.qualities : merge(local.qualities[quality], {
          source = local.quality_sources.radarr[local.qualities[quality].source]
        })
      ]
    }
  ]
  upgrade_allowed = true
}
