# bootstrap

The S3 bucket `davydehaas-terraform-state` that holds the state of the other stacks, the GitHub Actions OIDC provider,
and one role per stack that CI assumes through it. Each role can only reach its own stack's key prefix in the bucket,
plus the AWS permissions that stack's provider needs; none can change IAM. The roles trust `main` of this repository and
of `home-server`, whose `aws/` and `oci/` stacks use `github-aws` and `github-state-oci`.

**State** is in the bucket it creates, key `bootstrap/terraform.tfstate`, kept from when this lived in `home-server`.

**Applying** is by hand only, never by CI, with the administrator credentials in the AWS profile `bootstrap`; keep them
out of shared terminals. In the dev container: `AWS_PROFILE=bootstrap terraform init && terraform plan`. Building the
bucket from nothing needs the backend block left out on the first apply, and `terraform init -migrate-state` after.
