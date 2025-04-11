output "batch_job_role_arn" {
  description = "ARN of the IAM role for batch jobs"
  value       = aws_iam_role.batch_job_role.arn
}

output "batch_job_role_name" {
  description = "Name of the IAM role for batch jobs"
  value       = aws_iam_role.batch_job_role.name
}
