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

# creating a public subnet in vpc
resource "aws_subnet" "public_subnet2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "20.20.3.0/24"
  availability_zone = "us-west-2c"
  map_public_ip_on_launch = "1"
  tags = {
    Name = "public2_tf_subnet"
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

# route table association public subnet

resource "aws_route_table_association" "association_rt_public2" {
  subnet_id      = aws_subnet.public_subnet2.id
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
  name        = "terraform_security_group"

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

#actual instance in load balancer attached to target group and registered in the ALB
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


resource "aws_lb" "test" {
  name               = "project-ALB"
  internal           = false
  load_balancer_type = "application"
  #security_groups    = [aws_security_group.security_griup.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet2.id]
  
  tags = {
    Environment = "production"
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
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.test.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-west-2:124058707612:certificate/078fb849-dd7f-4c15-9f3a-76b7ced7b5a6"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}
