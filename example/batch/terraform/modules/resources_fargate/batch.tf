###############################################################################
# AWS Batch リソース - コンピューティング環境、ジョブキュー、ジョブ定義
###############################################################################

locals {
  # Batchリソースの共通設定
  batch_config = {
    compute_env_name    = "${local.name_prefix}-fargate"
    job_queue_name      = "${local.name_prefix}-fargate"
    job_definition_name = "${local.name_prefix}-fargate-sample"
    log_stream_prefix   = "fargate-sample"
  }
  
  # タグ設定
  batch_compute_tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-fargate-compute-env"
  })
  
  batch_queue_tags = merge(local.common_tags, {
    JobQueue = "Fargate job queue"
  })
  
  batch_job_def_tags = merge(local.common_tags, {
    JobDefinition = "Fargate Standard batch job"
  })
}

#----------------------------------------------------------------------
# AWS Batch コンピューティング環境
#----------------------------------------------------------------------

# Fargate用のコンピューティング環境
resource "aws_batch_compute_environment" "fargate" {
  compute_environment_name = local.batch_config.compute_env_name
  
  compute_resources {
    max_vcpus = var.max_vcpus
    
    security_group_ids = [
      aws_security_group.batch_compute_environment.id
    ]
    
    subnets = var.private_subnet_ids
    type    = "FARGATE"
  }
  
  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
  state        = "ENABLED"
  tags         = local.batch_compute_tags
  
  lifecycle {
    create_before_destroy = true
  }
}

#----------------------------------------------------------------------
# AWS Batch ジョブキュー
#----------------------------------------------------------------------

# Fargateジョブキュー
resource "aws_batch_job_queue" "fargate_queue" {
  name                  = local.batch_config.job_queue_name
  state                 = "ENABLED"
  priority              = 100
  scheduling_policy_arn = var.scheduling_policy_arn
  
  compute_environment_order {
    order            = 0
    compute_environment = aws_batch_compute_environment.fargate.arn
  }
  
  tags       = local.batch_queue_tags
  depends_on = [aws_batch_compute_environment.fargate]
}

#----------------------------------------------------------------------
# AWS Batch ジョブ定義
#----------------------------------------------------------------------

# Fargate用ジョブ定義
resource "aws_batch_job_definition" "fargate_sample" {
  name                  = local.batch_config.job_definition_name
  type                  = "container"
  platform_capabilities = ["FARGATE"]
  propagate_tags        = true
  
  parameters = {
    "CONFIG" = "{}"
  }
  
  # コンテナプロパティの定義
  container_properties = jsonencode({
    image       = var.container_image
    jobRoleArn  = var.batch_job_role_arn
    executionRoleArn = aws_iam_role.ecs_execution_role.arn
    
    resourceRequirements = [
      {
        type  = "VCPU"
        value = tostring(var.fargate_vcpu)
      },
      {
        type  = "MEMORY"
        value = tostring(var.fargate_memory)
      }
    ]
    
    environment = concat(
      [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "CUSTOM_ENVIRONMENT_1"
          value = var.common_env_var_value
        },
        {
          name  = "CONFIG"
          value = "Ref::CONFIG"
        }
      ],
      var.additional_environment_variables
    )
    
    command = var.container_command
    
    # KMS暗号化されたCloudWatch Logsの設定
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.batch_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = local.batch_config.log_stream_prefix
      }
      secretOptions = var.container_log_secrets
    }
    
    networkConfiguration = {
      assignPublicIp = "DISABLED"
    }
    
    fargatePlatformConfiguration = {
      platformVersion = var.fargate_platform_version
    }
  })
  
  # リトライ戦略
  retry_strategy {
    attempts = var.retry_attempts
    
    dynamic "evaluate_on_exit" {
      for_each = var.retry_exit_conditions
      content {
        action           = evaluate_on_exit.value.action
        on_reason        = lookup(evaluate_on_exit.value, "on_reason", null)
        on_exit_code     = lookup(evaluate_on_exit.value, "on_exit_code", null)
        on_status_reason = lookup(evaluate_on_exit.value, "on_status_reason", null)
      }
    }
  }
  
  tags = local.batch_job_def_tags
}
