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
    name = "tag:Name"
    values = ["ec2-reverse-proxy"]
  }
}