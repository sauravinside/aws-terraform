provider "aws" {
    access_key = ""
    secret_key = ""
    region     = "us-west-2"
}
resource "aws_cloudformation_stack" "network" {
  name = "networking-stack"
  
  template_body = <<STACK

  "Resources": {
        "Instance1": {
            "Type": "AWS::EC2::Instance",
            "Properties": {
                "ImageId": "ami-0892d3c7ee96c0bf7",
                "KeyName": "iam-oregon-shubham",
                "InstanceType": "t2.micro",
                "SecurityGroupIds": [
                    "sg-09af4c333e77629bc"
                ],
                "SubnetId": "subnet-3f345f62",
                "Tags": [
                    {
                        "Key": "Name",
                        "Value": "Saurav"
                    }
                ]
            }
        }
    }

STACK
}