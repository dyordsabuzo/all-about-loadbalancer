variable "region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "ap-southeast-2"
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "pablosspot.ml"
}

variable "ec2_security_group_id" {
  type = string
  description = "EC2 security group id"
  default = "sg-071da5f1e56debfa9"
}
