# ローカル変数
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # すべてのリソースに適用する共通タグ
  common_tags = merge(
    var.common_tags,
    {
      "Project"     = var.project_name
      "Environment" = var.environment
      "ManagedBy"   = "terraform"
    }
  )
}

#----------------------------------------------------------------------
# CloudWatch Logs
#----------------------------------------------------------------------

# CloudWatch Logsグループ
resource "aws_cloudwatch_log_group" "batch_logs" {
  name              = "/aws/batch/${local.name_prefix}-fargate"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn # 暗号化のために追加

  tags = local.common_tags
}

# AWS アカウント情報の取得
data "aws_caller_identity" "current" {}

#----------------------------------------------------------------------
# AWS Batch設定（モジュール利用）
#----------------------------------------------------------------------

# AWS Batch terraform モジュールを使用せず、直接リソースを作成します

# AWS Batch serviceロール
resource "aws_iam_role" "batch_service_role" {
  name = "${local.name_prefix}-batch-service-role"
  description = "Allows AWS Batch to manage resources on your behalf"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# BatchIAMロールにポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# Fargate用のコンピューティング環境
resource "aws_batch_compute_environment" "fargate" {
  # 固定名を使用してランダムな接尾辞を避ける
  compute_environment_name = "${local.name_prefix}-fargate"

  compute_resources {
    max_vcpus = var.max_vcpus

    security_group_ids = [
      aws_security_group.batch_compute_environment.id
    ]

    subnets = var.private_subnet_ids

    type = "FARGATE"
  }

  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
  state        = "ENABLED"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-fargate-compute-env"
    }
  )

  # 重複作成を避けるためにライフサイクル設定
  lifecycle {
    create_before_destroy = true
  }
}

# Fargate Spotのコンピューティング環境
resource "aws_batch_compute_environment" "fargate_spot" {
  # 固定名を使用してランダムな接尾辞を避ける
  compute_environment_name = "${local.name_prefix}-fargate-spot"

  compute_resources {
    max_vcpus = var.max_vcpus

    security_group_ids = [
      aws_security_group.batch_compute_environment.id
    ]

    subnets = var.private_subnet_ids

    type = "FARGATE_SPOT"
  }

  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
  state        = "ENABLED"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-fargate-spot-compute-env"
    }
  )

  # 重複作成を避けるためにライフサイクル設定
  lifecycle {
    create_before_destroy = true
  }
}

# ジョブキュー（通常のFargate、高優先度）
resource "aws_batch_job_queue" "fargate_high_priority" {
  name     = "${local.name_prefix}-fargate-high-priority"
  state    = "ENABLED"
  priority = 100
  scheduling_policy_arn = var.scheduling_policy_arn

  compute_environment_order {
    order            = 0
    compute_environment = aws_batch_compute_environment.fargate.arn
  }
  
  tags = merge(
    local.common_tags,
    {
      JobQueue = "Fargate High priority job queue"
    }
  )

  depends_on = [aws_batch_compute_environment.fargate]
}

# ジョブキュー（Fargate Spot、低優先度）
resource "aws_batch_job_queue" "fargate_low_priority" {
  name     = "${local.name_prefix}-fargate-low-priority"
  state    = "ENABLED"
  priority = 10
  scheduling_policy_arn = var.scheduling_policy_arn

  compute_environment_order {
    order            = 0
    compute_environment = aws_batch_compute_environment.fargate_spot.arn
  }
  
  tags = merge(
    local.common_tags,
    {
      JobQueue = "Fargate Spot Low priority job queue"
    }
  )

  depends_on = [aws_batch_compute_environment.fargate_spot]
}

#----------------------------------------------------------------------
# AWS Batch Job Definitions
#----------------------------------------------------------------------

# Fargate用ジョブ定義
resource "aws_batch_job_definition" "fargate_sample" {
  name                  = "${local.name_prefix}-fargate-sample"
  type                  = "container"
  platform_capabilities = ["FARGATE"]
  propagate_tags        = true

  # パラメータのデフォルト値を追加
  parameters = {
    "CONFIG" = "{}"  # デフォルト値を空のJSONにする
  }

  container_properties = jsonencode({
    image       = var.container_image
    jobRoleArn  = var.batch_job_role_arn
    executionRoleArn = aws_iam_role.ecs_execution_role.arn
    
    # Fargateでは、resourceRequirementsを使用する必要があります
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
          name  = "CONFIG"
          value = "Ref::CONFIG"  # パラメータ参照を追加
        }
      ],
      var.additional_environment_variables
    )

    command = var.container_command
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.batch_logs.name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "fargate-sample"
      }
      secretOptions = var.container_log_secrets
    }
    
    # Fargate用に必要な設定
    networkConfiguration = {
      assignPublicIp = var.assign_public_ip ? "ENABLED" : "DISABLED"
    }
    
    fargatePlatformConfiguration = {
      platformVersion = var.fargate_platform_version
    }
  })

  # リトライ戦略 - 最大3回まで試行
  retry_strategy {
    attempts = var.retry_attempts
    
    dynamic "evaluate_on_exit" {
      for_each = var.retry_exit_conditions
      content {
        action       = evaluate_on_exit.value.action
        on_reason    = lookup(evaluate_on_exit.value, "on_reason", null)
        on_exit_code = lookup(evaluate_on_exit.value, "on_exit_code", null)
        on_status_reason = lookup(evaluate_on_exit.value, "on_status_reason", null)
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      JobDefinition = "Fargate Standard batch job"
    }
  )
}

# Compute環境用のセキュリティグループ
resource "aws_security_group" "batch_compute_environment" {
  name        = "${local.name_prefix}-batch-fargate-sg"
  description = "Security group for AWS Batch Fargate compute environment"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-batch-fargate-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Fargate用のECS実行ロール
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.name_prefix}-fargate-execution-role"
  description = "Allows Fargate tasks to call AWS services on your behalf"
  path = "/service-role/"

  # 重要: ECSタスクがこのロールを引き受けられるように設定
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# ECS実行ロールにポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch Logsアクセス用ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_execution_role_logs" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# ECRアクセス用のインラインポリシーを作成
resource "aws_iam_role_policy" "ecs_execution_role_ecr" {
  name = "ECRAccessPolicy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
