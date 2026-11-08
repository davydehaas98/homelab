# Other names: redirected or a 404 by the gateway
resource "cloudflare_dns_record" "wildcard" {
  provider = cloudflare.nl

  name    = "*"
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id

  content = "davydehaas.nl"
  proxied = true
}

resource "cloudflare_dns_record" "plex" {
  provider = cloudflare.nl

  name    = "plex"
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id

  content = "davydehaas.nl"
  proxied = true
}

resource "cloudflare_dns_record" "vpn" {
  provider = cloudflare.nl

  name    = "vpn"
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id

  content = "davydehaas.nl"
  proxied = false
}

resource "cloudflare_dns_record" "wireguard" {
  provider = cloudflare.nl

  name    = "wireguard"
  ttl     = 1
  type    = "CNAME"
  zone_id = var.zone_id

  content = "davydehaas.nl"
  proxied = false
}

resource "cloudflare_dns_record" "spf1" {
  provider = cloudflare.nl

  name    = "davydehaas.nl"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "SPF record to allow Cloudflare Email Routing"
  content = "\"v=spf1 include:_spf.mx.cloudflare.email ~all\""
}

resource "cloudflare_dns_record" "dmarc" {
  provider = cloudflare.nl

  name    = "_dmarc"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "DMARC record to prevent email spoofing"
  content = "\"v=DMARC1; p=reject; adkim=r; aspf=r;\""
}

resource "cloudflare_dns_record" "dkim1" {
  provider = cloudflare.nl

  name    = "*._domainkey"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  comment = "DKIM record to prevent email spoofing"
  content = "\"v=DKIM1; p=\""
}

resource "cloudflare_dns_record" "dkim_cf2024" {
  provider = cloudflare.nl

  name    = "cf2024-1._domainkey"
  ttl     = 1
  type    = "TXT"
  zone_id = var.zone_id

  content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
}
