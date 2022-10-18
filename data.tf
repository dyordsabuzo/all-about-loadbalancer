data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

data "aws_acm_certificate" "issued" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "zone" {
  name = var.domain_name
}

data "aws_instance" "instance" {
  filter {
    name   = "tag:Name"
    values = ["ec2-reverse-proxy"]
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda-scripts/lambda.py"
  output_path = "lambda.zip"
}

data "aws_ssm_parameter" "okta_base_url" {
  name = "/tool/okta/BASE_URL"
}

data "aws_ssm_parameter" "okta_org_name" {
  name = "/tool/okta/ORG_NAME"
}

data "aws_ssm_parameter" "okta_token" {
  name            = "/tool/okta/TOKEN"
  with_decryption = true
}

data "okta_group" "group" {
  name = "Developer"
}
