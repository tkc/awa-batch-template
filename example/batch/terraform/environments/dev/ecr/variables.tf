variable "aws_region" {
  description = "使用するAWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "awa-batch"
}

variable "environment" {
  description = "環境名（dev, staging, prod など）"
  type        = string
  default     = "dev"
}
