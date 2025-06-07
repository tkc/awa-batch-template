###############################################################################
# CloudWatch Logs 関連リソース
###############################################################################

# CloudWatch Logs設定
locals {
  # ログ関連の共通設定
  logs_config = {
    group_name        = "/aws/batch/${local.name_prefix}-fargate"
    stream_prefix     = "fargate-batch"
    retention_days    = var.log_retention_days
  }
  
  # ログタグ設定
  logs_tags = merge(local.common_tags, {
    Service     = "CloudWatch Logs"
    Application = "AWS Batch"
  })
}

# CloudWatch Logsグループ
# Batchジョブからのログを保存するためのロググループを作成
resource "aws_cloudwatch_log_group" "batch_logs" {
  name              = local.logs_config.group_name
  retention_in_days = local.logs_config.retention_days
  kms_key_id        = aws_kms_key.cloudwatch_logs_key.arn

  tags = local.logs_tags
}

###############################################################################
# CloudWatch Logs および KMS アクセス用のIAMポリシー
###############################################################################

# 最小権限のCloudWatch Logsアクセスポリシー
resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "${local.name_prefix}-cloudwatch-logs-policy"
  description = "Policy for CloudWatch Logs access with minimal permissions"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        # 特定のロググループのみにアクセスを制限
        Resource = [
          "${aws_cloudwatch_log_group.batch_logs.arn}",
          "${aws_cloudwatch_log_group.batch_logs.arn}:*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# KMS暗号化キーへのアクセス権限ポリシー
resource "aws_iam_policy" "kms_access_policy" {
  name        = "${local.name_prefix}-kms-access-policy"
  description = "Policy for KMS access to CloudWatch Logs encryption key"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKMSDecryptAndGenerate"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        # 特定のKMSキーのみにアクセスを制限
        Resource = aws_kms_key.cloudwatch_logs_key.arn
      }
    ]
  })

  tags = local.common_tags
}
