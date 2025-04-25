#------------------------------------------------------------------------------
# AWS Fargate リソースモジュール
#
# このモジュールは、AWS Batch用のFargate環境を構築し、以下のリソースを作成します:
# - CloudWatch Logsグループ（ログ保存用）
# - コンピューティング環境（通常のFargateのみ - Spot利用なし）
# - ジョブキュー（高優先度と低優先度、どちらも通常のFargateを使用）
# - ジョブ定義（サンプル）
# - 必要なIAMロール（BatchサービスロールとECS実行ロール）
# - セキュリティグループ
#------------------------------------------------------------------------------

# ローカル変数
locals {
  # プロジェクト名と環境の組み合わせによる命名プレフィックス
  # 例: myproject-dev
  name_prefix = "${var.project_name}-${var.environment}"
  
  # すべてのリソースに適用する共通タグ
  # 標準タグに加えて、変数から渡されたタグもマージします
  common_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name     # プロジェクト名
      "Environment" = var.environment      # 環境名（dev/staging/prod等）
      "ManagedBy"   = "terraform"          # 管理ツール
    }
  )
}

#----------------------------------------------------------------------
# CloudWatch Logs
#----------------------------------------------------------------------

# CloudWatch Logsグループ
# Batchジョブからのログを保存するためのロググループを作成
resource "aws_cloudwatch_log_group" "batch_logs" {
  name              = "/aws/batch/${local.name_prefix}-fargate"  # バッチログのパス規則に従った名前
  retention_in_days = var.log_retention_days                     # ログの保持期間（日数）
  kms_key_id        = var.kms_key_arn                           # ログの暗号化に使用するKMSキー（オプション）

  tags = local.common_tags
}

# AWS アカウント情報の取得
# 現在のAWSアカウントIDなどを取得するためのデータソース
data "aws_caller_identity" "current" {}

#----------------------------------------------------------------------
# AWS Batch設定（モジュール利用せず直接リソース定義）
#----------------------------------------------------------------------

# AWS Batch serviceロール
# AWS Batchがリソースを管理するために使用するIAMロール
resource "aws_iam_role" "batch_service_role" {
  name = "${local.name_prefix}-batch-service-role"
  description = "Role that allows AWS Batch to manage resources on your behalf"
  path = "/service-role/"  # サービスロール用の標準パス

  # batch.amazonaws.comサービスがこのロールを引き受けることを許可
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# BatchサービスIAMロールに標準のBatchサービスポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"  # AWS管理ポリシー
}

# 通常のFargate用のコンピューティング環境
# オンデマンドのFargateリソースを使用するコンピューティング環境
resource "aws_batch_compute_environment" "fargate" {
  # 固定名を使用してランダムな接尾辞を避ける（リソース置き換え時の問題を防止）
  compute_environment_name = "${local.name_prefix}-fargate"

  compute_resources {
    max_vcpus = var.max_vcpus  # 最大vCPU数（Fargateの場合はスケーリングの上限）

    # セキュリティグループ設定
    security_group_ids = [
      aws_security_group.batch_compute_environment.id
    ]

    # 実行するサブネット（プライベートサブネット推奨）
    subnets = var.private_subnet_ids

    # コンピューティングタイプ（Fargateを使用）
    type = "FARGATE"
  }

  # Batchサービスが使用するIAMロール
  service_role = aws_iam_role.batch_service_role.arn
  
  # 管理タイプ（AWS Batchによる管理）
  type         = "MANAGED"
  
  # 有効状態に設定
  state        = "ENABLED"
  
  # タグ設定（共通タグに名前タグを追加）
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-fargate-compute-env"
    }
  )

  # 重複作成を避けるためのライフサイクル設定
  # 新しいリソースを先に作成してから古いリソースを削除（ダウンタイムを防止）
  lifecycle {
    create_before_destroy = true
  }
}

# ジョブキュー（通常のFargate）
resource "aws_batch_job_queue" "fargate_queue" { # リソース名を変更
  name     = "${local.name_prefix}-fargate" 
  state    = "ENABLED"                                     # 有効状態
  priority = 100                                           # 優先度（必要に応じて調整）
  scheduling_policy_arn = var.scheduling_policy_arn        # スケジューリングポリシー（オプション）

  # 使用するコンピューティング環境の順序
  # 順序は小さい方から試行される
  compute_environment_order {
    order            = 0
    compute_environment = aws_batch_compute_environment.fargate.arn
  }
  
  # タグ設定
  tags = merge(
    local.common_tags,
    {
      JobQueue = "Fargate job queue"  # タグから High priority を削除
    }
  )

  # コンピューティング環境が先に作成されていることを保証
  depends_on = [aws_batch_compute_environment.fargate]
}

# 低優先度キューは削除しました

#----------------------------------------------------------------------
# AWS Batch Job Definitions
#----------------------------------------------------------------------

