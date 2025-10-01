
resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.prefix}-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = local.required_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_ecr_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_lambda_function" "event_logger" {
  function_name = "${local.prefix}-api"

  role          = aws_iam_role.lambda_execution_role.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_uri}:${var.image_tag}"

  publish       = true

  memory_size   = 128
  timeout       = 15

  tags = local.required_tags
}

resource "aws_lambda_alias" "event_logger" {
  name = "${local.prefix}-alias"
  function_name    = aws_lambda_function.event_logger.function_name
  function_version = aws_lambda_function.event_logger.version
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${local.prefix}-lambda-execution-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}