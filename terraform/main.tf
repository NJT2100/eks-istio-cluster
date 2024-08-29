data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  vpc_id = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr_block
  public_subnet_ids = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets
  subnet_ids = concat(local.public_subnet_ids, local.private_subnet_ids)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.0.0/22", "10.0.4.0/22", "10.0.8.0/22"]
  public_subnets  = ["10.0.100.0/22", "10.0.104.0/22", "10.0.108.0/22"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  # Instances launched into the Public subnet should be assigned a public IP address. Specify true to indicate that instances launched into the subnet should be assigned a public IP address
  map_public_ip_on_launch = true

}

################
#  EKS MODULE  #
################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "development"
  cluster_version = "1.30"

  # to enable public and private access for eks cluster endpoint
  cluster_endpoint_public_access = true

  # install eks managed addons
  # more details are here - https://docs.aws.amazon.com/eks/latest/userguide/
  cluster_addons = {
    coredns                = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy             = {
      most_recent = true
    }
    vpc-cni                = {
      most_recent = true
      before_compute = true
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
  
  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids
  # subnets where the eks cluster needs to be created
  control_plane_subnet_ids = local.private_subnet_ids

  # EKS Managed Node Groups
  eks_managed_node_group_defaults = {
    instance_types = ["t2.nano", "t2.micro", "t2.small", "t2.medium", "t2.large"]
  }

  eks_managed_node_groups = {
    default = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.medium"]
      iam_role_attach_cni_policy = true

      min_size       = 3
      max_size       = 3
      desired_size   = 3
    }
  }

  access_entries = {
    # One access entry with a policy associated
    roles = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.eks_iam_role.arn
    }
  }

  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

################################
#  ROLES FOR SERVICE ACCOUNTS  #
################################

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

##############################
#  IAM ROLE FOR EKS CLUSTER  #
##############################

resource "aws_iam_role" "eks_iam_role" {
  name = "EKSDevelopmentRole"

  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": [
            "eks.amazonaws.com"
          ]
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "eks_iam_role_attach" {
  role       = aws_iam_role.eks_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}