# Everything is proxied, so these act on all traffic; the rest keeps its value in the dashboard. HSTS comes from the
# Envoy Gateway, not from here.
resource "cloudflare_universal_ssl_setting" "this" {
  provider = cloudflare.nl

  zone_id = var.zone_id
  enabled = true
}

import {
  to = cloudflare_universal_ssl_setting.this
  id = var.zone_id
}

locals {
  zone_settings = {
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    http3                    = "on"
    min_tls_version          = "1.3"
    # The origin has a Let's Encrypt certificate for every name, so Cloudflare verifies it
    ssl     = "strict"
    tls_1_3 = "on"
  }
}

resource "cloudflare_zone_setting" "this" {
  for_each = local.zone_settings
  provider = cloudflare.nl

  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}

import {
  for_each = local.zone_settings

  to = cloudflare_zone_setting.this[each.key]
  id = "${var.zone_id}/${each.key}"
}
