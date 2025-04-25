#----------------------------------------------------------------------
# AWS Batch Job Failure Notification Setup for EC2 environment
#----------------------------------------------------------------------

# Create SNS Topic (notification destination)
resource "aws_sns_topic" "batch_job_failure" {
  name = "${local.name_prefix}-batch-job-failure"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-batch-job-failure"
      Description = "SNS Topic for AWS Batch job failure notifications"
    }
  )
}

# Create IAM Role for Lambda function
resource "aws_iam_role" "lambda_slack_role" {
  name = "${local.name_prefix}-lambda-slack-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach Lambda basic execution policy (includes CloudWatch Logs write permissions)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_slack_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create CloudWatch Logs group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.name_prefix}-slack-notifier"
  retention_in_days = 14
  
  tags = local.common_tags
}

# Create Lambda function for Slack notifications
resource "aws_lambda_function" "slack_notifier" {
  function_name    = "${local.name_prefix}-slack-notifier"
  role             = aws_iam_role.lambda_slack_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.9"
  timeout          = 10
  memory_size      = 128
  
  # Using file instead of inline code
  filename         = "${path.module}/lambda_function_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function_payload.zip")
  
  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url # Get Webhook URL from variable
    }
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-slack-notifier"
      Description = "Lambda function to send Slack notifications on AWS Batch job failures"
    }
  )
  
  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}

# Set permission for SNS to invoke Lambda function
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.batch_job_failure.arn
}

# Set up SNS to Lambda subscription
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.batch_job_failure.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier.arn
}

# CloudWatch Metric Filter creation (for batch job failure detection)
resource "aws_cloudwatch_log_metric_filter" "batch_job_failure" {
  name           = "${local.name_prefix}-batch-job-failure-filter"
  pattern        = "?ERROR ?Error ?error ?Exception ?exception ?failed ?Failed"
  log_group_name = aws_cloudwatch_log_group.batch_logs.name
  
  metric_transformation {
    name      = "BatchJobFailureCount"
    namespace = "CustomBatch"
    value     = "1"
  }
}

# CloudWatch Alarm creation (based on the metric filter)
resource "aws_cloudwatch_metric_alarm" "batch_job_failure" {
  alarm_name          = "${local.name_prefix}-batch-job-failure-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "BatchJobFailureCount"
  namespace           = "CustomBatch"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Sends notification when AWS Batch jobs fail"
  alarm_actions       = [aws_sns_topic.batch_job_failure.arn]
  
  dimensions = {}
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-batch-job-failure-alarm"
      Description = "AWS Batch job failure alert"
    }
  )
}
