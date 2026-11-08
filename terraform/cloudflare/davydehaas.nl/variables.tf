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
  default     = "5ff3d3cef9bdf0f486f79115aadc9504"
}
