provider "aws" {
    access_key = ""
    secret_key = ""
    region     = "us-west-2"
}

/*data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["124058707612"]

    filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
} 

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["124058707612"] # Canonical
}*/

resource "aws_security_group" "sauravNEW_tf_allow_ssh_http" {
  name        = "sauravNEW_tf_allow_ssh_http"
  description = "Allow ssh and HTTP inbound traffic"

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0892d3c7ee96c0bf7"
  instance_type = "t3.micro"
  security_groups = ["${aws_security_group.sauravNEW_tf_allow_ssh_http.name}"]
  key_name = "iam-oregon"
  user_data = "${file("./install_jenkins1.sh")}"

  tags = {
    Name = "TerraformInstancewithJENKINS"
  }
}

output "IP" {
  value = aws_instance.web.public_ip
}