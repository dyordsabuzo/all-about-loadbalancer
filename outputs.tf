output "http_to_lb" {
  value = "https://${aws_lb.lb.dns_name}"
}
