locals {
  okta_url = format("https://%s.%s",
    data.aws_ssm_parameter.okta_org_name.value,
    data.aws_ssm_parameter.okta_base_url.value
  )
}
