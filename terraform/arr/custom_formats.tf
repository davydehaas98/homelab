# Custom formats of Sonarr and Radarr, with their scores in the HD (1080p/720p) and UHD (2160p) quality profiles.
# A score of -10000 blocks a release.
locals {
  custom_formats = {
    surround_sound = {
      name      = "SS"
      apps      = ["sonarr", "radarr"]
      score_hd  = 20
      score_uhd = 20
      specifications = [
        { name = "Surround Sound", value = "DTS.?(HD|ES|X(?!\\D))|TRUEHD|ATMOS|DD(\\+|P)?.?([5-9])|EAC3.?([5-9])" },
      ]
    }
    hevc = {
      name      = "HEVC"
      apps      = ["sonarr", "radarr"]
      score_hd  = 15
      score_uhd = 15
      specifications = [
        { name = "HEVC", value = "((X|H)\\.?265)|(HEVC)" },
      ]
    }
    avc = {
      name      = "AVC"
      apps      = ["sonarr", "radarr"]
      score_hd  = 0
      score_uhd = 0
      specifications = [
        { name = "AVC", value = "((X|H)\\.?264)|(AVC)" },
      ]
    }
    ten_bit = {
      name      = "10 bit"
      apps      = ["sonarr", "radarr"]
      score_hd  = 5
      score_uhd = 5
      specifications = [
        { name = "10 bit", value = "10BIT" },
      ]
    }
    hdr = {
      name      = "HDR"
      apps      = ["sonarr", "radarr"]
      score_hd  = 5
      score_uhd = 25
      specifications = [
        { name = "HDR", value = "\\bHDR(?!Rip)" },
      ]
    }
    # Side-by-side and other 3D releases
    three_d = {
      name      = "3D"
      apps      = ["sonarr", "radarr"]
      score_hd  = -10000
      score_uhd = -10000
      specifications = [
        { name = "3D", value = "\\b3D\\b" },
      ]
    }
    # Full Blu-ray discs instead of video files
    br_disk = {
      name      = "BR-DISK"
      apps      = ["sonarr", "radarr"]
      score_hd  = -10000
      score_uhd = -10000
      specifications = [
        { name = "BR-DISK", value = "\\b(COMPLETE.?(UHD.?)?BLU-?RAY|BDMV|BD(25|50|66|100))\\b" },
      ]
    }
    # Low-bitrate release groups
    low_quality = {
      name      = "LQ"
      apps      = ["sonarr", "radarr"]
      score_hd  = -10000
      score_uhd = -10000
      specifications = [
        { name = "LQ", value = "\\b(YTS|YIFY|aXXo)\\b" },
      ]
    }
    # AV1, which many Plex clients cannot direct play
    av1 = {
      name      = "AV1"
      apps      = ["sonarr", "radarr"]
      score_hd  = -10000
      score_uhd = -10000
      specifications = [
        { name = "AV1", value = "\\bAV1\\b" },
      ]
    }
    # Dolby Vision without an HDR10 fallback, which shows wrong colours on players without DV
    dv_without_hdr = {
      name      = "DV (w/o HDR)"
      apps      = ["sonarr", "radarr"]
      score_hd  = -10000
      score_uhd = -10000
      specifications = [
        { name = "DV", value = "\\b(DV|DoVi|Dolby.?Vision)\\b" },
        { name = "Not HDR", value = "\\bHDR(?!Rip)", negate = true },
      ]
    }
    # Dubs and other releases without the original language (-2 is Original). Radarr filters on language in its
    # quality profiles instead.
    not_original_language = {
      name      = "Not Original"
      apps      = ["sonarr"]
      score_hd  = -10000
      score_uhd = -10000
      specifications = [
        { name = "Not Original", value = "-2", implementation = "LanguageSpecification", negate = true },
      ]
    }
  }
}

resource "sonarr_custom_format" "this" {
  for_each = { for key, format in local.custom_formats : key => format if contains(format.apps, "sonarr") }

  include_custom_format_when_renaming = false
  name                                = each.value.name
  specifications = [
    for specification in each.value.specifications : {
      implementation = try(specification.implementation, "ReleaseTitleSpecification")
      name           = specification.name
      negate         = try(specification.negate, false)
      required       = true
      value          = specification.value
    }
  ]
}

resource "radarr_custom_format" "this" {
  for_each = { for key, format in local.custom_formats : key => format if contains(format.apps, "radarr") }

  include_custom_format_when_renaming = false
  name                                = each.value.name
  specifications = [
    for specification in each.value.specifications : {
      implementation = try(specification.implementation, "ReleaseTitleSpecification")
      name           = specification.name
      negate         = try(specification.negate, false)
      required       = true
      value          = specification.value
    }
  ]
}

# The custom formats were separate resources before; these move them into the maps above instead of recreating them
moved {
  from = sonarr_custom_format.surround_sound
  to   = sonarr_custom_format.this["surround_sound"]
}

moved {
  from = sonarr_custom_format.hevc
  to   = sonarr_custom_format.this["hevc"]
}

moved {
  from = sonarr_custom_format.avc
  to   = sonarr_custom_format.this["avc"]
}

moved {
  from = sonarr_custom_format.ten_bit
  to   = sonarr_custom_format.this["ten_bit"]
}

moved {
  from = sonarr_custom_format.hdr
  to   = sonarr_custom_format.this["hdr"]
}

moved {
  from = sonarr_custom_format.three_d
  to   = sonarr_custom_format.this["three_d"]
}

moved {
  from = sonarr_custom_format.br_disk
  to   = sonarr_custom_format.this["br_disk"]
}

moved {
  from = sonarr_custom_format.low_quality
  to   = sonarr_custom_format.this["low_quality"]
}

moved {
  from = sonarr_custom_format.av1
  to   = sonarr_custom_format.this["av1"]
}

moved {
  from = sonarr_custom_format.dv_without_hdr
  to   = sonarr_custom_format.this["dv_without_hdr"]
}

moved {
  from = sonarr_custom_format.not_original_language
  to   = sonarr_custom_format.this["not_original_language"]
}

moved {
  from = radarr_custom_format.surround_sound
  to   = radarr_custom_format.this["surround_sound"]
}

moved {
  from = radarr_custom_format.hevc
  to   = radarr_custom_format.this["hevc"]
}

moved {
  from = radarr_custom_format.avc
  to   = radarr_custom_format.this["avc"]
}

moved {
  from = radarr_custom_format.ten_bit
  to   = radarr_custom_format.this["ten_bit"]
}

moved {
  from = radarr_custom_format.hdr
  to   = radarr_custom_format.this["hdr"]
}

moved {
  from = radarr_custom_format.three_d
  to   = radarr_custom_format.this["three_d"]
}

moved {
  from = radarr_custom_format.br_disk
  to   = radarr_custom_format.this["br_disk"]
}

moved {
  from = radarr_custom_format.low_quality
  to   = radarr_custom_format.this["low_quality"]
}

moved {
  from = radarr_custom_format.av1
  to   = radarr_custom_format.this["av1"]
}

moved {
  from = radarr_custom_format.dv_without_hdr
  to   = radarr_custom_format.this["dv_without_hdr"]
}
