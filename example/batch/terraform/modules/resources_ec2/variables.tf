# AWSリージョン
# リソースをデプロイするAWSリージョンを指定します
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  # デフォルトは東京リージョン
  default     = "ap-northeast-1"
}

# バッチジョブのIAMロールARN
# ジョブ実行時に使用されるIAMロールのARNを指定します
variable "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs"
  type        = string
}

# 環境名
# デプロイされる環境（dev/staging/prodなど）を指定します
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# プロジェクト名
# このインフラが属するプロジェクトの名前を指定します
variable "project_name" {
  description = "Name of the project"
  type        = string
}

# VPC ID
# バッチリソースをデプロイするVPCのIDを指定します
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# プライベートサブネットIDリスト
# バッチインスタンスを配置するプライベートサブネットのIDリスト
variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

# ECR（Elastic Container Registry）関連の変数
# コンテナイメージの格納場所に関する設定
# ECRリポジトリ名
# 使用する既存のECRリポジトリの名前を指定します
variable "ecr_repository_name" {
  description = "既存のECRリポジトリ名"
  type        = string
}

# バッチジョブ定義名
# 作成するAWS Batchジョブ定義の名前
variable "batch_job_definition_name" {
  description = "Name of the AWS Batch job definition"
  type        = string
  # デフォルト名は "batch-job"
  default     = "batch-job"
}

# バッチジョブキュー名
# 作成するAWS Batchジョブキューの名前
variable "batch_job_queue_name" {
  description = "Name of the AWS Batch job queue"
  type        = string
  # デフォルト名は "batch-job-queue"
  default     = "batch-job-queue"
}

# バッチコンピュート環境名
# 作成するAWS Batchコンピュート環境の名前
variable "batch_compute_environment_name" {
  description = "Name of the AWS Batch compute environment"
  type        = string
  # デフォルト名は "batch-compute-env"
  default     = "batch-compute-env"
}

# コンテナイメージURI
# バッチジョブで使用するコンテナイメージの完全URI
variable "container_image" {
  description = "Full ECR image URI for the batch job (e.g., 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/my-repo:latest)"
  type        = string
}

# EC2インスタンスタイプ
# コンピュート環境で使用するEC2インスタンスタイプのリスト
variable "instance_types" {
  description = "EC2 instance types to use in the compute environment"
  type        = list(string)
  # デフォルトは汎用的なm4.largeを使用
  # 特別な要件がある場合はここで適切なインスタンスタイプを指定します
  default     = ["m4.large"]
}

# 最大vCPU数
# コンピュート環境で使用する最大vCPU数を指定します
variable "max_vcpus" {
  description = "Maximum number of vCPUs in the compute environment"
  type        = number
  # デフォルトは4 vCPUまでのスケールアップを許可
  # 予算と負荷から適切な値を設定します
  default     = 4
}

# 最小vCPU数
# コンピュート環境で常に維持する最小vCPU数を指定します
variable "min_vcpus" {
  description = "Minimum number of vCPUs in the compute environment"
  type        = number
  # デフォルトは0（ジョブがない時はインスタンスを維持しない）
  # 続行的にジョブがある場合や即時実行が必要な場合は値を増やします
  # デフォルトは0（ジョブが来たときにスケールアップ）
  # ジョブ開始までの待ち時間を短縮するために増やすことも可能
  default     = 0
}

# 共通環境変数の値
# すべてのコンテナに設定される共通の環境変数値
variable "common_env_var_value" {
  description = "Value for the common environment variable 'key'"
  type        = string
  # デフォルト値は単純な"value"
  # 実際の実装では、より意味のある値に置き換えます
  default     = "value"
}

# 希望外vCPU数
# 実行開始時に相当する、初期の希望スケールを指定します
variable "desired_vcpus" {
  description = "Desired number of vCPUs in the compute environment"
  type        = number
  default     = 0
}

# 共通タグ
# すべてのリソースに付与する共通タグのマップ
variable "common_tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)
  # デフォルトは空のタグマップ
  # 必要に応じてタグを追加できます（例: Team = "DevOps", CostCenter = "123"）
  default     = {}
}

# Slack通知用のWebhook URL
variable "slack_webhook_url" {
  description = "Slack通知用のWebhook URL"
  type        = string
  default     = ""
  sensitive   = true
}
