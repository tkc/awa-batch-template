output "batch_security_group_id" {
  description = "ID of the security group for AWS Batch EC2 compute environment"
  value       = aws_security_group.batch_compute_environment.id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Logs group for EC2 batch jobs"
  value       = aws_cloudwatch_log_group.batch_logs.name
}

output "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs (passed from environment)"
  value       = var.batch_job_role_arn
}

output "sample_job_definition_arn" {
  description = "ARN of the sample EC2 batch job definition"
  value       = aws_batch_job_definition.sample1.arn
}

output "high_priority_job_queue_arn" {
  description = "ARN of the EC2 high priority job queue"
  value       = module.batch.job_queues["high_priority"].arn
}

output "low_priority_job_queue_arn" {
  description = "ARN of the EC2 low priority job queue"
  value       = module.batch.job_queues["low_priority"].arn
}

output "on_demand_compute_environment_arn" {
  description = "ARN of the EC2 on-demand compute environment"
  value       = module.batch.compute_environments["on_demand"].arn
}

output "spot_compute_environment_arn" {
  description = "ARN of the EC2 spot compute environment"
  value       = module.batch.compute_environments["spot"].arn
}
