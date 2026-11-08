# cloudflare/davydehaas.nl

The DNS records of `davydehaas.nl`, proxied by Cloudflare. A wildcard sends every name to the gateway, which serves Plex
and redirects the names in `nlRedirects` (`kubernetes/core/envoy-gateway/values.yaml`) to `davydehaas.dev`, so a new app
needs no record here. `plex` has a record of its own, as do the names that must stay unproxied and the mail records. The
CAA records allow Let's Encrypt for cert-manager; Cloudflare adds its own CAs for the proxied names. `zone_settings.tf`
holds the SSL and HTTPS settings of the proxy and DNSSEC, whose DS record (output `dnssec_ds`) is set at the registrar
by hand. The Email Routing rules stay in the dashboard.

**State** is in S3 bucket `davydehaas-terraform-state` (`eu-central-1`), key `cloudflare/davydehaas.nl/terraform.tfstate`,
kept from when this lived in `home-server`. The provider keeps its alias `nl`, which the state refers to.

**CI** is the workflow of the `davydehaas.dev` stack, see its README, so a merge to `main` changes DNS here too.

**Locally**, set `TF_VAR_cloudflare_api_token` and `TF_VAR_ipv4_address`, then `terraform init && terraform plan`.
