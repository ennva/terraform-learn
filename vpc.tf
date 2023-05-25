module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "myapp-vpc"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.azs.names
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  # These 3 tags below tied vpc and subnet in a cluster 
  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }
  public_subnet_tags = { 
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    #cloud-native-loadbalabncer
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    #loadbalancer-service
    "kubernetes.io/role/internal-elb" = 1
  }

}

