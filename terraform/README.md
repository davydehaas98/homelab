# Terraform

## cloudflare/davydehaas.dev

DNS records of the `davydehaas.dev` zone: the root A/AAAA/CAA records, `www`, `wireguard`, the SRV
records, the mail spoofing protection (SPF, DMARC, DKIM) and the wildcard `*` that points every
subdomain at the home server, which passes TLS through to the Kubernetes gateway.

Records of the services themselves (`grafana`, `argocd`, ...) are not managed here, external-dns
creates and removes them from the HTTPRoutes in `kubernetes/`. It only touches records it owns (its
TXT registry), so the records in this stack are left alone.

### State

The state is in the S3 bucket `davydehaas-terraform-state` under `cloudflare/davydehaas.dev/terraform.tfstate`
(`eu-central-1`, locked with a lockfile). The key is independent of the repository, the code was moved
from `home-server` and kept this key, so there is nothing to import.

### Workflow

`.github/workflows/terraform-cloudflare.yaml` plans on every push to `main` that touches this
directory. It never applies on a push: run the workflow by hand with `apply` ticked.

It needs these repository secrets:

- `AWS_ACCOUNT_ID`: account of the IAM role `github-state-cloudflare-dev`
- `CLOUDFLARE_API_TOKEN`: token with DNS edit rights on the zone
- `SERVER_IPV4_ADDRESS` and `SERVER_IPV6_ADDRESS`: public addresses of the home server

The role is created by the `bootstrap` stack of `home-server`. Its trust policy has to allow
`repo:davydehaas98/homelab:*` as well, otherwise the workflow cannot assume the role.

### Locally

```sh
cd terraform/cloudflare/davydehaas.dev
terraform init
terraform plan   # TF_VAR_cloudflare_api_token, TF_VAR_ipv4_address and TF_VAR_ipv6_address have to be set
```

`*.tfvars` and the state files are ignored. Commit `.terraform.lock.hcl`, and refresh it with
`terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_arm64` after a
provider bump.
