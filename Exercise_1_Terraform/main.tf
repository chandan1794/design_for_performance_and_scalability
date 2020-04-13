# TODO: Designate a cloud provider, region, and credentials
provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

# TODO: provision 4 AWS t2.micro EC2 instances named Udacity T2
resource "aws_spot_instance_request" "Udacity_T2" {
  ami           = "ami-2757f631"
  spot_price    = "0.004"
  instance_type = "t2.micro"
  count         = 4
}


# TODO: provision 2 m4.large EC2 instances named Udacity M4
resource "aws_spot_instance_request" "Udacity_M4" {
  ami           = "ami-2757f631"
  spot_price    = "0.04"
  instance_type = "m4.large"
  count         = 2
}
