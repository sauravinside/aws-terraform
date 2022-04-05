# defining provider 
provider "aws" {
    access_key = ""
    secret_key = ""
    region     = "us-west-2"
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.27"
  instance_class       = "db.t2.micro"
  db_name                 = "project"
  username             = "admin"
  password             = "admin123"
  vpc_security_group_ids = ["sg-09af4c333e77629bc"]
  #vpc_security_group_ids= ["${aws_security_group.security_group.id}"]
  availability_zone = "us-west-2b"
  publicly_accessible = "false"
  #db_subnet_group_name      = "${aws_db_subnet_group.default.id}"
}