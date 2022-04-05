# defining provider 
provider "aws" {
    access_key = ""
    secret_key = ""
    region     = "us-west-2"
}
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

resource "aws_db_subnet_group" "default" {
  name        = "subnet-group"
  description = "Terraform example RDS subnet group"
  subnet_ids  = ["${aws_subnet.public_subnet.id}","${aws_subnet.private_subnet.id}"]
}

resource "aws_db_instance" "default" {
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
  db_subnet_group_name      = "${aws_db_subnet_group.default.id}"
}