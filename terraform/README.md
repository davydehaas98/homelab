# Terraform

One stack per directory, each with its own README.

- [`bootstrap`](bootstrap/README.md): the S3 state bucket and the CI roles of the other stacks, applied by hand.
- [`cloudflare/davydehaas.dev`](cloudflare/davydehaas.dev/README.md) and
  [`cloudflare/davydehaas.nl`](cloudflare/davydehaas.nl/README.md): DNS records of the two domains, each with its own
  state, applied by CI on a merge to `main`.
- [`devopsarr`](devopsarr/README.md): settings of Sonarr, Radarr, Lidarr and Prowlarr, applied by hand.
- [`unifi`](unifi/README.md): the networks, Wi-Fi, switch ports, firewall, port forwards and BGP of the UniFi
  gateway, applied by hand.
