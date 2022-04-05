# defining provider 
provider "aws" {
    access_key = ""
    secret_key = ""
    region     = "us-west-2"
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "employee_image_table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 100
  write_capacity = 100
  hash_key       = "empid"

  attribute {
    name = "empid"
    type = "N"
  }
  
  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}