# ローカル変数の定義
# 命名規則の一貫性維持や、環境間（dev/staging/prod）でのリソース分離を実現するために使用します
locals {
  # プロジェクト名と環境名を組み合わせて一意のプレフィックスを作成
  # 例: myproject-dev, myproject-staging, myproject-prod
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Batch環境の名前
  # コンピュート環境やジョブキューの命名に使用し、一貫性を確保します
  batch_compute_environment_name = "${local.name_prefix}-${var.batch_compute_environment_name}"
  batch_job_queue_name = "${local.name_prefix}-${var.batch_job_queue_name}"
  
  # すべてのリソースに適用する共通タグ
  # タグ付けはコスト分析、リソース管理、所有権の追跡に重要です
  common_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "ManagedBy"   = "terraform"
    }
  )
}

#----------------------------------------------------------------------
# CloudWatch Logs設定
# バッチジョブの実行ログを保存するためのロググループを設定します
#----------------------------------------------------------------------

# CloudWatch Logsグループ
# ジョブのログを集約して監視・デバッグを容易にします
resource "aws_cloudwatch_log_group" "batch_logs" {
  # ロググループ名は階層構造で、検索や管理が容易になるよう設計されています
  name              = "/aws/batch/${local.name_prefix}-ec2"
  # ログの保持期間は14日間に設定（コスト最適化のため）
  # 長期保存が必要な場合は、この値を変更するか、エクスポート設定を追加してください
  retention_in_days = 14

  tags = local.common_tags
}

#----------------------------------------------------------------------
# AWS Batch設定
# EC2インスタンスを使用したバッチコンピュート環境の構築
#----------------------------------------------------------------------

# Compute環境用のセキュリティグループ
# バッチジョブを実行するEC2インスタンスのネットワーク制御に使用します
resource "aws_security_group" "batch_compute_environment" {
  # セキュリティグループ名はプレフィックスを含め、環境を識別できるようにします
  name        = "${local.name_prefix}-batch-ec2-sg"
  description = "Security group for AWS Batch EC2 compute environment"
  vpc_id      = var.vpc_id

  # アウトバウンド（外向き）トラフィックの設定
  # EC2インスタンスからインターネットへの接続を許可します
  egress {
    # 全ポート (0-65535)、全プロトコル("-1")を許可
    # これにより、コンテナはインターネット上の任意のサービスにアクセス可能になります
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # すべてのIPアドレス範囲へのアクセスを許可
    # 注意: 本番環境ではより制限的な設定が望ましい場合があります
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = local.common_tags
}

# AWS Batch terraform モジュールの利用
# コミュニティが提供するモジュールを使用して、AWS Batch環境を効率的に構築します
module "batch" {
  # テラフォームレジストリからバージョン指定でモジュールを利用
  # バージョン固定によって、予期しない変更を防ぎます
  source = "terraform-aws-modules/batch/aws"
  version = "2.1.0"

  # EC2インスタンスプロファイル用のIAMロール設定
  # このロールはEC2インスタンスに付与され、AWSリソースへのアクセス権を与えます
  instance_iam_role_name        = "${local.name_prefix}-batch-instance-role"
  instance_iam_role_path        = "/"
  instance_iam_role_description = "IAM role for AWS Batch EC2 instances"
  instance_iam_role_tags        = local.common_tags
  # インスタンスに追加で付与するポリシー
  # これらのポリシーにより、インスタンスが必要なAWSサービスにアクセスできるようになります
  instance_iam_role_additional_policies = [
    # S3への完全アクセス権（データの読み書きに必要）
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    # SSMを使用したインスタンス管理（トラブルシューティング用）
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    # ECRからのコンテナイメージ取得権限
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    # ECSコンテナエージェントに必要な権限
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]

  # AWS Batchサービス用のIAMロール設定
  # このロールはBatchサービス自体が使用し、リソースの管理を行います
  service_iam_role_name        = "${local.name_prefix}-batch-service-role"
  service_iam_role_path        = "/"
  service_iam_role_description = "IAM role for AWS Batch service"
  service_iam_role_tags        = local.common_tags
  # Batchサービスに追加で付与するポリシー
  # BatchがEC2インスタンスを操作するために必要です
  service_iam_role_additional_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
  ]

  # スポットフリートロールは作成しない
  create_spot_fleet_iam_role = false
  # spot_fleet_iam_role_name        = "${local.name_prefix}-batch-spot-fleet-role" # 不要
  # spot_fleet_iam_role_path        = "/" # 不要
  # spot_fleet_iam_role_description = "IAM role for AWS Batch spot fleet" # 不要
  # spot_fleet_iam_role_tags        = local.common_tags # 不要

  # コンピュート環境の定義 (オンデマンドのみ)
  compute_environments = {
    # オンデマンド環境（安定性重視の高優先度ジョブ用）
    on_demand = {
      name                  = "${local.name_prefix}-ec2-on-demand"
      type                  = "MANAGED"
      compute_environment_name_prefix = "${local.name_prefix}-ec2-"

      # コンピュートリソースの設定
      # オンデマンドEC2インスタンスの具体的な設定を行います
      compute_resources = {
        # EC2タイプを指定（Fargateではなく）
        type                = "EC2"
        # BEST_FIT_PROGRESSIVEはコスト効率と可用性のバランスを取る配置戦略
        # 最初はコスト効率の良いインスタンスを使い、徐々に別タイプも利用します
        allocation_strategy = "BEST_FIT_PROGRESSIVE"

        # vCPUの設定（スケーリング挙動を制御）
        # max_vcpus: 最大スケールアウト時のvCPU数
        # min_vcpus: 常に維持する最小vCPU数（コスト影響あり）
        # desired_vcpus: 初期状態で起動するvCPU数
        max_vcpus           = var.max_vcpus
        min_vcpus           = var.min_vcpus
        desired_vcpus       = var.desired_vcpus

        # 使用するEC2インスタンスタイプのリスト
        # 複数指定することでAWSが最適なタイプを選択できます
        instance_types      = var.instance_types

        # インスタンスを配置するプライベートサブネット
        # セキュリティ上、パブリックサブネットではなくプライベートサブネットを使用
        subnets             = var.private_subnet_ids

        # インスタンスに適用するセキュリティグループ
        # ネットワークトラフィックの制御に使用します
        security_group_ids  = [
          aws_security_group.batch_compute_environment.id
        ]

        # インスタンスに付けるタグ
        # インスタンスを識別しやすくするためのタグを設定
        tags = {
          Name = "${local.name_prefix}-batch-ec2-instance"
          Type = "OnDemand"
        }
      }
    }
    # スポットインスタンス環境は削除
  }

  # ジョブキューの定義 (高優先度のみ)
  job_queues = {
    # 高優先度キュー（オンデマンド環境を使用）
    # ビジネス上重要度の高いジョブや即時実行が必要なジョブ向け
    high_priority = {
      name     = "${local.name_prefix}-ec2-high-priority"
      state    = "ENABLED"
      # 優先度は100（数値が大きいほど優先度が高い）
      priority = 100
      # スケジューリングポリシー
      # null = デフォルトのファーストインファーストアウト（FIFO）スケジューリング
      # フェアシェアポリシーを使用する場合はARNを指定します
      scheduling_policy_arn = null  # ファーストインファーストアウト（FIFO）スケジューリング

      # コンピュート環境の使用順序 (オンデマンドのみ)
      compute_environment_order = [
        {
          order               = 0
          compute_environment = "on_demand" # モジュール内のキー名を参照
        }
      ]

      tags = {
        JobQueue = "EC2 High priority job queue"
      }
    }
    # 低優先度キューは削除
  }

  tags = local.common_tags
}

