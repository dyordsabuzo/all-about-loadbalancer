resource "aws_lb" "lb" {
  name               = "my-loadbalancer"
  load_balancer_type = "application"
  internal           = false
  subnets            = data.aws_subnets.subnets.ids
  security_groups    = [aws_security_group.sg.id]
}

resource "aws_default_vpc" "default" {

}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = data.aws_acm_certificate.issued.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      status_code  = 401
      message_body = "Unauthorised"
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "sg" {
  name        = "my-loadbalancer-sg"
  description = "My load balancer sec group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_default_vpc.default.id
}

resource "aws_route53_record" "endpoint" {
  zone_id = data.aws_route53_zone.zone.zone_id
  type    = "A"
  name    = "myurl"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "nginx_endpoint" {
  zone_id = data.aws_route53_zone.zone.zone_id
  type    = "A"
  name    = "nginx"

  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener_rule" "rule_1" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 30

  action {
    type = "redirect"

    redirect {
      status_code = "HTTP_301"
      host        = "google.com"
      port        = 443
      protocol    = "HTTPS"
    }
  }

  condition {
    host_header {
      values = ["myurl.pablosspot.ml"]
    }
  }
}

resource "aws_lb_listener_rule" "rule_2" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 20

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      status_code  = 200
      message_body = "HELLO! IT WORKS!"
    }
  }

  condition {
    path_pattern {
      values = ["/mytest"]
    }
  }

  condition {
    host_header {
      values = ["myurl.pablosspot.ml"]
    }
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "my-targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
}

resource "aws_lb_target_group_attachment" "attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = data.aws_instance.instance.id
}

resource "aws_lb_listener_rule" "tg_rule" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 40

  action {
    type = "authenticate-oidc"

    authenticate_oidc {
      authorization_endpoint     = "${local.okta_url}/oauth2/v1/authorize"
      token_endpoint             = "${local.okta_url}/oauth2/v1/token"
      user_info_endpoint         = "${local.okta_url}/oauth2/v1/userinfo"
      issuer                     = local.okta_url
      session_cookie_name        = "TOKEN-My-OIDC"
      session_timeout            = 120
      scope                      = "openid profile"
      on_unauthenticated_request = "authenticate"
      client_id                  = okta_app_oauth.oidc.client_id
      client_secret              = okta_app_oauth.oidc.client_secret
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["nginx.pablosspot.ml"]
    }
  }
}

resource "aws_security_group_rule" "lb_access" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = var.ec2_security_group_id
  source_security_group_id = aws_security_group.sg.id
}

resource "aws_lambda_function" "lambda" {
  function_name    = "my-lambda-backend"
  runtime          = "python3.9"
  timeout          = 30
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.lambda.output_path
  handler          = "lambda.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "aws_iam_role" "lambda" {
  name        = "my-lambda-role"
  description = "Role for lambda function called by load balancer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lb_target_group" "lambda" {
  name        = "lambda-tg"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = aws_lambda_function.lambda.arn
  depends_on = [
    aws_lambda_permission.permission
  ]
}

resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowExecutionFromALB"
  principal     = "elasticloadbalancing.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  source_arn    = aws_lb_target_group.lambda.arn
}

resource "aws_lb_listener_rule" "lambda" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda.arn
  }

  condition {
    path_pattern {
      values = ["/lambda"]
    }
  }

  condition {
    host_header {
      values = ["myurl.pablosspot.ml"]
    }
  }
}

resource "okta_app_oauth" "oidc" {
  label          = "My OIDC"
  type           = "web"
  grant_types    = ["authorization_code"]
  response_types = ["code"]
  omit_secret    = false
  redirect_uris  = ["https://nginx.pablosspot.ml/oauth2/idpresponse"]
}

resource "okta_app_group_assignment" "assignment" {
  app_id   = okta_app_oauth.oidc.id
  group_id = data.okta_group.group.id
}
