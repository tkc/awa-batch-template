output "batch_security_group_id" {
  description = "ID of the security group for AWS Batch Fargate compute environment"
  value       = module.resources_fargate.batch_security_group_id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Logs group for Fargate batch jobs"
  value       = module.resources_fargate.cloudwatch_log_group_name
}

output "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs"
  value       = module.resources_fargate.batch_job_role_arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role for Fargate tasks"
  value       = module.resources_fargate.ecs_execution_role_arn
}

output "batch_service_role_arn" {
  description = "ARN of the AWS Batch service role"
  value       = module.resources_fargate.batch_service_role_arn
}

output "sample_job_definition_arn" {
  description = "ARN of the sample Fargate batch job definition"
  value       = module.resources_fargate.sample_job_definition_arn
}

output "high_priority_job_queue_arn" {
  description = "ARN of the Fargate high priority job queue"
  value       = module.resources_fargate.high_priority_job_queue_arn
}

output "low_priority_job_queue_arn" {
  description = "ARN of the Fargate spot low priority job queue"
  value       = module.resources_fargate.low_priority_job_queue_arn
}

output "fargate_compute_environment_arn" {
  description = "ARN of the Fargate compute environment"
  value       = module.resources_fargate.fargate_compute_environment_arn
}

output "fargate_spot_compute_environment_arn" {
  description = "ARN of the Fargate Spot compute environment"
  value       = module.resources_fargate.fargate_spot_compute_environment_arn
}
