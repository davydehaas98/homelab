# Custom formats of Sonarr and Radarr, with their scores in the HD (1080p/720p) and UHD (2160p) quality profiles.
# A score of -10000 blocks a release.
locals {
  # HDR10, HDR10+ and HLG, but not HDRip (an SD or HD re-encode)
  hdr = "\\bHDR(?!Rip)|\\bHLG\\b"

  custom_formats = {
    # Any 5.1 or 7.1 track (also written 51 or 6CH), and the surround-only codecs
    surround_sound = {
      name      = "SS"
      apps      = ["sonarr", "radarr"]
      score_hd  = 20
      score_uhd = 20
      specifications = [
        {
          name  = "Surround Sound"
          value = "\\b(DTS(.?(HD|ES|X))?|TRUEHD|ATMOS)\\b|(?<!\\d)[5-7][ .]1(?!\\d)|\\b(AAC|AC3|DDP?|EAC3)[ .]?[5-7]1\\b|\\b[68]CH\\b"
        },
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
        { name = "10 bit", value = "\\b10.?bit\\b" },
      ]
    }
    hdr = {
      name      = "HDR"
      apps      = ["sonarr", "radarr"]
      score_hd  = 5
      score_uhd = 25
      specifications = [
        { name = "HDR", value = local.hdr },
      ]
    }
    # Releases with a proper or repack fix. Scored here instead of through "Propers and Repacks" in media management,
    # which would rank them above every custom format.
    repack_proper = {
      name      = "Repack/Proper"
      apps      = ["sonarr", "radarr"]
      score_hd  = 10
      score_uhd = 10
      specifications = [
        { name = "Repack/Proper", value = "\\b(REPACK\\d?|PROPER|RERIP)\\b" },
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
        { name = "LQ", value = "\\b(YTS|YIFY|aXXo|PSA|MeGusta)\\b" },
      ]
    }
    # SD or HD blown up to a higher resolution
    upscaled = {
      name      = "Upscaled"
      apps      = ["sonarr", "radarr"]
      score_hd  = -10000
      score_uhd = -10000
      specifications = [
        { name = "Upscaled", value = "\\b(Upscaled?|AI.?Upscaled?)\\b" },
      ]
    }
    # 2160p without HDR, which the UHD profile is for
    sdr = {
      name      = "SDR"
      apps      = ["sonarr", "radarr"]
      score_hd  = 0
      score_uhd = -10000
      specifications = [
        { name = "SDR", value = "\\bSDR\\b" },
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
        { name = "Not HDR", value = local.hdr, negate = true },
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
