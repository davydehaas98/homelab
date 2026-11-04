resource "cloudflare_dns_record" "wireguard" {
  name    = "wireguard"
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id

  content = "davydehaas.dev"
  proxied = false
}

resource "cloudflare_dns_record" "spf1" {
  name    = "davydehaas.dev"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "SPF record to prevent email spoofing"
  content = "\"v=spf1 -all\""
}

resource "cloudflare_dns_record" "dmarc" {
  name    = "_dmarc"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "DMARC record to prevent email spoofing"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;\""
}

resource "cloudflare_dns_record" "dkim1" {
  name    = "*._domainkey"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "DKIM record to prevent email spoofing"
  content = "\"v=DKIM1; p=\""
}

locals {
  kubernetes_apps = [
    "actual",
    "adguard",
    "airtrail",
    "argocd",
    "auth",
    "bazarr",
    "dispatcharr",
    "gatus",
    "grafana",
    "headlamp",
    "home-assistant",
    "homepage",
    "hubble",
    "immich",
    "it-tools",
    "jellyfin",
    "lazylibrarian",
    "lidarr",
    "memos",
    "nextcloud",
    "ntfy",
    "omni-tools",
    "policy",
    "prometheus",
    "prowlarr",
    "radarr",
    "sabnzbd",
    "seerr",
    "sonarr",
    "tautulli",
    "tracearr",
    "www",
    "zigbee",
  ]

  # Private gateway, only on the home network
  kubernetes_private_apps = [
    "grafana.mcp",
    "lidarr.lan",
    "prowlarr.lan",
    "radarr.lan",
    "sabnzbd.lan",
    "sonarr.lan",
    "tautulli.lan",
    "tracearr.lan",
  ]

  # `route.aliases`
  kubernetes_aliases = [
    "adguardhome",
    "authentik",
    "books",
    "budget",
    "drive",
    "dvr",
    "hass",
    "home",
    "movies",
    "music",
    "request",
    "requests",
    "series",
    "status",
    "subtitles",
    "usenet",
  ]

  game_servers = [
    "factorio",
  ]

  # Off port 25565 a server also gets an SRV record
  minecraft_servers = {
    minecraft  = 25565
    ftb        = 25566
    arachne    = 25567
    skyfactory = 25568
  }
}

# Not proxied: the UniFi gateway forwards to the Kubernetes gateway
resource "cloudflare_dns_record" "kubernetes_app" {
  for_each = toset(concat(local.kubernetes_apps, local.kubernetes_aliases))

  name    = each.value
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id

  comment = "Port forward to the Kubernetes gateway"
  content = var.ipv4_address
  proxied = false
}

# A private address, not forwarded by the UniFi gateway
resource "cloudflare_dns_record" "kubernetes_private_app" {
  for_each = toset(local.kubernetes_private_apps)

  name    = each.value
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id

  comment = "Private Kubernetes gateway"
  content = "192.168.1.61"
  proxied = false
}

# Other names get the gateway's 404 page instead of a DNS error
resource "cloudflare_dns_record" "wildcard" {
  name    = "*"
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id

  comment = "Port forward to the Kubernetes gateway, for its 404 page"
  content = var.ipv4_address
  proxied = false
}

resource "cloudflare_dns_record" "game_server" {
  for_each = toset(concat(local.game_servers, keys(local.minecraft_servers)))

  name    = each.value
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id

  comment = "Game server"
  content = var.ipv4_address
  proxied = false
}

resource "cloudflare_dns_record" "minecraft_srv" {
  for_each = { for name, port in local.minecraft_servers : name => port if port != 25565 }

  name     = "_minecraft._tcp.${each.key}"
  ttl      = 1
  type     = "SRV"
  zone_id  = var.zone_id
  priority = 0

  comment = "Minecraft server"
  data = {
    port     = each.value
    priority = 0
    weight   = 0
    target   = "${each.key}.davydehaas.dev"
  }
}
