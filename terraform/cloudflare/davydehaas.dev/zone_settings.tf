# Off, as nothing is proxied: with it on, Cloudflare adds its own CAs to the CAA records in root.tf. The other zone
# settings only act on proxied traffic and keep their value in the dashboard.
resource "cloudflare_universal_ssl_setting" "this" {
  zone_id = var.zone_id
  enabled = false
}

import {
  to = cloudflare_universal_ssl_setting.this
  id = var.zone_id
}
