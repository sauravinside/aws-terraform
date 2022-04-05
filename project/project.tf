# creating vpc
resource "aws_vpc" "main" {
  cidr_block = "20.20.0.0/16"
  tags={
    Name = "demo_vpc_terraform"
  }
}

# creating a public subnet in vpc
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "20.20.1.0/24"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = "1"
  tags = {
    Name = "public_tf_subnet"
  }
}


# creating private subnet in vpc
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "20.20.2.0/24"
   availability_zone = "us-west-2b"
  tags = {
    Name = "private_tf_subnet"
  }
}

# creating a internet gateway and associating with vpc
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-IGW"
  }
}


#creating Elastic IP
resource "aws_eip" "eip" {
  vpc      = true
  tags = {
    Name = "tf_elastic_ip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "tf_NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}




#route table for public subnet with IGW
resource "aws_route_table" "table_public" {
  vpc_id = "${aws_vpc.main.id}"
 route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "rt_public"
  }
}
# route table association public subnet

resource "aws_route_table_association" "association_rt_public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.table_public.id
}

#route table for private subnet with Nat
resource "aws_route_table" "table_private" {
  vpc_id = "${aws_vpc.main.id}"
 route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }
  tags = {
    Name = "rt_private"
  }
}
# route table association private subnet

resource "aws_route_table_association" "association_rt_private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.table_private.id
}

# creating a sg and associating it with the vpc
resource "aws_security_group" "security_group" {
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-security_grp"
  }
}


# launch an instance
resource "aws_instance" "web" {
  ami           = "ami-0892d3c7ee96c0bf7"
  instance_type = "t2.micro"
  vpc_security_group_ids= ["${aws_security_group.security_group.id}"]
  subnet_id= aws_subnet.public_subnet.id
  key_name= "iam-oregon-shubham"
  #user_data = "${file("./apache.sh")}"
  tags = {
    Name = "Bastion_Host"
  }
}

# launch an instance
resource "aws_instance" "db" {
  ami           = "ami-0892d3c7ee96c0bf7"
  instance_type = "t2.micro"
  vpc_security_group_ids= ["${aws_security_group.security_group.id}"]
  subnet_id= aws_subnet.private_subnet.id
  key_name= "iam-oregon-shubham"
  tags = {
    Name = "Application_Tier"
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "add-emp-project12"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
}
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.s3_bucket.id
  key    = "aboutus.html"
  source = "aboutus.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "subnet-group"
  description = "Terraform example RDS subnet group"
  subnet_ids  = ["${aws_subnet.public_subnet.id}","${aws_subnet.private_subnet.id}"]
}

resource "aws_db_instance" "db_instance" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.27"
  instance_class       = "db.t2.micro"
  db_name                 = "project"
  username             = "admin"
  password             = "admin123"
  #vpc_security_group_ids = ["sg-09af4c333e77629bc"]
  vpc_security_group_ids= ["${aws_security_group.security_group.id}"]
  availability_zone = "us-west-2b"
  publicly_accessible = "false"
  db_subnet_group_name      = "${aws_db_subnet_group.db_subnet_group.id}"
  skip_final_snapshot       = true
  final_snapshot_identifier = "Ignore"
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

resource "aws_route53_zone" "hosted_zone" {
  name = "shubhamdomain.tk"
force_destroy="true"  

}

# resource "aws_route53_record" "blog-ns" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "blog.awssession.ml"
#   type    = "NS"
#   ttl     = "30"
#   records = aws_route53_zone.dev.name_servers
# }

resource "aws_lb" "alb" {
  name               = "project-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
  
  tags = {
    Environment = "project-ALB"
  }
}

resource "aws_lb_target_group" "target" {
  name     = "target-project"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "attach" {
  target_group_arn = aws_lb_target_group.target.arn
  target_id        = aws_instance.db.id
  port             = 80
}

resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-west-2:124058707612:certificate/078fb849-dd7f-4c15-9f3a-76b7ced7b5a6"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}

output "name_servers" {
  value = aws_route53_zone.hosted_zone.name_servers
}