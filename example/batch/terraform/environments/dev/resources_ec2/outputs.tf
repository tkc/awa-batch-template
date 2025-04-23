output "batch_security_group_id" {
  description = "ID of the security group for AWS Batch compute environment"
  value       = module.resources.batch_security_group_id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Logs group for batch jobs"
  value       = module.resources.cloudwatch_log_group_name
}

output "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs"
  value       = module.resources.batch_job_role_arn
}

output "sample_job_definition_arn" {
  description = "ARN of the sample batch job definition"
  value       = module.resources.sample_job_definition_arn
}

output "high_priority_job_queue_arn" {
  description = "ARN of the high priority job queue"
  value       = module.resources.high_priority_job_queue_arn
}
