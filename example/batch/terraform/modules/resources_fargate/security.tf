###############################################################################
# セキュリティグループ設定
###############################################################################

locals {
  # セキュリティグループの共通設定
  sg_config = {
    name        = "${local.name_prefix}-batch-fargate-sg"
    description = "Security group for AWS Batch Fargate compute environment"
  }
  
  # セキュリティグループのタグ
  sg_tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-batch-fargate-sg"
    Service = "AWS Batch"
    Type    = "Security Group"
  })
}

# Compute環境用のセキュリティグループ
resource "aws_security_group" "batch_compute_environment" {
  name        = local.sg_config.name
  description = local.sg_config.description
  vpc_id      = var.vpc_id
  
  # 外部への接続のみ許可（コンテナからの送信トラフィック）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  # 明示的なインバウンドルールなし（デフォルトで拒否）
  
  tags = local.sg_tags
  
  lifecycle {
    create_before_destroy = true
  }
}
