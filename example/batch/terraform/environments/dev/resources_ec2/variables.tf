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

variable "instance_types" {
  description = "EC2 instance types to use in the compute environment"
  type        = list(string)
  default     = ["m4.large"]
}

variable "max_vcpus" {
  description = "Maximum number of vCPUs in the compute environment"
  type        = number
  default     = 4
}

variable "min_vcpus" {
  description = "Minimum number of vCPUs in the compute environment"
  type        = number
  default     = 0
}

variable "common_env_var_value" {
  description = "Value for the common environment variable 'key'"
  type        = string
  default     = "value"
}

variable "desired_vcpus" {
  description = "Desired number of vCPUs in the compute environment"
  type        = number
  default     = 0
}
