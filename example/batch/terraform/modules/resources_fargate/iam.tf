###############################################################################
# IAM ロールとポリシーアタッチメント
###############################################################################

locals {
  # IAM設定に関する共通変数
  iam_config = {
    path                   = "/service-role/"
    ecs_execution_role     = "${local.name_prefix}-fargate-execution-role"
    batch_service_role     = "${local.name_prefix}-batch-service-role"
  }
  
  # IAMリソースのタグ
  iam_tags = merge(local.common_tags, {
    Service = "IAM"
  })
}

#----------------------------------------------------------------------
# ECS実行ロール（Fargateタスク実行用）
#----------------------------------------------------------------------

# Fargate用のECS実行ロール
# コンテナ起動時に使用され、ECRからのイメージ取得やCloudWatchへのログ書き込みを行う
resource "aws_iam_role" "ecs_execution_role" {
  name        = local.iam_config.ecs_execution_role
  description = "Role that allows Fargate tasks to call AWS services"
  path        = local.iam_config.path

  # ECSタスクがこのロールを引き受けられるように設定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.iam_tags
}

# ECS実行ロールに標準のECSタスク実行ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 最小権限のCloudWatch Logsポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_execution_role_logs" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

# KMS権限ポリシーをECS実行ロールにアタッチ
resource "aws_iam_role_policy_attachment" "ecs_execution_role_kms" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.kms_access_policy.arn
}

# ECRアクセス用のインラインポリシー
resource "aws_iam_role_policy" "ecs_execution_role_ecr" {
  name = "ECRAccessPolicy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid     = "AllowECROperations"
        Effect  = "Allow"
        Action  = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"  # ECR認証トークン取得にはリソースレベルのアクセス制御が使用できないため
      }
    ]
  })
}

#----------------------------------------------------------------------
# AWS Batch サービスロール
#----------------------------------------------------------------------

# AWS Batch serviceロール
# Batchサービスがリソースを管理するために使用する
resource "aws_iam_role" "batch_service_role" {
  name        = local.iam_config.batch_service_role
  description = "Role that allows AWS Batch to manage resources on your behalf"
  path        = local.iam_config.path

  # AWS Batchサービスがロールを引き受けることを許可
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

  tags = local.iam_tags
}

# BatchサービスロールにAWS管理ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

#----------------------------------------------------------------------
# 既存のBatchジョブロールへのKMS権限付与
#----------------------------------------------------------------------

# 外部から渡されたBatchジョブロールにKMS権限を付与
resource "aws_iam_role_policy_attachment" "batch_job_role_kms" {
  # ARNからロール名を抽出
  role       = element(split("/", var.batch_job_role_arn), length(split("/", var.batch_job_role_arn)) - 1)
  policy_arn = aws_iam_policy.kms_access_policy.arn
}
