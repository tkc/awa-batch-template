# ローカル変数
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Batch環境の名前
  batch_compute_environment_name = "${local.name_prefix}-${var.batch_compute_environment_name}"
  batch_job_queue_name = "${local.name_prefix}-${var.batch_job_queue_name}"
  
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
  retention_in_days = 14

  tags = local.common_tags
}

#----------------------------------------------------------------------
# AWS Batch設定
#----------------------------------------------------------------------

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
  }
  
  tags = local.common_tags
}

# Fargate用のECS実行ロール
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.name_prefix}-batch-fargate-execution-role"

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

# CloudWatch Logsアクセス用ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_execution_role_logs" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# AWS Batch サービスロール
resource "aws_iam_role" "batch_service_role" {
  name = "${local.name_prefix}-batch-fargate-service-role"

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

# BatchサービスロールにAWSBatchServiceRoleポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# BatchサービスロールにECS権限をインラインポリシーで追加
resource "aws_iam_role_policy" "batch_service_ecs_permissions" {
  name = "ECSManagementPermissions"
  role = aws_iam_role.batch_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:*"  # より広範なECS権限を付与
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Fargate用のコンピューティング環境
resource "aws_batch_compute_environment" "fargate" {
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
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-fargate-compute-env"
    }
  )
}

# Fargate Spotのコンピューティング環境
resource "aws_batch_compute_environment" "fargate_spot" {
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
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-fargate-spot-compute-env"
    }
  )
}

# ジョブキュー（通常のFargate、高優先度）
resource "aws_batch_job_queue" "fargate_high_priority" {
  name     = "${local.name_prefix}-fargate-high-priority"
  state    = "ENABLED"
  priority = 100

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
}

# ジョブキュー（Fargate Spot、低優先度）
resource "aws_batch_job_queue" "fargate_low_priority" {
  name     = "${local.name_prefix}-fargate-low-priority"
  state    = "ENABLED"
  priority = 10

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

    # 通常の方法ではvCPUとメモリを設定できない
    # vcpus と memory プロパティはFargateでは使用できません
    
    environment = [
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "key"
        value = var.common_env_var_value
      }
    ]

    command = []
    mountPoints = []
    volumes = []
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.batch_logs.name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "fargate-sample"
      }
    }
    
    # Fargate用に必要な追加設定
    networkConfiguration = {
      assignPublicIp = "DISABLED"
    }
    
    fargatePlatformConfiguration = {
      platformVersion = "LATEST"
    }
  })

  # リトライ戦略 - 最大3回まで試行
  retry_strategy {
    attempts = 3
    
    evaluate_on_exit {
      action       = "RETRY"
      on_reason    = "*"
      on_exit_code = 1
    }
    
    evaluate_on_exit {
      action       = "EXIT"
      on_exit_code = 0
    }
  }

  tags = merge(
    local.common_tags,
    {
      JobDefinition = "Fargate Standard batch job"
    }
  )
}
