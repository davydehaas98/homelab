# cloudflare/davydehaas.nl

The DNS records of `davydehaas.nl`, proxied by Cloudflare. A wildcard sends every name to the gateway, which serves Plex
and redirects the names in `nlRedirects` (`kubernetes/core/envoy-gateway/values.yaml`) to `davydehaas.dev`, so a new app
needs no record here. `plex` has a record of its own, as do the names that must stay unproxied, the game servers' SRV
records and the mail records.

**State** is in S3 bucket `davydehaas-terraform-state` (`eu-central-1`), key `cloudflare/davydehaas.nl/terraform.tfstate`,
kept from when this lived in `home-server`. The provider keeps its alias `nl`, which the state refers to.

**CI** (`.github/workflows/terraform-cloudflare-nl.yaml`) plans on pushes to `main` that touch this stack. It only applies
on a manual run with `apply` set. It uses the secrets of the `davydehaas.dev` stack, and the token must be able to edit
this zone too. The IAM role `github-state-cloudflare-nl` comes from the `bootstrap` stack of `home-server`.

**Locally**, set `TF_VAR_cloudflare_api_token` and `TF_VAR_ipv4_address`, then `terraform init && terraform plan`.
