module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.2"

  cluster_name = "myapp-eks-cluster"
  cluster_version = "1.27"

  subnet_ids = module.myapp-vpc.private_subnets
  vpc_id = module.myapp-vpc.vpc_id

  #define worker nodes
  eks_managed_node_groups = {
    dev = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = [var.instance_type]
    }
  }

  tags = {
    name = "${var.env_prefix}-cluster"
  }
}
