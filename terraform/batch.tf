# AWS Batch サービスロール
resource "aws_iam_role" "batch_service_role" {
  name = "${local.name_prefix}-batch-service-role"
  
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
}

resource "aws_iam_role_policy_attachment" "batch_service_role" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# EC2インスタンスプロファイルロール
resource "aws_iam_role" "batch_instance_role" {
  name = "${local.name_prefix}-batch-instance-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "batch_instance_role_ecr" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECR-FullAccess"
}

resource "aws_iam_role_policy_attachment" "batch_instance_role_s3" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "batch_instance_role_ssm" {
  role       = aws_iam_role.batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "batch_instance_role" {
  name = "${local.name_prefix}-batch-instance-profile"
  role = aws_iam_role.batch_instance_role.name
}

# AWS Batch ジョブ実行ロール
resource "aws_iam_role" "batch_job_role" {
  name = "${local.name_prefix}-batch-job-role"
  
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
}

resource "aws_iam_role_policy_attachment" "batch_job_role_s3" {
  role       = aws_iam_role.batch_job_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# AWS Batch コンピュート環境
resource "aws_batch_compute_environment" "batch_compute_env" {
  compute_environment_name = "${local.name_prefix}-${var.batch_compute_environment_name}"
  
  compute_resources {
    type                = "EC2"
    allocation_strategy = var.use_spot_instances ? "SPOT_CAPACITY_OPTIMIZED" : "BEST_FIT"
    
    max_vcpus     = var.max_vcpus
    min_vcpus     = var.min_vcpus
    desired_vcpus = var.desired_vcpus
    
    instance_role = aws_iam_instance_profile.batch_instance_role.arn
    
    instance_type = var.instance_types
    
    subnets = aws_subnet.private[*].id
    
    security_group_ids = [
      aws_security_group.batch_compute_env.id
    ]
    
    tags = local.common_tags
    
    dynamic "spot_iam_fleet_role" {
      for_each = var.use_spot_instances ? [1] : []
      content {
        arn = aws_iam_role.spot_fleet_role[0].arn
      }
    }
  }
  
  service_role = aws_iam_role.batch_service_role.arn
  type         = "MANAGED"
  depends_on   = [aws_vpc.main]
  
  tags = local.common_tags
}

# スポットフリートロール（スポットインスタンス使用時のみ）
resource "aws_iam_role" "spot_fleet_role" {
  count = var.use_spot_instances ? 1 : 0
  name  = "${local.name_prefix}-spot-fleet-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "spotfleet.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "spot_fleet_role" {
  count      = var.use_spot_instances ? 1 : 0
  role       = aws_iam_role.spot_fleet_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

# バッチ環境のセキュリティグループ
resource "aws_security_group" "batch_compute_env" {
  name        = "${local.name_prefix}-batch-sg"
  description = "Security group for AWS Batch compute environment"
  vpc_id      = aws_vpc.main.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-batch-sg"
    }
  )
}

# AWS Batch ジョブキュー
resource "aws_batch_job_queue" "main" {
  name                 = "${local.name_prefix}-${var.batch_job_queue_name}"
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.batch_compute_env.arn]
  
  tags = local.common_tags
}

# AWS Batch ジョブ定義 - sample1
resource "aws_batch_job_definition" "sample1" {
  name                  = "${local.name_prefix}-sample1"
  type                  = "container"
  container_properties  = jsonencode({
    image   = var.container_image != null ? var.container_image : "${aws_ecr_repository.main.repository_url}:latest"
    vcpus   = 1
    memory  = 2048
    command = ["sample1", "--param1", "Ref::param1", "--param2", "Ref::param2"]
    jobRoleArn = aws_iam_role.batch_job_role.arn
    
    environment = [
      {
        name  = "S3_BUCKET"
        value = aws_s3_bucket.main.bucket
      },
      {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    ]
    
    mountPoints = []
    volumes     = []
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/batch/job"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "sample1"
      }
    }
  })
  
  tags = local.common_tags
  
  depends_on = [aws_ecr_repository.main, aws_s3_bucket.main]
}

# AWS Batch ジョブ定義 - sample2
resource "aws_batch_job_definition" "sample2" {
  name                  = "${local.name_prefix}-sample2"
  type                  = "container"
  container_properties  = jsonencode({
    image   = var.container_image != null ? var.container_image : "${aws_ecr_repository.main.repository_url}:latest"
    vcpus   = 1
    memory  = 2048
    command = ["sample2", "--input-key", "Ref::input_key", "--param", "Ref::param"]
    jobRoleArn = aws_iam_role.batch_job_role.arn
    
    environment = [
      {
        name  = "S3_BUCKET"
        value = aws_s3_bucket.main.bucket
      },
      {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    ]
    
    mountPoints = []
    volumes     = []
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/batch/job"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "sample2"
      }
    }
  })
  
  tags = local.common_tags
  
  depends_on = [aws_ecr_repository.main, aws_s3_bucket.main]
}

# AWS Batch ジョブ定義 - sample3
resource "aws_batch_job_definition" "sample3" {
  name                  = "${local.name_prefix}-sample3"
  type                  = "container"
  container_properties  = jsonencode({
    image   = var.container_image != null ? var.container_image : "${aws_ecr_repository.main.repository_url}:latest"
    vcpus   = 2  # より多くのリソースを割り当て
    memory  = 4096
    command = ["sample3", "--input-prefix", "Ref::input_prefix", "--filter", "Ref::filter"]
    jobRoleArn = aws_iam_role.batch_job_role.arn
    
    environment = [
      {
        name  = "S3_BUCKET"
        value = aws_s3_bucket.main.bucket
      },
      {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    ]
    
    mountPoints = []
    volumes     = []
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/aws/batch/job"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "sample3"
      }
    }
  })
  
  tags = local.common_tags
  
  depends_on = [aws_ecr_repository.main, aws_s3_bucket.main]
}
