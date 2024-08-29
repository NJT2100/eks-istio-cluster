variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "eks-vpc"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr_blocks" {
  description = "Available cidr blocks for private subnets"
  type        = list(string)
  default     = [ 
    "10.0.0.0/22",
    "10.0.4.0/22",
    "10.0.8.0/22"
  ]
}

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets"
  type        = list(string)
  default     = [ 
    "10.0.100.0/22",
    "10.0.104.0/22",
    "10.0.108.0/22" 
  ]
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "development"
}

variable "cluster_version" {
  description = "EKS Cluster version"
  type        = string
  default     = "1.30"
}

# Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
variable "eks_managed_node_config" {
  type  = list(object({
    ami_type       = string
    instance_types = list(string)

    min_size       = number
    max_size       = number
    desired_size   = number

    iam_role_attach_cni_policy = bool
  }))
  default = [ {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t2.medium"]

    min_size       = 3
    max_size       = 3
    desired_size   = 3

    iam_role_attach_cni_policy = true
  } ]
  
}

variable "istio_security_group_rules" {
  type = map(object({
    from_port   = number
    to_port     = number
    ip_protocol = string 
    description = string
  }))
  default = {
    grpc = {
      from_port   = 15010
      to_port     = 15010
      ip_protocol = "tcp"
      description = "Istio GRPC XDS"
    }
    mtls = {
      from_port   = 15012
      to_port     = 15012
      ip_protocol = "tcp"
      description = "Istio mTLS with k8s signed cert"
    }
    webhook = {
      from_port   = 15017
      to_port     = 15017
      ip_protocol = "tcp"
      description = "Istio webhook validation and injection"
    }
    monitoring = {
      from_port   = 15014
      to_port     = 15014
      ip_protocol = "tcp"
      description = "Istio monitoring/metrics gathering"
    }
  }
}

