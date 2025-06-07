terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ローカルバックエンドはデフォルトなので明示的に指定不要
  # backend "local" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

# ネットワーク設定の状態をローカルファイルから参照
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../network/terraform.tfstate"
  }
}

# IAM設定の状態をローカルファイルから参照
data "terraform_remote_state" "iam" {
  backend = "local"
  config = {
    path = "../iam/terraform.tfstate"
  }
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Platform    = "Fargate"
  }
}

# 複数のFargateイメージ（resources_fargate_X、resources_fargate_Y など）を使用する場合の注意点:
# - IAM権限については、セキュリティ上は各イメージ用に個別のIAMロールを作成することが望ましい
# - 各イメージが同じ権限セットを必要とする場合は共通のIAMロールを使用することも可能
# - ただし、将来の拡張性と運用の明確さを考慮すると、イメージごとに別々のIAMロールを定義することを推奨
# - CloudWatchログは必ず別々に設定し、各イメージからのログを明確に分離する
# - 例: 
#   - イメージ固有のIAMロール: fargate_role_x, fargate_role_y
#   - イメージ固有のCloudWatchロググループ: /ecs/fargate-x, /ecs/fargate-y
# 
# このアプローチにより、セキュリティと運用の両面で柔軟性と透明性が向上します

module "resources_fargate" {
  source = "../../../modules/resources_fargate"

  aws_region                     = var.aws_region
  environment                    = var.environment
  project_name                   = var.project_name
  vpc_id                         = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids             = data.terraform_remote_state.network.outputs.private_subnet_ids
  batch_job_role_arn             = data.terraform_remote_state.iam.outputs.batch_job_role_arn
  ecr_repository_name            = var.ecr_repository_name
  container_image                = var.container_image
  batch_job_definition_name      = var.batch_job_definition_name
  batch_job_queue_name           = var.batch_job_queue_name
  batch_compute_environment_name = var.batch_compute_environment_name
  max_vcpus                      = var.max_vcpus
  fargate_vcpu                   = var.fargate_vcpu
  fargate_memory                 = var.fargate_memory
  common_env_var_value           = var.common_env_var_value
  common_tags                    = local.common_tags
  slack_webhook_url              = var.slack_webhook_url
}