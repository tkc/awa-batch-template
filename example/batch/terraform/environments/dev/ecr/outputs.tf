output "repository_url" {
  description = "ECRリポジトリのURL"
  value       = module.ecr_batch.repository_url
}

output "repository_arn" {
  description = "ECRリポジトリのARN"
  value       = module.ecr_batch.repository_arn
}

output "repository_name" {
  description = "ECRリポジトリの名前"
  value       = module.ecr_batch.repository_name
}

output "repository_registry_id" {
  description = "ECRリポジトリのレジストリID"
  value       = module.ecr_batch.repository_registry_id
}
