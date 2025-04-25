# 変数定義
variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "環境名（dev/stg/prod）"
  type        = string
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
}

variable "vpc_id" {
  description = "使用するVPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "FargateコンテナをデプロイするVPCのプライベートサブネットID"
  type        = list(string)
}

variable "max_vcpus" {
  description = "コンピューティング環境の最大vCPU数"
  type        = number
  default     = 4
}

variable "fargate_vcpu" {
  description = "Fargateコンテナに割り当てるvCPU"
  type        = number
  default     = 0.5
}

variable "fargate_memory" {
  description = "Fargateコンテナに割り当てるメモリ（MiB）"
  type        = number
  default     = 1024
}

variable "batch_job_role_arn" {
  description = "AWSバッチジョブがAWSリソースにアクセスするためのIAMロールARN"
  type        = string
}

variable "ecr_repository_name" {
  description = "コンテナイメージのECRリポジトリ名"
  type        = string
}

variable "container_image" {
  description = "使用するコンテナイメージURI"
  type        = string
}

variable "batch_job_definition_name" {
  description = "バッチジョブ定義名"
  type        = string
  default     = "sample-job"
}

variable "batch_job_queue_name" {
  description = "バッチジョブキュー名"
  type        = string
  default     = "sample-queue"
}

variable "batch_compute_environment_name" {
  description = "バッチコンピューティング環境名"
  type        = string
  default     = "sample-compute"
}

variable "common_tags" {
  description = "すべてのリソースに付与する共通タグのマップ"
  type        = map(string)
  default     = {}
}

variable "common_env_var_value" {
  description = "サンプル環境変数の値"
  type        = string
  default     = "default-value"
}

variable "log_retention_days" {
  description = "CloudWatch Logsのログ保持期間（日数）"
  type        = number
  default     = 14
}

variable "kms_key_arn" {
  description = "ログを暗号化するKMSキーのARN（オプション）"
  type        = string
  default     = null
}

variable "scheduling_policy_arn" {
  description = "ジョブキューのスケジューリングポリシーARN（オプション）"
  type        = string
  default     = null
}

variable "fargate_platform_version" {
  description = "Fargateプラットフォームバージョン"
  type        = string
  default     = "LATEST"
}

variable "retry_attempts" {
  description = "ジョブ失敗時の最大再試行回数"
  type        = number
  default     = 1
}

variable "retry_exit_conditions" {
  description = "リトライ戦略の終了条件の設定"
  type        = list(object({
    action          = string
    on_reason       = optional(string)
    on_exit_code    = optional(string)
    on_status_reason = optional(string)
  }))
  default     = [
    {
      action     = "RETRY"
      on_reason  = "Host EC2*"
    },
    {
      action      = "EXIT"
      on_exit_code = "0"
    },
    {
      action     = "EXIT"
      on_reason  = "*"
    }
  ]
}

variable "container_command" {
  description = "コンテナで実行するコマンド"
  type        = list(string)
  default     = ["echo", "Hello World"]
}

variable "additional_environment_variables" {
  description = "コンテナに追加する環境変数のリスト"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

variable "container_log_secrets" {
  description = "コンテナのログ設定で使用するシークレットのリスト"
  type        = list(object({
    name      = string
    valueFrom = string
  }))
  default     = []
}

variable "assign_public_ip" {
  description = "FargateコンテナにパブリックIPを割り当てるかどうか"
  type        = bool
  default     = false
}

# Slack 通知用の Webhook URL
variable "slack_webhook_url" {
  description = "Slack通知用のWebhook URL"
  type        = string
  default     = ""
  sensitive   = true
}
