###############################################################################
# KMS キー設定
###############################################################################

# CloudWatch Logs用のKMSキー設定
locals {
  # KMSキーポリシーで使用する共通のARNパターン
  cloudwatch_logs_arn_pattern = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
  
  # KMSキーのタグ
  kms_tags = merge(local.common_tags, {
    Name        = "${local.name_prefix}-cloudwatch-logs-kms-key"
    Description = "KMS key for CloudWatch Logs encryption"
    Service     = "CloudWatch Logs"
  })
}

# CloudWatch Logs用のKMSキー
resource "aws_kms_key" "cloudwatch_logs_key" {
  description             = "KMS key for CloudWatch Logs encryption in AWS Batch system"
  deletion_window_in_days = var.kms_key_deletion_window_days
  enable_key_rotation     = true
  
  # KMSキーポリシー - CloudWatch Logsサービスによる使用を許可
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "cloudwatch-logs-kms-policy"
    Statement = [
      # アカウントルートユーザーに完全な管理権限を付与
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = "kms:*"
        Resource  = "*"
      },
      # CloudWatch Logsサービスにキーの使用権限を付与
      {
        Sid       = "Allow CloudWatch Logs to use the key"
        Effect    = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action    = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource  = "*"
        # 特定のCloudWatch Logsリソースのみでの使用を制限
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = local.cloudwatch_logs_arn_pattern
          }
        }
      }
    ]
  })

  tags = local.kms_tags
}

# KMSキーのエイリアス作成
resource "aws_kms_alias" "cloudwatch_logs_key_alias" {
  name          = "alias/${local.name_prefix}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs_key.key_id
}
