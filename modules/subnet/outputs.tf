output "subnet" {
    value = aws_subnet.myapp-subnet-1
}

output "gateway" {
    value = aws_internet_gateway.myapp-igw
}
