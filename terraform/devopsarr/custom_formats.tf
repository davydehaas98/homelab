# Scores per quality profile in quality_profiles.tf; -10000 blocks a release
locals {
  # Not HDRip, a re-encode
  hdr = "\\bHDR(?!Rip)|\\bHLG\\b"

  custom_formats = {
    surround_sound = {
      name   = "SS"
      apps   = ["sonarr", "radarr"]
      scores = { hd = 20, uhd = 20 }
      specifications = [
        {
          name  = "Surround Sound"
          value = "\\b(DTS(.?(HD|ES|X))?|TRUEHD|ATMOS)\\b|(?<!\\d)[5-7][ .]1(?!\\d)|\\b(AAC|AC3|DDP?|EAC3)[ .]?[5-7]1\\b|\\b[68]CH\\b"
        },
      ]
    }
    hevc = {
      name   = "HEVC"
      apps   = ["sonarr", "radarr"]
      scores = { hd = 15, uhd = 15 }
      specifications = [
        { name = "HEVC", value = "((X|H)\\.?265)|(HEVC)" },
      ]
    }
    avc = {
      name   = "AVC"
      apps   = ["sonarr", "radarr"]
      scores = { hd = 0, uhd = 0 }
      specifications = [
        { name = "AVC", value = "((X|H)\\.?264)|(AVC)" },
      ]
    }
    ten_bit = {
      name   = "10 bit"
      apps   = ["sonarr", "radarr"]
      scores = { hd = 5, uhd = 5 }
      specifications = [
        { name = "10 bit", value = "\\b10.?bit\\b" },
      ]
    }
    hdr = {
      name   = "HDR"
      apps   = ["sonarr", "radarr"]
      scores = { hd = 5, uhd = 25 }
      specifications = [
        { name = "HDR", value = local.hdr },
      ]
    }
    # Scored here, as the media management setting would rank them above every format
    repack_proper = {
      name   = "Repack/Proper"
      apps   = ["sonarr", "radarr"]
      scores = { hd = 10, uhd = 10 }
      specifications = [
        { name = "Repack/Proper", value = "\\b(REPACK\\d?|PROPER|RERIP)\\b" },
      ]
    }
    three_d = {
      name   = "3D"
      apps   = ["sonarr", "radarr"]
      scores = { hd = -10000, uhd = -10000 }
      specifications = [
        { name = "3D", value = "\\b3D\\b" },
      ]
    }
    br_disk = {
      name   = "BR-DISK"
      apps   = ["sonarr", "radarr"]
      scores = { hd = -10000, uhd = -10000 }
      specifications = [
        { name = "BR-DISK", value = "\\b(COMPLETE.?(UHD.?)?BLU-?RAY|BDMV|BD(25|50|66|100))\\b" },
      ]
    }
    low_quality = {
      name   = "LQ"
      apps   = ["sonarr", "radarr"]
      scores = { hd = -10000, uhd = -10000 }
      specifications = [
        { name = "LQ", value = "\\b(YTS|YIFY|aXXo|PSA|MeGusta)\\b" },
      ]
    }
    upscaled = {
      name   = "Upscaled"
      apps   = ["sonarr", "radarr"]
      scores = { hd = -10000, uhd = -10000 }
      specifications = [
        { name = "Upscaled", value = "\\b(Upscaled?|AI.?Upscaled?)\\b" },
      ]
    }
    # 2160p without HDR, which the UHD profile is for
    sdr = {
      name   = "SDR"
      apps   = ["sonarr", "radarr"]
      scores = { hd = 0, uhd = -10000 }
      specifications = [
        { name = "SDR", value = "\\bSDR\\b" },
      ]
    }
    # Many Plex clients cannot direct play AV1
    av1 = {
      name   = "AV1"
      apps   = ["sonarr", "radarr"]
      scores = { hd = -10000, uhd = -10000 }
      specifications = [
        { name = "AV1", value = "\\bAV1\\b" },
      ]
    }
    # Wrong colours on players without Dolby Vision
    dv_without_hdr = {
      name   = "DV (w/o HDR)"
      apps   = ["sonarr", "radarr"]
      scores = { hd = -10000, uhd = -10000 }
      specifications = [
        { name = "DV", value = "\\b(DV|DoVi|Dolby.?Vision)\\b" },
        { name = "Not HDR", value = local.hdr, negate = true },
      ]
    }
    # -2 is Original, 1 is English
    not_original_language = {
      name   = "Not Original or English"
      apps   = ["sonarr", "radarr"]
      scores = { hd = -10000, uhd = -10000 }
      specifications = [
        { name = "Not Original", value = "-2", implementation = "LanguageSpecification", negate = true },
        { name = "Not English", value = "1", implementation = "LanguageSpecification", negate = true },
      ]
    }
    # Every English release has it
    multi_audio = {
      name   = "Multi Audio"
      apps   = ["sonarr", "radarr"]
      scores = { hd = 25, uhd = 25 }
      specifications = [
        { name = "Original", value = "-2", implementation = "LanguageSpecification" },
        { name = "English", value = "1", implementation = "LanguageSpecification" },
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
