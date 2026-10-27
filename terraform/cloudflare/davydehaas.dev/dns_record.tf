resource "cloudflare_dns_record" "wireguard" {
  name    = "wireguard"
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id

  content = "davydehaas.dev"
  proxied = false
}

# Prevent email spoofing

# Sender Policy Framework (SPF)
# https://en.wikipedia.org/wiki/Sender_Policy_Framework
resource "cloudflare_dns_record" "spf1" {
  name    = "davydehaas.dev"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "SPF record to prevent email spoofing"
  content = "\"v=spf1 -all\""
}

# Domain-based Message Authentication, Reporting and Conformance (DMARC)
# https://en.wikipedia.org/wiki/DMARC
resource "cloudflare_dns_record" "dmarc" {
  name    = "_dmarc"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "DMARC record to prevent email spoofing"
  content = "\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;\""
}

# DomainKeys Identified Mail (DKIM)
# https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail
resource "cloudflare_dns_record" "dkim1" {
  name    = "*._domainkey"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "DKIM record to prevent email spoofing"
  content = "\"v=DKIM1; p=\""
}

locals {
  # HTTPRoute hostnames.
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
    "lidarr",
    "memos",
    "nextcloud",
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

  # HTTPRoute hostnames on the private gateway, only reachable from the home network.
  kubernetes_private_apps = [
    "grafana.mcp",
  ]

  # Their `route.aliases`, which redirect to the main name.
  kubernetes_aliases = [
    "adguardhome",
    "authentik",
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

  # Game servers, on their default ports.
  game_servers = [
    "factorio",
  ]

  # Minecraft servers and their public ports. Off the default port 25565 a server also gets an SRV record, so
  # players connect without typing the port.
  minecraft_servers = {
    minecraft  = 25565
    ftb        = 25566
    arachne    = 25567
    skyfactory = 25568
  }
}

# Not proxied: the UniFi gateway forwards the traffic to the Kubernetes gateway.
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

# A private address, which only resolves to something on the home network: the UniFi gateway forwards nothing to it
# (kubernetes/core/envoy-gateway/templates/gateway-private.yaml).
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

# Any other name also reaches the Kubernetes gateway, which answers with its 404 page
# (kubernetes/core/envoy-gateway/templates/not-found.yaml) instead of the browser showing a DNS error. The records
# above take precedence.
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