# Fargate用ジョブ定義
# Fargateで実行されるコンテナジョブの定義
resource "aws_batch_job_definition" "fargate_sample" {
  name                  = "${local.name_prefix}-fargate-sample"  # ジョブ定義名
  type                  = "container"                            # ジョブタイプ
  platform_capabilities = ["FARGATE"]                            # Fargate対応として明示的に指定
  propagate_tags        = true                                   # タグを関連リソースに伝播

  # パラメータのデフォルト値を追加
  # 実行時にオーバーライドすることができる
  parameters = {
    "CONFIG" = "{}"  # デフォルト値を空のJSONにする（実行時に上書き可能）
  }

  # コンテナプロパティの定義（JSON形式）
  container_properties = jsonencode({
    image       = var.container_image                     # 使用するコンテナイメージ
    jobRoleArn  = var.batch_job_role_arn                  # ジョブが使用するIAMロール
    executionRoleArn = aws_iam_role.ecs_execution_role.arn # ECSタスク実行ロール
    
    # Fargateでは、resourceRequirementsを使用する必要がある
    # CPU/メモリの値はFargateでサポートされている組み合わせに注意
    resourceRequirements = [
      {
        type  = "VCPU"
        value = tostring(var.fargate_vcpu)  # vCPU数
      },
      {
        type  = "MEMORY"
        value = tostring(var.fargate_memory)  # メモリ量（MiB）
      }
    ]

    # コンテナの環境変数設定
    # 基本的な環境変数と追加の環境変数を結合
    environment = concat(
      [
        {
          name  = "ENVIRONMENT"
          value = var.environment  # 環境名
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region   # AWSリージョン
        },
        {
        name  = "CUSTOM_ENVIRONMENT_1"
        value = var.common_env_var_value  # カスタム環境変数
        },
        {
          name  = "CONFIG"
          value = "Ref::CONFIG"  # パラメータ参照（ジョブ実行時にオーバーライド可能）
        }
      ],
      var.additional_environment_variables  # 追加環境変数
    )

    # コンテナの実行コマンド
    command = var.container_command
    
    # ログ設定
    logConfiguration = {
      logDriver = "awslogs"  # AWS Logsドライバーを使用
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.batch_logs.name  # ロググループ名
        "awslogs-region" = var.aws_region                           # リージョン
        "awslogs-stream-prefix" = "fargate-sample"                  # ログストリームプレフィックス
      }
      secretOptions = var.container_log_secrets  # シークレットオプション（必要な場合）
    }
    
    # Fargate用のネットワーク設定
    networkConfiguration = {
      assignPublicIp = var.assign_public_ip ? "ENABLED" : "DISABLED"  # パブリックIP割り当てオプション
    }
    
    # Fargateプラットフォームバージョン設定
    fargatePlatformConfiguration = {
      platformVersion = var.fargate_platform_version  # プラットフォームバージョン
    }
  })

  # リトライ戦略 - ジョブ失敗時の再試行設定
  retry_strategy {
    attempts = var.retry_attempts  # 最大再試行回数
    
    # 終了条件に応じたアクション設定
    # 例: 特定の終了コードでリトライ/終了など
    dynamic "evaluate_on_exit" {
      for_each = var.retry_exit_conditions
      content {
        action       = evaluate_on_exit.value.action         # アクション（RETRY/EXIT）
        on_reason    = lookup(evaluate_on_exit.value, "on_reason", null)  # 理由のパターン
        on_exit_code = lookup(evaluate_on_exit.value, "on_exit_code", null)  # 終了コード
        on_status_reason = lookup(evaluate_on_exit.value, "on_status_reason", null)  # ステータス理由
      }
    }
  }

  # タグ設定
  tags = merge(
    local.common_tags,
    {
      JobDefinition = "Fargate Standard batch job"  # ジョブ定義タイプを示すタグ
    }
  )
}

# Compute環境用のセキュリティグループ
# AWS Batchのコンピューティング環境で使用するセキュリティグループ
resource "aws_security_group" "batch_compute_environment" {
  name        = "${local.name_prefix}-batch-fargate-sg"
  description = "Security group for AWS Batch Fargate compute environment"
  vpc_id      = var.vpc_id  # VPC ID

  # 外部への接続のみ許可（コンテナからの送信トラフィック）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # すべてのプロトコル
    cidr_blocks = ["0.0.0.0/0"]  # すべての送信先
    description = "Allow all outbound traffic"
  }
  
  # 注: 必要に応じて特定のポートへのingressルールを追加可能
  
  # タグ設定
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-batch-fargate-sg"
    }
  )

  # リソース置き換え時の問題を避けるライフサイクル設定
  lifecycle {
    create_before_destroy = true
  }
}

# Fargate用のECS実行ロール
# Fargateタスクの実行に必要なECS実行ロール（コンテナ起動時に使用）
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.name_prefix}-fargate-execution-role"
  description = "Role that allows Fargate tasks to call AWS services"
  path = "/service-role/"  # サービスロール用の標準パス

  # 重要: ECSタスクがこのロールを引き受けられるように設定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"  # ECSタスクサービス
        }
      }
    ]
  })

  tags = local.common_tags
}

# ECS実行ロールに標準のECSタスク実行ポリシーをアタッチ
# ECRからのイメージプル、CloudWatchへのログ書き込みなどの権限を付与
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"  # AWS管理ポリシー
}

# CloudWatch Logsアクセス用ポリシーをアタッチ
# ログの完全な管理権限を付与（必要に応じて権限を制限することも可能）
resource "aws_iam_role_policy_attachment" "ecs_execution_role_logs" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"  # AWS管理ポリシー
}

# ECRアクセス用のインラインポリシーを作成
# コンテナイメージをECRから取得するための権限
resource "aws_iam_role_policy" "ecs_execution_role_ecr" {
  name = "ECRAccessPolicy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",  # レイヤーのダウンロードURL取得
          "ecr:BatchGetImage",           # イメージの取得
          "ecr:BatchCheckLayerAvailability",  # レイヤーの存在確認
          "ecr:GetAuthorizationToken"    # 認証トークン取得
        ]
        Effect   = "Allow"
        Resource = "*"  # すべてのECRリポジトリへのアクセスを許可
      }
    ]
  })
}
