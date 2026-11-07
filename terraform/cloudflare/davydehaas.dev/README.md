# cloudflare/davydehaas.dev

All DNS records of `davydehaas.dev`. App hostnames (`kubernetes_apps`) and their redirect names
(`kubernetes_aliases`, the `route.aliases` of an app) point at the public address, which the UniFi gateway forwards to the
Kubernetes gateway; a wildcard record sends other names to its 404 page, but every app hostname still goes in one of
those lists. Nothing is proxied, so Universal SSL is off in the dashboard (SSL/TLS → Edge Certificates): otherwise
Cloudflare adds its own CAs to the CAA records in `root.tf`.

**State** is in S3 bucket `davydehaas-terraform-state` (`eu-central-1`), key `cloudflare/davydehaas.dev/terraform.tfstate`,
kept from when this lived in `home-server`.

**CI** (`.github/workflows/terraform-cloudflare.yaml`) plans on pushes to `main` that touch this stack and on manual
runs. A plan with changes is applied right after, with no approval, so a merge to `main` changes DNS. It needs the
repository secrets `AWS_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN` (DNS edit on the zone) and `SERVER_IPV4_ADDRESS`. The IAM
role `github-state-cloudflare-dev` comes from the `bootstrap` stack of `home-server`, and its trust policy must allow the
subject `repo:davydehaas98/homelab:ref:refs/heads/main`, for both jobs.

**Locally**, set `TF_VAR_cloudflare_api_token` and `TF_VAR_ipv4_address`, then
`terraform init && terraform plan`. Commit `.terraform.lock.hcl`, and after a provider bump refresh it with
`terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_arm64`.
