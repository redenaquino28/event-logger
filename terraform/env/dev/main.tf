resource "aws_dynamodb_table" "events" {
  name         = "${local.prefix}-dynamodb"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = local.required_tags
}

resource "aws_ecr_repository" "event_logger" {
  name                 = "event-logger"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = local.required_tags
}

resource "aws_ecr_lifecycle_policy" "keep_recent" {
  repository = aws_ecr_repository.event_logger.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last 3 images"
        selection = {
          tagStatus = "any"
          countType = "imageCountMoreThan"
          countNumber = 3
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "allow_github_oidc_role" {
  repository = aws_ecr_repository.event_logger.name

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid = "AllowPushPullForGitHubOIDCRole"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_iam_role.github_oidc_role.arn
        }
        Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:DescribeRepositories",
            "ecr:DescribeImages",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart"
        ]
      }
    ]
  })
}