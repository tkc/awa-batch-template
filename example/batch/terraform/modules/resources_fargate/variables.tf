variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# ECR関連の変数
variable "ecr_repository_name" {
  description = "既存のECRリポジトリ名"
  type        = string
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
  description = "Full ECR image URI for the batch job (e.g., 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/my-repo:latest)"
  type        = string
}

variable "max_vcpus" {
  description = "Maximum number of vCPUs in the compute environment"
  type        = number
  default     = 4
}

# Fargate固有の設定
variable "fargate_vcpu" {
  description = "The number of vCPUs to reserve for the Fargate container (0.25, 0.5, 1, 2, 4, 8, or 16)"
  type        = number
  default     = 1
}

variable "fargate_memory" {
  description = "The amount of memory (in MiB) to reserve for the Fargate container (512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192, etc.)"
  type        = number
  default     = 2048
}

variable "common_env_var_value" {
  description = "Value for the common environment variable 'key'"
  type        = string
  default     = "value"
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
