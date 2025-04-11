output "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs"
  value       = module.iam.batch_job_role_arn
}

output "batch_job_role_name" {
  description = "Name of the IAM role for batch jobs"
  value       = module.iam.batch_job_role_name
}
