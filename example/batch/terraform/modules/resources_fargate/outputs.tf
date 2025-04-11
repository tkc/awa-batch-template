output "batch_security_group_id" {
  description = "ID of the security group for AWS Batch Fargate compute environment"
  value       = aws_security_group.batch_compute_environment.id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Logs group for Fargate batch jobs"
  value       = aws_cloudwatch_log_group.batch_logs.name
}

output "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs (passed from environment)"
  value       = var.batch_job_role_arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role for Fargate tasks"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "batch_service_role_arn" {
  description = "ARN of the AWS Batch service role"
  value       = aws_iam_role.batch_service_role.arn
}

output "sample_job_definition_arn" {
  description = "ARN of the sample Fargate batch job definition"
  value       = aws_batch_job_definition.fargate_sample.arn
}

output "high_priority_job_queue_arn" {
  description = "ARN of the Fargate high priority job queue"
  value       = aws_batch_job_queue.fargate_high_priority.arn
}

output "low_priority_job_queue_arn" {
  description = "ARN of the Fargate spot low priority job queue"
  value       = aws_batch_job_queue.fargate_low_priority.arn
}

output "fargate_compute_environment_arn" {
  description = "ARN of the Fargate compute environment"
  value       = aws_batch_compute_environment.fargate.arn
}

output "fargate_spot_compute_environment_arn" {
  description = "ARN of the Fargate Spot compute environment"
  value       = aws_batch_compute_environment.fargate_spot.arn
}
