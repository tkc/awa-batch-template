#------------------------------------------------------------------------------
# AWS Fargate リソースモジュール - 出力変数
#
# このファイルには、他のモジュールやメインTerraformコードで
# 参照できるようにエクスポートされる出力変数が定義されています。
#------------------------------------------------------------------------------

# セキュリティグループ出力
#----------------------------------------------------------------------

output "batch_security_group_id" {
  description = "AWS Batch Fargateコンピューティング環境用のセキュリティグループID"
  value       = aws_security_group.batch_compute_environment.id
  # 他のリソースやモジュールでこのセキュリティグループを参照するために使用
}

# ログ設定出力
#----------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Fargateバッチジョブ用のCloudWatch Logsグループ名"
  value       = aws_cloudwatch_log_group.batch_logs.name
  # ログ分析やアラーム設定時に参照するために使用
}

# IAMロール出力
#----------------------------------------------------------------------

output "batch_job_role_arn" {
  description = "バッチジョブ用IAMロールのARN（環境から渡されたもの）"
  value       = var.batch_job_role_arn
  # 参照用に元の変数値を出力（このモジュールでは作成せず渡されたもの）
}

output "ecs_execution_role_arn" {
  description = "FargateタスクのECS実行ロールARN"
  value       = aws_iam_role.ecs_execution_role.arn
  # ECSタスク実行関連の設定で参照するために使用
}

output "batch_service_role_arn" {
  description = "AWS Batchサービスロールのarn"
  value       = aws_iam_role.batch_service_role.arn
  # バッチサービスロールを参照するために使用
}

# ジョブ定義出力
#----------------------------------------------------------------------

output "sample_job_definition_arn" {
  description = "サンプルFargateバッチジョブ定義のARN"
  value       = aws_batch_job_definition.fargate_sample.arn
  # ジョブのサブミット時などに参照するために使用
}

# ジョブキュー出力
#----------------------------------------------------------------------

output "job_queue_arn" { # 出力名を変更
  description = "FargateジョブキューのARN" # 説明を変更
  value       = aws_batch_job_queue.fargate_queue.arn # main.tf で変更したリソース名を参照
  # ジョブのサブミット時に参照するために使用
}

# 低優先度ジョブキューの出力は削除しました

# コンピューティング環境出力
#----------------------------------------------------------------------

output "fargate_compute_environment_arn" {
  description = "Fargateコンピューティング環境のARN"
  value       = aws_batch_compute_environment.fargate.arn
  # 標準Fargate環境を参照するために使用
}
