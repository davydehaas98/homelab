variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "ipv4_address" {
  description = "Server IPv4 address"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  default     = "01af14b5b71f5639198aaca16f0b38f6"
}
