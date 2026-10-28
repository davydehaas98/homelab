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
  quality_groups = {
    hd = [
      { qualities = ["bluray_1080p"] },
      { id = 1002, name = "WEB 1080p", qualities = ["webrip_1080p", "webdl_1080p"] },
      { qualities = ["hdtv_1080p"] },
      { qualities = ["bluray_720p"] },
      { id = 1001, name = "WEB 720p", qualities = ["webrip_720p", "webdl_720p"] },
      { qualities = ["hdtv_720p"] },
    ]
    uhd = [
      { qualities = ["bluray_2160p"] },
      { id = 1003, name = "WEB 2160p", qualities = ["webrip_2160p", "webdl_2160p"] },
      { qualities = ["hdtv_2160p"] },
      { qualities = ["bluray_1080p"] },
      { id = 1002, name = "WEB 1080p", qualities = ["webrip_1080p", "webdl_1080p"] },
      { qualities = ["hdtv_1080p"] },
    ]
  }

  # The cutoff is a quality or group id per app. Series stop at WEB, as few get a Blu-ray that is better, movies at
  # Blu-ray.
  quality_profiles = {
    hd = {
      name   = "1080p/720p"
      cutoff = { sonarr = 1002, radarr = 7 }
      groups = local.quality_groups.hd
    }
    uhd = {
      name   = "2160p"
      cutoff = { sonarr = 1003, radarr = 19 }
      groups = local.quality_groups.uhd
    }
  }

  profile_scores = {
    for profile_key, profile in local.quality_profiles : profile_key => {
      for format_key, format in local.custom_formats : format_key => try(format.scores[profile_key], 0)
    }
  }
}

resource "sonarr_quality_profile" "this" {
  for_each = local.quality_profiles

  cutoff = each.value.cutoff.sonarr
  # Includes the Multi Audio score, so series in another language than English wait for a release that also has
  # English. For English series every release has it.
  cutoff_format_score = 60
  format_items = [
    for key, format in sonarr_custom_format.this : {
      format = format.id
      name   = format.name
      score  = local.profile_scores[each.key][key]
    }
    # The apps leave formats scored 0 out of a profile
    if local.profile_scores[each.key][key] != 0
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

  cutoff = each.value.cutoff.radarr
  # Includes the Multi Audio score, as for Sonarr
  cutoff_format_score = 60
  format_items = [
    for key, format in radarr_custom_format.this : {
      format = format.id
      name   = format.name
      score  = local.profile_scores[each.key][key]
    }
    # The apps leave formats scored 0 out of a profile
    if local.profile_scores[each.key][key] != 0
  ]
  # Languages are filtered through custom formats, as in Sonarr
  language = {
    id   = -1
    name = "Any"
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
