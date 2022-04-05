provider "aws" {
    access_key = ""
    secret_key = ""
    region     = "us-west-2"
}
resource "aws_instance" "oregon" {
   ami= "ami-0892d3c7ee96c0bf7"
   instance_type = "t2.micro"
   key_name= "iam-oregon"
   user_data       = "${file("install_jenkins.sh")}"
  tags = {
    Name = "development_instance"
  }
}