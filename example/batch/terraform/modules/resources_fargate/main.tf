###############################################################################
# AWS Fargate リソースモジュール - メイン定義
#
# このモジュールは、AWS Batch用のFargate環境を構築し、以下のリソースを作成します:
# - CloudWatch Logsグループ（KMS暗号化）
# - コンピューティング環境（Fargate）
# - ジョブキュー
# - ジョブ定義（サンプル）
# - IAMロールとポリシー
# - セキュリティグループ
###############################################################################

# ローカル変数定義
locals {
  # 命名プレフィックス - すべてのリソース名に使用
  name_prefix = "${var.project_name}-${var.environment}"
  
  # 共通タグ - すべてのリソースに適用
  common_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "ManagedBy"   = "terraform"
      "Module"      = "aws-batch-fargate"
    }
  )
}

# AWS アカウント情報の取得
data "aws_caller_identity" "current" {}

# AWS リージョン情報の取得
data "aws_region" "current" {
  name = var.aws_region
}
