###############################################################################
# AWS Fargate リソースモジュール - 出力変数
###############################################################################

#----------------------------------------------------------------------
# セキュリティグループ出力
#----------------------------------------------------------------------

output "batch_security_group_id" {
  description = "AWS Batch Fargateコンピューティング環境用のセキュリティグループID"
  value       = aws_security_group.batch_compute_environment.id
}

#----------------------------------------------------------------------
# ログ設定出力
#----------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Fargateバッチジョブ用のCloudWatch Logsグループ名"
  value       = aws_cloudwatch_log_group.batch_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "Fargateバッチジョブ用のCloudWatch LogsグループARN"
  value       = aws_cloudwatch_log_group.batch_logs.arn
}

#----------------------------------------------------------------------
# KMS設定出力
#----------------------------------------------------------------------

output "cloudwatch_logs_kms_key_arn" {
  description = "CloudWatch Logsの暗号化に使用するKMSキーのARN"
  value       = aws_kms_key.cloudwatch_logs_key.arn
}

output "cloudwatch_logs_kms_key_id" {
  description = "CloudWatch Logsの暗号化に使用するKMSキーのID"
  value       = aws_kms_key.cloudwatch_logs_key.key_id
}

output "cloudwatch_logs_kms_key_alias" {
  description = "CloudWatch Logsの暗号化に使用するKMSキーのエイリアス"
  value       = aws_kms_alias.cloudwatch_logs_key_alias.name
}

#----------------------------------------------------------------------
# IAMロール出力
#----------------------------------------------------------------------

output "batch_job_role_arn" {
  description = "バッチジョブ用IAMロールのARN（環境から渡されたもの）"
  value       = var.batch_job_role_arn
}

output "ecs_execution_role_arn" {
  description = "FargateタスクのECS実行ロールARN"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_execution_role_name" {
  description = "FargateタスクのECS実行ロール名"
  value       = aws_iam_role.ecs_execution_role.name
}

output "batch_service_role_arn" {
  description = "AWS Batchサービスロールのarn"
  value       = aws_iam_role.batch_service_role.arn
}

output "batch_service_role_name" {
  description = "AWS Batchサービスロール名"
  value       = aws_iam_role.batch_service_role.name
}

#----------------------------------------------------------------------
# AWS Batch リソース出力
#----------------------------------------------------------------------

output "fargate_compute_environment_arn" {
  description = "Fargateコンピューティング環境のARN"
  value       = aws_batch_compute_environment.fargate.arn
}

output "fargate_compute_environment_name" {
  description = "Fargateコンピューティング環境の名前"
  value       = aws_batch_compute_environment.fargate.compute_environment_name
}

output "job_queue_arn" {
  description = "FargateジョブキューのARN"
  value       = aws_batch_job_queue.fargate_queue.arn
}

output "job_queue_name" {
  description = "Fargateジョブキューの名前"
  value       = aws_batch_job_queue.fargate_queue.name
}

output "sample_job_definition_arn" {
  description = "サンプルFargateバッチジョブ定義のARN"
  value       = aws_batch_job_definition.fargate_sample.arn
}

output "sample_job_definition_name" {
  description = "サンプルFargateバッチジョブ定義の名前"
  value       = aws_batch_job_definition.fargate_sample.name
}

#----------------------------------------------------------------------
# モジュール設定出力
#----------------------------------------------------------------------

output "module_config" {
  description = "モジュールの主要な設定値"
  value = {
    environment          = var.environment
    project_name         = var.project_name
    aws_region           = var.aws_region
    max_vcpus            = var.max_vcpus
    fargate_vcpu         = var.fargate_vcpu
    fargate_memory       = var.fargate_memory
    log_retention_days   = var.log_retention_days
    retry_attempts       = var.retry_attempts
  }
}