#----------------------------------------------------------------------
# AWS Batch Job Definitions
# ジョブの実行内容、リソース割り当て、環境変数などを定義します
#----------------------------------------------------------------------

# ジョブ定義
# サンプルジョブの設定 - EC2環境で実行するコンテナ化されたジョブの仕様を定義
resource "aws_batch_job_definition" "sample1" {
  # ジョブ定義名（命名規則に沿った一意の名前）
  name                  = "${local.name_prefix}-ec2-sample1"
  # タイプは「container」（コンテナ化されたジョブであることを示す）
  type                  = "container"
  # タグの伝播を有効化（親リソースからタグを継承）
  propagate_tags        = true
  # プラットフォーム機能をEC2に設定（Fargateではなく）
  platform_capabilities = ["EC2"]

  # コンテナのプロパティ（JSON形式でエンコード）
  # コンテナの実行環境、リソース、環境変数などを指定します
  container_properties = jsonencode({
    # 使用するコンテナイメージのURI
    # 例: 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/my-repo:latest
    image = var.container_image
    # リソース割り当て
    # vcpus: コンテナに割り当てるvCPU数
    # memory: コンテナに割り当てるメモリ量（MB単位）
    vcpus = 1
    memory = 2048
    # コンテナで実行するコマンド（空配列はイメージのデフォルトコマンドを使用）
    command = []
    # ジョブ実行時に使用するIAMロール
    # このロールにより、コンテナはAWSリソースにアクセスできます
    jobRoleArn = var.batch_job_role_arn

    # 環境変数の設定
    # コンテナ内のアプリケーションに渡す環境変数を定義します
    environment = [
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
          name  = "AWS_REGION"
          value = var.aws_region
        },
      {
        name  = "CUSTOM_ENVIRONMENT"
        value = var.common_env_var_value
      }
    ]

    # ボリュームとマウントポイントの設定（現在は空）
    # コンテナにデータボリュームをマウントする場合に設定します
    mountPoints = []
    volumes = []

    # ログ設定
    # コンテナのログをCloudWatch Logsに送信する設定
    logConfiguration = {
      # awslogsドライバーを使用（CloudWatch Logsに送信）
      logDriver = "awslogs"
      # ログオプションの設定
      # ロググループ、リージョン、ストリームプレフィックスを指定
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.batch_logs.name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "sample1"
      }
    }
  })
  
  # リトライ戦略 - 最大3回まで試行
  # ジョブ失敗時の再試行動作を定義します
  retry_strategy {
    # 最大試行回数（初回実行 + 最大3回のリトライ = 計4回）
    attempts = 3
    
    # 終了条件の評価ルール
    # 特定の終了条件に対する動作を定義します
    evaluate_on_exit {
      # 終了コード1、または任意の理由（"*"）で失敗した場合のリトライ設定
      action       = "RETRY"  # リトライする
      on_reason    = "*"     # 任意の理由
      on_exit_code = 1       # 終了コード1（一般的なエラーコード）
    }
    
    evaluate_on_exit {
      # 終了コード0（正常終了）の場合のアクション
      action       = "EXIT"   # 正常終了として処理
      on_exit_code = 0         # 終了コード0（成功）
    }
  }

  # ジョブ定義に対するタグ
  # 共通タグとジョブ定義固有のタグをマージ
  tags = merge(
    local.common_tags,
    {
      # このジョブ定義を識別するための専用タグ
      JobDefinition = "EC2 Standard batch job"
    }
  )
}
