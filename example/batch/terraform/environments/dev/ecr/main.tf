provider "aws" {
  region = var.aws_region
}

locals {
  # リソース名のプレフィックス
  name_prefix = "${var.project_name}-${var.environment}"
  
  # すべてのリソースに適用する共通タグ
  common_tags = {
    "Project"     = var.project_name
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
  }

  # イメージの保持ポリシー (30日以上経過したイメージを10個のみ残す)
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire images older than 30 days while keeping at least 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Batchジョブ用のECRリポジトリ
module "ecr_batch" {
  source = "../../../modules/ecr"

  repository_name      = "${local.name_prefix}-batch"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  encryption_type      = "AES256"
  lifecycle_policy     = local.lifecycle_policy
  
  tags = local.common_tags
}
