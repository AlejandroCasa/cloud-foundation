locals {
  name_prefix = "${var.service_name}-${var.environment}"

  # AWS Managed CloudFront Policy IDs (static global UUIDs)
  caching_disabled_policy_id       = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  all_viewer_except_host_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"

  lambda_env = merge(
    {
      AWS_LWA_PORT                 = tostring(var.app_port)
      AWS_LWA_READINESS_CHECK_PATH = var.readiness_check_path
    },
    var.environment_variables,
  )
}

# =============================================================================
# 1. Amazon ECR (Scan-on-Push + Strict 1-Image Lifecycle Policy for 500MB Quota)
# =============================================================================
# trivy:ignore:AVD-AWS-0033 AES256 used intentionally to preserve $0.00/mo Free Tier (KMS CMK costs $1.00/mo).
resource "aws_ecr_repository" "app" {
  name                 = local.name_prefix
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "keep_latest_only" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged container layers after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the latest 1 image to stay well under the 500 MB Free Tier quota"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}

# =============================================================================
# 2. CloudWatch Logs + Least-Privilege Lambda Execution Role
# =============================================================================
# trivy:ignore:AVD-AWS-0017 AWS-managed log encryption used intentionally ($0.00/mo vs $1.00/mo KMS CMK).
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}"
  retention_in_days = var.log_retention_days
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid     = "AllowLambdaServiceAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${local.name_prefix}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_logs_only" {
  statement {
    sid    = "WriteOwnCloudWatchLogGroupOnly"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }
}

resource "aws_iam_role_policy" "lambda_logs_only" {
  name   = "${local.name_prefix}-logs-only"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_logs_only.json
}

# =============================================================================
# 3. AWS Lambda (arm64 Graviton2 Container + Hard Concurrency Circuit Breaker)
# =============================================================================
resource "aws_lambda_function" "app" {
  function_name                  = local.name_prefix
  role                           = aws_iam_role.lambda_exec.arn
  package_type                   = "Image"
  image_uri                      = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
  architectures                  = ["arm64"]
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions

  environment {
    variables = local.lambda_env
  }

  tracing_config {
    mode = "PassThrough"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_logs_only,
  ]
}

# Zero-Trust: Forbid direct unauthenticated invocation; require SigV4 AWS_IAM from CloudFront OAC.
resource "aws_lambda_function_url" "app" {
  function_name      = aws_lambda_function.app.function_name
  authorization_type = "AWS_IAM"
  invoke_mode        = "BUFFERED"
}

# =============================================================================
# 4. Amazon CloudFront (Always-Free: OAC SigV4 + Shield Standard + Security Headers)
# =============================================================================
resource "aws_cloudfront_origin_access_control" "lambda_oac" {
  name                              = "${local.name_prefix}-lambda-oac"
  description                       = "SigV4 Origin Access Control for ${local.name_prefix} Lambda Function URL"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "${local.name_prefix}-security-headers"
  comment = "Zero-Trust HTTP security headers for ${local.name_prefix}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
  }
}

# trivy:ignore:AVD-AWS-0011 AWS WAF costs $5+/mo; mitigated via AWS Shield Standard + Lambda reserved concurrency circuit breaker.
# trivy:ignore:AVD-AWS-0010 CloudFront S3 access logging omitted to keep $0.00/mo Always-Free tier.
# trivy:ignore:AVD-AWS-0013 Default CloudFront certificate used when no custom domain is attached ($0.00/mo).
resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  price_class         = "PriceClass_100"
  comment             = "Zero-Cost CloudFront edge for ${local.name_prefix}"
  wait_for_deployment = false

  origin {
    origin_id                = "${local.name_prefix}-lambda-origin"
    domain_name              = replace(replace(aws_lambda_function_url.app.function_url, "https://", ""), "/", "")
    origin_access_control_id = aws_cloudfront_origin_access_control.lambda_oac.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id           = "${local.name_prefix}-lambda-origin"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = local.caching_disabled_policy_id
    origin_request_policy_id   = local.all_viewer_except_host_policy_id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Grant ONLY this CloudFront distribution permission to invoke the AWS_IAM Lambda Function URL.
resource "aws_lambda_permission" "allow_cloudfront_oac" {
  statement_id  = "AllowCloudFrontServicePrincipalInvokeUrl"
  action        = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.app.function_name
  principal     = "cloudfront.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.app.arn
}
