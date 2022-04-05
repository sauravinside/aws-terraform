provider "aws" {
    access_key = ""
    secret_key = ""
    region     = "us-west-2"
}
resource "aws_instance" "web" {
   ami= "ami-0892d3c7ee96c0bf7"
   instance_type = "t2.micro"
   key_name= "iam-oregon-shubham"
   vpc_security_group_ids = ["sg-09af4c333e77629bc"]
   #user_data       = "${file("install_nginx.sh")}"
  tags = {
    Name = "web"
  }
}
output "IP" {
  value = aws_instance.web.public_ip
}