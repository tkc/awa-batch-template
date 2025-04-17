#------------------------------------------------------------------------------
# AWS Fargate リソースモジュール - 変数定義
#
# このファイルには、Fargateベースのバッチ処理環境を設定するための
# すべての入力変数が定義されています。
#------------------------------------------------------------------------------

# 基本設定
#----------------------------------------------------------------------

variable "aws_region" {
  description = "リソースをデプロイするAWSリージョン（例: ap-northeast-1）"
  type        = string
  default     = "ap-northeast-1"  # デフォルトは東京リージョン
}

variable "batch_job_role_arn" {
  description = "バッチジョブが使用するIAMロールのARN（任意のAWSリソースにアクセスするための権限）"
  type        = string
  # 必須値のためデフォルト値なし
}

variable "environment" {
  description = "環境名（例: dev, staging, prod）- リソース名やタグに使用"
  type        = string
  # 必須値のためデフォルト値なし
}

variable "project_name" {
  description = "プロジェクト名 - リソース名やタグに使用"
  type        = string
  # 必須値のためデフォルト値なし
}

# ネットワーク設定
#----------------------------------------------------------------------

variable "vpc_id" {
  description = "使用するVPCのID（Fargateタスクを実行するVPC）"
  type        = string
  # 必須値のためデフォルト値なし
}

variable "private_subnet_ids" {
  description = "プライベートサブネットIDのリスト（Fargateタスクを実行するサブネット）"
  type        = list(string)
  # 必須値のためデフォルト値なし
}

# ECR関連の変数
#----------------------------------------------------------------------

variable "ecr_repository_name" {
  description = "既存のECRリポジトリ名（コンテナイメージを格納するリポジトリ）"
  type        = string
  # 必須値のためデフォルト値なし
}

# 命名設定
#----------------------------------------------------------------------

variable "batch_job_definition_name" {
  description = "AWS Batchジョブ定義の名前（上書き用、基本的にはプロジェクト・環境から自動生成）"
  type        = string
  default     = "batch-job"
}

variable "batch_job_queue_name" {
  description = "AWS Batchジョブキューの名前（上書き用、基本的にはプロジェクト・環境から自動生成）"
  type        = string
  default     = "batch-job-queue"
}

variable "batch_compute_environment_name" {
  description = "AWS Batchコンピューティング環境の名前（上書き用、基本的にはプロジェクト・環境から自動生成）"
  type        = string
  default     = "batch-compute-env"
}

# コンテナ設定
#----------------------------------------------------------------------

variable "container_image" {
  description = "バッチジョブ用のECRイメージURI (例: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/my-repo:latest)"
  type        = string
  # 必須値のためデフォルト値なし
}

variable "max_vcpus" {
  description = "コンピューティング環境で使用する最大vCPU数（スケーリング上限）"
  type        = number
  default     = 4  # 適度なデフォルト値
}

# Fargate固有の設定
#----------------------------------------------------------------------

variable "fargate_vcpu" {
  description = "Fargateコンテナ用に予約するvCPU数 (0.25, 0.5, 1, 2, 4, 8, 16 のいずれか)"
  type        = number
  default     = 1  # 基本的なワークロード向けのデフォルト値
}

variable "fargate_memory" {
  description = "Fargateコンテナ用に予約するメモリ量（MiB単位）(512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192など)"
  type        = number
  default     = 2048  # 基本的なワークロード向けのデフォルト値
}

variable "common_env_var_value" {
  description = "共通環境変数'CUSTOM_ENVIRONMENT_1'の値"
  type        = string
  default     = "value"
}

variable "common_tags" {
  description = "すべてのリソースに適用する共通タグのマップ"
  type        = map(string)
  default     = {}
}

# ログ設定
#----------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch Logsでログイベントを保持する日数"
  type        = number
  default     = 14  # 2週間（コスト最適化のための中間値）
}

variable "kms_key_arn" {
  description = "CloudWatchログの暗号化に使用するKMSキーのARN（オプション）"
  type        = string
  default     = null  # デフォルトではKMS暗号化なし
}

# ジョブキュー設定
#----------------------------------------------------------------------

variable "scheduling_policy_arn" {
  description = "ジョブキューに使用するフェアシェアスケジューリングポリシーのARN（オプション）"
  type        = string
  default     = null  # デフォルトではスケジューリングポリシーなし
}

# ネットワーク設定（Fargate固有）
#----------------------------------------------------------------------

variable "assign_public_ip" {
  description = "FargateタスクにパブリックIPを割り当てるかどうか（NATゲートウェイの代替）"
  type        = bool
  default     = false  # デフォルトではプライベートIPのみ（推奨）
}

variable "fargate_platform_version" {
  description = "使用するFargateプラットフォームバージョン（'LATEST'または'1.4.0'など）"
  type        = string
  default     = "LATEST"  # 常に最新機能を使用
}

# ジョブリトライ設定
#----------------------------------------------------------------------

variable "retry_attempts" {
  description = "ジョブが失敗したと見なす前に再試行する回数"
  type        = number
  default     = 3  # 一般的なデフォルト値
}

variable "retry_exit_conditions" {
  description = "リトライ戦略の条件リスト（終了コードや理由に基づく再試行制御）"
  type = list(object({
    action           = string            # RETRY または EXIT
    on_reason        = optional(string)  # 理由パターン（オプション）
    on_exit_code     = optional(number)  # 終了コード（オプション）
    on_status_reason = optional(string)  # ステータス理由（オプション）
  }))
  default = [
    {
      action       = "RETRY"
      on_reason    = "*"        # すべての理由
      on_exit_code = 1          # 終了コード1の場合、再試行
    },
    {
      action       = "EXIT"
      on_exit_code = 0          # 終了コード0の場合、正常終了
    }
  ]
}

# コンテナ実行設定
#----------------------------------------------------------------------

variable "container_command" {
  description = "コンテナに渡すコマンド（ENTRYPOINTをオーバーライド）"
  type        = list(string)
  default     = []  # デフォルトではコンテナのデフォルトコマンドを使用
}

variable "container_mount_points" {
  description = "コンテナのマウントポイント設定（ボリューム）"
  type        = list(any)
  default     = []  # デフォルトではマウントポイントなし
}

variable "container_volumes" {
  description = "コンテナのボリューム設定"
  type        = list(any)
  default     = []  # デフォルトではボリュームなし
}

variable "container_log_secrets" {
  description = "コンテナログ設定用のシークレットオプション"
  type        = list(any)
  default     = []  # デフォルトではシークレットなし
}

variable "additional_environment_variables" {
  description = "コンテナに渡す追加の環境変数"
  type = list(object({
    name  = string  # 環境変数名
    value = string  # 環境変数値
  }))
  default = []  # デフォルトでは追加環境変数なし
}
