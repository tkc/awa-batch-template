variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "awa-batch"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "batch_job_definition_name" {
  description = "Name of the AWS Batch job definition"
  type        = string
  default     = "batch-job"
}

variable "batch_job_queue_name" {
  description = "Name of the AWS Batch job queue"
  type        = string
  default     = "batch-job-queue"
}

variable "batch_compute_environment_name" {
  description = "Name of the AWS Batch compute environment"
  type        = string
  default     = "batch-compute-env"
}

variable "container_image" {
  description = "Container image for the batch job"
  type        = string
  default     = null # Will be replaced by the ECR repository URL during deployment
}

variable "instance_types" {
  description = "EC2 instance types to use in the compute environment"
  type        = list(string)
  default     = ["m5.large", "c5.large"]
}

variable "max_vcpus" {
  description = "Maximum number of vCPUs in the compute environment"
  type        = number
  default     = 16
}

variable "min_vcpus" {
  description = "Minimum number of vCPUs in the compute environment"
  type        = number
  default     = 0
}

variable "desired_vcpus" {
  description = "Desired number of vCPUs in the compute environment"
  type        = number
  default     = 0
}

variable "use_spot_instances" {
  description = "Whether to use spot instances for the compute environment"
  type        = bool
  default     = true
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for input/output data"
  type        = string
  default     = null # Will be generated based on project name
}