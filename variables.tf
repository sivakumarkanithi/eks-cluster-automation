variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "siva"
}

variable "bastion_ami_id" {
  description = "Valid Ubuntu 22.04 AMI ID in us-east-1"
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.medium"
}

variable "bastion_root_volume_size" {
  description = "Root EBS volume size in GB for the bastion host"
  type        = number
  default     = 30
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name for SSH access to the bastion host"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Your public IP in CIDR notation, e.g. 203.0.113.10/32"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones for EKS subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "siva-cluster-1"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS; verify regional support before deployment"
  type        = string
  default     = "1.32"
}

variable "nodegroup_name" {
  description = "Name of the EKS managed nodegroup"
  type        = string
  default     = "siva-cluster-ng-1"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_volume_size" {
  description = "EBS root volume size in GB for each worker node"
  type        = number
  default     = 30
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}
