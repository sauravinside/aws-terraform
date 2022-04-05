# defining provider 
provider "aws" {
    access_key = ""
    secret_key = ""
    region     = "us-west-2"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "add-emp-project12"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}