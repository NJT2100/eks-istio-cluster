variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
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

variable "eks_node_ami_image" {
  description = "AMI Image used on EKS cluster node"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

