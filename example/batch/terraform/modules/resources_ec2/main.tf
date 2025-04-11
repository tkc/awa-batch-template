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
  name              = "/aws/batch/${local.name_prefix}-ec2"
  retention_in_days = 14

  tags = local.common_tags
}

#----------------------------------------------------------------------
# AWS Batch設定
#----------------------------------------------------------------------

# Compute環境用のセキュリティグループ
resource "aws_security_group" "batch_compute_environment" {
  name        = "${local.name_prefix}-batch-ec2-sg"
  description = "Security group for AWS Batch EC2 compute environment"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = local.common_tags
}

# AWS Batch terraform モジュールの利用
module "batch" {
  source = "terraform-aws-modules/batch/aws"
  version = "2.1.0"

  instance_iam_role_name        = "${local.name_prefix}-batch-instance-role"
  instance_iam_role_path        = "/"
  instance_iam_role_description = "IAM role for AWS Batch EC2 instances"
  instance_iam_role_tags        = local.common_tags
  instance_iam_role_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]

  service_iam_role_name        = "${local.name_prefix}-batch-service-role"
  service_iam_role_path        = "/"
  service_iam_role_description = "IAM role for AWS Batch service"
  service_iam_role_tags        = local.common_tags
  service_iam_role_additional_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
  ]

  # スポットフリートロール作成（スポットインスタンスを使用する場合）
  create_spot_fleet_iam_role      = true
  spot_fleet_iam_role_name        = "${local.name_prefix}-batch-spot-fleet-role"
  spot_fleet_iam_role_path        = "/"
  spot_fleet_iam_role_description = "IAM role for AWS Batch spot fleet"
  spot_fleet_iam_role_tags        = local.common_tags

  compute_environments = {
    on_demand = {
      name                  = "${local.name_prefix}-ec2-on-demand"
      type                  = "MANAGED"
      compute_environment_name_prefix = "${local.name_prefix}-ec2-"
      
      compute_resources = {
        type                = "EC2"
        allocation_strategy = "BEST_FIT_PROGRESSIVE"
        
        max_vcpus           = var.max_vcpus
        min_vcpus           = var.min_vcpus
        desired_vcpus       = var.desired_vcpus
        
        instance_types      = var.instance_types
        
        subnets             = var.private_subnet_ids
        
        security_group_ids  = [
          aws_security_group.batch_compute_environment.id
        ]
        
        # インスタンスに付けるタグ
        tags = {
          Name = "${local.name_prefix}-batch-ec2-instance"
          Type = "OnDemand"
        }
      }
    }
    
    # スポットインスタンス環境
    spot = {
      name                  = "${local.name_prefix}-ec2-spot"
      type                  = "MANAGED"
      compute_environment_name_prefix = "${local.name_prefix}-ec2-"
      
      compute_resources = {
        type                = "SPOT"
        allocation_strategy = "SPOT_CAPACITY_OPTIMIZED"
        bid_percentage      = 60
        
        max_vcpus           = var.max_vcpus
        min_vcpus           = 0
        desired_vcpus       = 0
        
        instance_types      = var.instance_types
        
        subnets             = var.private_subnet_ids
        
        security_group_ids  = [
          aws_security_group.batch_compute_environment.id
        ]
        
        # インスタンスに付けるタグ
        tags = {
          Name = "${local.name_prefix}-batch-ec2-spot-instance"
          Type = "Spot"
        }
      }
    }
  }

  job_queues = {
    # 高優先度キュー（オンデマンド環境を使用）
    high_priority = {
      name     = "${local.name_prefix}-ec2-high-priority"
      state    = "ENABLED"
      priority = 100
      scheduling_policy_arn = null  # ファーストインファーストアウト（FIFO）スケジューリング
      
      compute_environment_order = [
        {
          order               = 0
          compute_environment = "on_demand"
        }
      ]
      
      tags = {
        JobQueue = "EC2 High priority job queue"
      }
    },
    
    # 低優先度キュー（スポット環境を使用）
    low_priority = {
      name     = "${local.name_prefix}-ec2-low-priority"
      state    = "ENABLED"
      priority = 10
      scheduling_policy_arn = null  # ファーストインファーストアウト（FIFO）スケジューリング
      
      compute_environment_order = [
        {
          order               = 0
          compute_environment = "spot"
        }
      ]
      
      tags = {
        JobQueue = "EC2 Low priority job queue"
      }
    }
  }

  tags = local.common_tags
}

#----------------------------------------------------------------------
# AWS Batch Job Definitions
#----------------------------------------------------------------------

# ジョブ定義
resource "aws_batch_job_definition" "sample1" {
  name                  = "${local.name_prefix}-ec2-sample1"
  type                  = "container"
  propagate_tags        = true
  platform_capabilities = ["EC2"]

  container_properties = jsonencode({
    image = var.container_image
    vcpus = 1
    memory = 2048
    command = []
    jobRoleArn = var.batch_job_role_arn

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

    mountPoints = []
    volumes = []

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group" = aws_cloudwatch_log_group.batch_logs.name
        "awslogs-region" = var.aws_region
        "awslogs-stream-prefix" = "sample1"
      }
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
      JobDefinition = "EC2 Standard batch job"
    }
  )
}
