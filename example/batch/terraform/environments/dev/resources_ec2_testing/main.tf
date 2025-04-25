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
  }
}

module "resources" {
  source = "../../../modules/resources_ec2"

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
  instance_types                 = var.instance_types
  max_vcpus                      = var.max_vcpus
  min_vcpus                      = var.min_vcpus
  desired_vcpus                  = var.desired_vcpus
  common_env_var_value           = var.common_env_var_value
  common_tags                    = local.common_tags
  slack_webhook_url              = var.slack_webhook_url
}
