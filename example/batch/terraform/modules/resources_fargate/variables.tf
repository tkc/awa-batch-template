###############################################################################
# 変数定義
###############################################################################

#----------------------------------------------------------------------
# 基本設定
#----------------------------------------------------------------------

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

variable "common_tags" {
  description = "すべてのリソースに付与する共通タグのマップ"
  type        = map(string)
  default     = {}
}

#----------------------------------------------------------------------
# ネットワーク設定
#----------------------------------------------------------------------

variable "vpc_id" {
  description = "使用するVPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "FargateコンテナをデプロイするVPCのプライベートサブネットID"
  type        = list(string)
}

#----------------------------------------------------------------------
# IAM設定
#----------------------------------------------------------------------

variable "batch_job_role_arn" {
  description = "AWSバッチジョブがAWSリソースにアクセスするためのIAMロールARN"
  type        = string
}

#----------------------------------------------------------------------
# Fargate設定
#----------------------------------------------------------------------

variable "max_vcpus" {
  description = "コンピューティング環境の最大vCPU数"
  type        = number
  default     = 4
}

variable "fargate_vcpu" {
  description = "Fargateコンテナに割り当てるvCPU"
  type        = number
  default     = 0.5
  validation {
    condition     = contains([0.25, 0.5, 1, 2, 4, 8, 16], var.fargate_vcpu)
    error_message = "fargate_vcpuは、0.25, 0.5, 1, 2, 4, 8, 16のいずれかである必要があります。"
  }
}

variable "fargate_memory" {
  description = "Fargateコンテナに割り当てるメモリ（MiB）"
  type        = number
  default     = 1024
  validation {
    condition     = var.fargate_memory >= 512 && var.fargate_memory <= 30720
    error_message = "fargate_memoryは512〜30720の範囲内である必要があります。"
  }
}

variable "fargate_platform_version" {
  description = "Fargateプラットフォームバージョン"
  type        = string
  default     = "LATEST"
}

#----------------------------------------------------------------------
# コンテナ設定
#----------------------------------------------------------------------

variable "ecr_repository_name" {
  description = "コンテナイメージのECRリポジトリ名"
  type        = string
}

variable "container_image" {
  description = "使用するコンテナイメージURI"
  type        = string
}

variable "container_command" {
  description = "コンテナで実行するコマンド"
  type        = list(string)
  default     = ["echo", "Hello World"]
}

variable "additional_environment_variables" {
  description = "コンテナに追加する環境変数のリスト"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "common_env_var_value" {
  description = "サンプル環境変数の値"
  type        = string
  default     = "default-value"
}

#----------------------------------------------------------------------
# AWS Batch設定
#----------------------------------------------------------------------

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

variable "scheduling_policy_arn" {
  description = "ジョブキューのスケジューリングポリシーARN（オプション）"
  type        = string
  default     = null
}

variable "retry_attempts" {
  description = "ジョブ失敗時の最大再試行回数"
  type        = number
  default     = 1
}

variable "retry_exit_conditions" {
  description = "リトライ戦略の終了条件の設定"
  type = list(object({
    action           = string
    on_reason        = optional(string)
    on_exit_code     = optional(string)
    on_status_reason = optional(string)
  }))
  default = [
    # Fargateのコンテナエラーに対応するリトライ設定
    {
      action    = "RETRY"
      on_reason = "ContainerError:*"  # コンテナの一時的なエラー
    },
    {
      action    = "RETRY"
      on_reason = "Timeout:*"  # タイムアウトエラー
    },
    {
      action    = "RETRY"
      on_reason = "ResourceError:*"  # リソース関連のエラー
    },
    # 通常の終了条件 - 成功時
    {
      action       = "EXIT"
      on_exit_code = "0"
    },
    # その他すべてのエラーは失敗として扱う
    {
      action    = "EXIT"
      on_reason = "*"
    }
  ]
}

#----------------------------------------------------------------------
# ログ設定
#----------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch Logsのログ保持期間（日数）"
  type        = number
  default     = 14
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "log_retention_daysは、AWS CloudWatchの有効な保持期間値である必要があります。"
  }
}

variable "container_log_secrets" {
  description = "コンテナのログ設定で使用するシークレットのリスト"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

#----------------------------------------------------------------------
# KMS設定
#----------------------------------------------------------------------

variable "kms_key_arn" {
  description = "既存のKMSキーを使用する場合、そのARN"
  type        = string
  default     = null
}

variable "kms_key_deletion_window_days" {
  description = "KMSキーの削除待機期間（日数）"
  type        = number
  default     = 30
  validation {
    condition     = var.kms_key_deletion_window_days >= 7 && var.kms_key_deletion_window_days <= 30
    error_message = "kms_key_deletion_window_daysは7〜30の範囲内である必要があります。"
  }
}

#----------------------------------------------------------------------
# 通知設定
#----------------------------------------------------------------------

variable "slack_webhook_url" {
  description = "Slack通知用のWebhook URL"
  type        = string
  default     = ""
  sensitive   = true
}
