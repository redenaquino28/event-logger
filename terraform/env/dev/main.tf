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