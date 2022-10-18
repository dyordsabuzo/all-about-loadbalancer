provider "aws" {
  region = var.region

  default_tags {
    tags = {
      created_by = "terraform"
      workspace  = terraform.workspace
    }
  }
}

provider "okta" {
  org_name  = data.aws_ssm_parameter.okta_org_name.value
  base_url  = data.aws_ssm_parameter.okta_base_url.value
  api_token = data.aws_ssm_parameter.okta_token.value
}
