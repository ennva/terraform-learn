output "ec2_public_ip" {
    value = module.myapp-server.instance.public_ip
}

output "app_vpc_id" {
    value = aws_vpc.myapp-vpc.id
}

output "app_sg_id" {
    value = module.myapp-server.instance.security_groups
}

output "app_ami_id" {
    value = module.myapp-server.instance.ami
}

output "app_rtb_id" {
    value = module.myapp-subnet.subnet.id
}

output "app_gtw_id" {
    value = module.myapp-subnet.gateway.id
}
