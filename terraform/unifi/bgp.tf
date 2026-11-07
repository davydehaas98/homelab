# The gateway's side of the BGP sessions with Cilium (kubernetes/core/cilium/templates/bgp-cluster-config.yaml)
resource "unifi_bgp" "cilium" {
  description      = "BGP"
  enabled          = true
  config           = file("${path.module}/bgp.conf")
  upload_file_name = "bgp.conf"
}
