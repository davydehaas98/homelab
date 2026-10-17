resource "cloudflare_dns_record" "www" {
  provider = cloudflare.dev

  name    = "www"
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id

  content = "davydehaas.dev"
  proxied = true
}

resource "cloudflare_dns_record" "wireguard" {
  provider = cloudflare.dev

  name    = "wireguard"
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id

  content = "davydehaas.dev"
  proxied = false
}

resource "cloudflare_dns_record" "factorio" {
  provider = cloudflare.dev

  name     = "_factorio._tcp.factorio"
  ttl      = 1
  type     = "SRV"
  zone_id  = var.zone_id
  priority = 0

  comment = "Factorio server"
  data = {
    port     = 34197
    priority = 0
    weight   = 0
    target   = "factorio.davydehaas.dev"
  }
}

resource "cloudflare_dns_record" "minecraft" {
  provider = cloudflare.dev

  name     = "_minecraft._tcp.minecraft"
  ttl      = 1
  type     = "SRV"
  zone_id  = var.zone_id
  priority = 0

  comment = "Minecraft Vanilla server"
  data = {
    port     = 25565
    priority = 0
    weight   = 0
    target   = "minecraft.davydehaas.dev"
  }
}

# Prevent email spoofing

# Sender Policy Framework (SPF)
# https://en.wikipedia.org/wiki/Sender_Policy_Framework
resource "cloudflare_dns_record" "spf1" {
  provider = cloudflare.dev

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
  provider = cloudflare.dev

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
  provider = cloudflare.dev

  name    = "*._domainkey"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "DKIM record to prevent email spoofing"
  content = "\"v=DKIM1; p=\""
}

locals {
  # Apps behind the Kubernetes gateway, one line per HTTPRoute hostname. They share the gateway's
  # wildcard certificate.
  kubernetes_apps = [
    "argocd",
    "auth",
    "grafana",
    "hubble",
    "prometheus",
    "prowlarr",
    "radarr",
    "sonarr",
  ]

  # Game servers on the home server, the targets of the SRV records above.
  game_servers = [
    "factorio",
    "minecraft",
  ]
}

# Traefik on the home server passes TLS through to the Kubernetes gateway.
# This must not be proxied: Cloudflare would terminate TLS.
resource "cloudflare_dns_record" "kubernetes_app" {
  provider = cloudflare.dev
  for_each = toset(local.kubernetes_apps)

  name    = each.value
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id

  comment = "Home server, TLS passthrough to Kubernetes"
  content = var.ipv4_address
  proxied = false
}

resource "cloudflare_dns_record" "game_server" {
  provider = cloudflare.dev
  for_each = toset(local.game_servers)

  name    = each.value
  ttl     = 1
  type    = "A"
  zone_id = var.zone_id

  comment = "Game server on the home server"
  content = var.ipv4_address
  proxied = false
}
