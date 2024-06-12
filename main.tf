provider "aws" {
  region = "us-east-1"
}

data "aws_s3_bucket" "existing_bucket" {
  bucket = "blackjack-game-site"
}

resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = data.aws_s3_bucket.existing_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = data.aws_s3_bucket.existing_bucket.bucket_regional_domain_name
    origin_id   = "S3-blackjack-game-site"
  }
  enabled = true
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-blackjack-game-site"
    viewer_protocol_policy = "redirect-to-https"
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

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Sid    = "",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "lambda_exec_policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action: [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect: "Allow",
        Resource: "*"
      }
    ]
  })
}

resource "aws_lambda_function" "blackjack_game" {
  filename         = "blackjack_game.zip"
  function_name    = "blackjack_game"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "blackjack.handler"
  runtime          = "python3.8"
}
