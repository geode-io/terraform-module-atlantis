terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "atlantis" {
  source = "../.."

  name                   = "atlantis-sample"
  route53_zone_name      = "my.zone.com"
  vpc_id                 = "vpc-000000000"
  lb_subnet_ids          = ["subnet-1111111111", "subnet-2222222222"]
  task_subnet_ids        = ["subnet-1111111111", "subnet-2222222222"]

  repo_allowlist = [
    "github.com/my-org/*",
    "github.com/my-org2/*",
  ]
  
  github_app_slug        = "geode-atlantis"
  github_app_id          = 284854
  github_app_private_key = file("gh.key")
  github_webhook_secret  = "abc123"

  oidc_issuer                 = "https://geode.okta.com"
  oidc_client_id              = "aaabbbccc"
  oidc_client_secret          = "aaabbbccc"
  oidc_authorization_endpoint = "https://geode.okta.com/oauth2/v1/authorize"
  oidc_token_endpoint         = "https://geode.okta.com/oauth2/v1/token"
  oidc_user_info_endpoint     = "https://geode.okta.com/oauth2/v1/userinfo"
}

