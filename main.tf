provider "aws" {
  region = "eu-central-1"
  # Try to set en environment variable to test it
  # or having .aws folder with config and credentials in your home directory
}

## This is not an official provider, need to declare it as required_providers in provider.tf file
#provider "linode" {
#  ###
#}

#variable "subnet_cidr_block" {
#  description = "subnet cidr block"
#}

#variable "vpc_cidr_block" {
#  description = "vpc cidr block"
#}

variable "environment" {
  description = "environment to deploy"
}

variable "env_prefix" {
  description = "environment prefix resource"
  type = string
}

variable cidr_blocks {
    description = "cidr blocks and name tags for vpc and subnets"
    type = list(object({
        cidr_block = string
        name = string
    }))
}

variable avail_zone {
    default = "eu-central-1a"
}

variable my_ip {
    default = "198.184.231.254/32"
}

variable my_ip_range {
    description = "define a range of ip address allowed to access resources in form of cidr"
    type = list(string)
}

variable instance_type {
    default = "t2.micro"
}

#variable my_public_key {}

variable public_key_location {}

variable private_key_location {}

resource "aws_vpc" "app-vpc" {
    #cidr_block = "10.0.0.0/16"
    cidr_block = var.cidr_blocks[0].cidr_block
    tags = {
        #Name: "development-vpc"
        #vpc_env: "dev"
        Name = "${var.env_prefix}-${var.cidr_blocks[0].name}"
    }
}

resource "aws_subnet" "app-subnet-1" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = var.cidr_blocks[1].cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-${var.cidr_blocks[1].name}"
    }
}

output "vpc-id" {
    value = aws_vpc.app-vpc.id
}

output "subnet-id" {
    value = aws_subnet.app-subnet-1.id
}

/*
# routing trafic from internet (virtual router)
resource "aws_route_table" "app-route-table" {
    vpc_id = aws_vpc.app-vpc.id
    
    route {
    	cidr_block = "0.0.0.0/0"
    	gateway_id = aws_internet_gateway.app-igw.id
    }
    
    tags = {
    	Name = "${var.env_prefix}-rtb"
    }
}
*/

resource "aws_default_route_table" "app-default-rtb" {
    default_route_table_id = aws_vpc.app-vpc.default_route_table_id
    
    route {
    	cidr_block = "0.0.0.0/0"
    	gateway_id = aws_internet_gateway.app-igw.id
    }
    
    tags = {
    	Name = "${var.env_prefix}-main-rtb"
    }
}

# virtual internet gateway
resource "aws_internet_gateway" "app-igw" {
    vpc_id = aws_vpc.app-vpc.id
    tags = {
    	Name = "${var.env_prefix}-igw"
    }
    
}

# associate a subnet to a routing table
resource "aws_route_table_association" "ass-rtb-subnet" {
    subnet_id = aws_subnet.app-subnet-1.id
    #route_table_id = aws_route_table.app-route-table.id
    route_table_id = aws_default_route_table.app-default-rtb.id
}

# configure security group to ssh your app
## resource "aws_security_group" "app-sg" {
# or define security rules in default sg
resource "aws_default_security_group" "app-default-sg" {
    #name = "app-sg"
    vpc_id = aws_vpc.app-vpc.id
    
    ingress {
    	from_port= 22
    	to_port= 22
    	protocol= "tcp"
    	cidr_blocks = [var.my_ip] 
    }
    
    ingress {
    	from_port= 8080
    	to_port= 8080
    	protocol= "tcp"
    	cidr_blocks = ["0.0.0.0/0"] 
    }
    
    egress {
    	from_port= 0
    	to_port= 0
    	protocol= "-1"
    	cidr_blocks = ["0.0.0.0/0"]
    	prefix_list_ids = []
    }
    
    tags = {
    	Name = "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
    	name   = "name"
      	values = ["*-ami-*-x86_64"]
    }
    filter {
    	name   = "virtualization-type"
    	values = ["hvm"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

resource "aws_key_pair" "ssh-key" {
    key_name = "eks-nodes"
    #public_key = var.my_public_key
    public_key = "${file(var.public_key_location)}"
}

resource "aws_instance" "app-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type
    
    subnet_id = aws_subnet.app-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.app-default-sg.id]
    availability_zone = var.avail_zone
    
    associate_public_ip_address = true
    
    key_name = aws_key_pair.ssh-key.key_name
    
    connection {
       	type     = "ssh"
      	user     = "ec2-user"
      	private_key = "${file(var.private_key_location)}"
      	host     = self.public_ip
    }
    
    provisioner "file" {
    	source = "entry-script.sh"
    	destination = "/home/ec2-user/entry-script-on-ec2.sh"
    }
    
    ### user_data
    #user_data = "${file("entry-script.sh")}"
    ### or
    provisioner "remote-exec" {
    	script = "${file("entry-script.sh")}"
    	/*
    	inline = [
    		"export ENV=dev",
    		"mkdir newdir"
    	]
    	*/
    }
    
    provisioner "local-exec" {
    	command = "echo ${self.public_ip}"
    }
    
    tags = {
    	Name = "${var.env_prefix}-server"
    }
}

output "ec2_public_ip" {
    value = aws_instance.app-server.public_ip
}

/*
## add this component only of you want add resource to an existing one
data "aws_vpc" "existing_vpc" {}

## creating new subnet to existing vpc (resource)
resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existing_vpc.id
     # the range will follow the existing one
    cidr_block = "10.0.20.0/24"
    availability_zone = "eu-central-1a"
    tags = {
        Name: "subnet-2-dev"
        #Name = "subnet-2-default"
    }
}
*/
