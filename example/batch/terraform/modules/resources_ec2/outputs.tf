# Batchコンピュート環境用セキュリティグループID
# 他のモジュールがこのグループIDを参照するための出力値
output "batch_security_group_id" {
  description = "ID of the security group for AWS Batch EC2 compute environment"
  value       = aws_security_group.batch_compute_environment.id
}

# CloudWatchロググループ名
# バッチジョブのログ出力先の名前を出力します
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Logs group for EC2 batch jobs"
  value       = aws_cloudwatch_log_group.batch_logs.name
}

# バッチジョブロールARN
# 環境から渡されたバッチジョブ用IAMロールARNを出力
output "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs (passed from environment)"
  value       = var.batch_job_role_arn
}

# サンプルジョブ定義ARN
# 作成したサンプルジョブ定義のARNを出力
output "sample_job_definition_arn" {
  description = "ARN of the sample EC2 batch job definition"
  value       = aws_batch_job_definition.sample1.arn
}

# ジョブキューARN
# オンデマンド環境を使用するジョブキューのARNを出力
output "job_queue_arn" { # 出力名を変更
  description = "ARN of the EC2 job queue" # 説明を変更
  value       = module.batch.job_queues["on_demand_queue"].arn # main.tf で変更したキー名を参照
}

# オンデマンドコンピュート環境ARN
# オンデマンドインスタンスを使用するコンピュート環境のARN
output "on_demand_compute_environment_arn" {
  description = "ARN of the EC2 on-demand compute environment"
  value       = module.batch.compute_environments["on_demand"].arn
}
