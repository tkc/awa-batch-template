output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.main.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket
}

output "batch_job_queue_arn" {
  description = "ARN of the Batch job queue"
  value       = aws_batch_job_queue.main.arn
}

output "batch_job_queue_name" {
  description = "Name of the Batch job queue"
  value       = aws_batch_job_queue.main.name
}

output "batch_job_definition_sample1_arn" {
  description = "ARN of the sample1 Batch job definition"
  value       = aws_batch_job_definition.sample1.arn
}

output "batch_job_definition_sample1_name" {
  description = "Name of the sample1 Batch job definition"
  value       = aws_batch_job_definition.sample1.name
}

output "batch_job_definition_sample2_arn" {
  description = "ARN of the sample2 Batch job definition"
  value       = aws_batch_job_definition.sample2.arn
}

output "batch_job_definition_sample2_name" {
  description = "Name of the sample2 Batch job definition"
  value       = aws_batch_job_definition.sample2.name
}

output "batch_job_definition_sample3_arn" {
  description = "ARN of the sample3 Batch job definition"
  value       = aws_batch_job_definition.sample3.arn
}

output "batch_job_definition_sample3_name" {
  description = "Name of the sample3 Batch job definition"
  value       = aws_batch_job_definition.sample3.name
}

output "batch_compute_environment_arn" {
  description = "ARN of the Batch compute environment"
  value       = aws_batch_compute_environment.batch_compute_env.arn
}

output "batch_job_role_arn" {
  description = "ARN of the Batch job role"
  value       = aws_iam_role.batch_job_role.arn
}