terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "pablosspot"
    workspaces {
      prefix = "all-about-loadbalancer-"
    }
  }

  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 3.37"
    }
  }
}
