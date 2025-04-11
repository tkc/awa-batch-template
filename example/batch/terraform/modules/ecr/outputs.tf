output "repository_url" {
  description = "ECRリポジトリのURL"
  value       = aws_ecr_repository.repository.repository_url
}

output "repository_arn" {
  description = "ECRリポジトリのARN"
  value       = aws_ecr_repository.repository.arn
}

output "repository_name" {
  description = "ECRリポジトリの名前"
  value       = aws_ecr_repository.repository.name
}

output "repository_registry_id" {
  description = "ECRリポジトリのレジストリID"
  value       = aws_ecr_repository.repository.registry_id
}
