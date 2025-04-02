# AWS Batch ジョブ定義 - sample1
resource "aws_batch_job_definition" "sample1" {
  name                  = "${local.name_prefix}-sample1"
  type                  = "container"
  container_properties  = jsonencode({
    image   = var.container_image != null ? var.container_image : "${aws_ecr_repository.main.repository_url}:latest"
    vcpus   = 1
    memory  = 2048
    command = ["sample1", "--input-file", "Ref::input_file", "--output-to-s3", "Ref::output_to_s3"]
    jobRoleArn = aws_iam_role.batch_job_role.arn
    
    environment = [
      {
        name  = "S3_BUCKET"
        value = aws_s3_bucket.main.bucket
      },
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "SAMPLE1_INPUT_FILE"
        value = "Ref::input_file_env"
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