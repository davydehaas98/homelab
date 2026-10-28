# Terraform

## cloudflare/davydehaas.dev

All DNS records of `davydehaas.dev`. App hostnames (`kubernetes_apps`) and their redirect names
(`kubernetes_aliases`, the `route.aliases` of an app) point at the public address, which the UniFi gateway forwards to the
Kubernetes gateway. There is no wildcard record, so every new hostname goes in one of those lists.

**State** is in S3 bucket `davydehaas-terraform-state` (`eu-central-1`), key `cloudflare/davydehaas.dev/terraform.tfstate`,
kept from when this lived in `home-server`.

**CI** (`.github/workflows/terraform-cloudflare.yaml`) plans on pushes to `main` that touch this stack and on manual
runs. A plan with changes is applied right after, with no approval, so a merge to `main` changes DNS. It needs the
repository secrets `AWS_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN` (DNS edit on the zone), `SERVER_IPV4_ADDRESS` and
`SERVER_IPV6_ADDRESS`. The IAM role `github-state-cloudflare-dev` comes from the `bootstrap` stack of `home-server`,
and its trust policy must allow the subject `repo:davydehaas98/homelab:ref:refs/heads/main`, for both jobs.

**Locally**, set `TF_VAR_cloudflare_api_token`, `TF_VAR_ipv4_address` and `TF_VAR_ipv6_address`, then
`terraform init && terraform plan`. Commit `.terraform.lock.hcl`, and after a provider bump refresh it with
`terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_arm64`.

## arr

Settings of Sonarr, Radarr, Lidarr and Prowlarr: root folders, naming, media management, download clients, Discord
notifications, delay profiles, custom formats, quality and metadata profiles, and in Prowlarr the indexers, sync
profiles and the apps it syncs the indexers to. The indexers in the other apps are left to that sync.

The Lidarr provider is behind on Lidarr's API and crashes on its delay profile and download clients, so those stay in
the UI. So do Prowlarr's disabled altHUB indexer and the indexers whose definitions Prowlarr no longer has.

**State** is local, `terraform.tfstate` here, and gitignored. It holds the secrets in plain text. If it is lost, the
import blocks in `imports.tf` adopt the settings again on the next apply.

**Applied locally only**, no CI. `. scripts/arr-env.sh` exports the variables in `variables.tf`, read from the
cluster, then `terraform init && terraform plan`. The providers use the public hostnames, whose `/api` skips the Authentik login.
The APIs do not return secrets, so the first apply after an import writes them again. A change made in the UI shows
as drift in the next plan.
