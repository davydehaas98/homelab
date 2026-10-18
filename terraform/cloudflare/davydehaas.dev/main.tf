terraform {
  required_version = "~> 1.15"

  backend "s3" {
    bucket       = "davydehaas-terraform-state"
    key          = "cloudflare/davydehaas.dev/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.27.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Only for destroying the removed SRV records, which the state still binds to this alias. Remove it after the
# next apply.
provider "cloudflare" {
  alias     = "dev"
  api_token = var.cloudflare_api_token
}
