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
# VPC情報の取得
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Compute環境用のセキュリティグループ
resource "aws_security_group" "batch_compute_environment" {
  name        = local.sg_config.name
  description = local.sg_config.description
  vpc_id      = var.vpc_id
  
  # S3へのHTTPS通信（VPCエンドポイント経由）
  # VPCエンドポイント経由でS3にアクセスするため、実際にはインターネットへの通信は不要
  # ただし、クロスリージョンS3アクセスの場合は必要
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow HTTPS within VPC (for VPC endpoints)"
  }
  
  # Google Drive APIへのHTTPS通信
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS to Google APIs"
  }
  
  # DNS解決のための通信（Route 53 Resolver）
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow DNS resolution via TCP"
  }
  
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow DNS resolution via UDP"
  }
  
  # 明示的なインバウンドルールなし（デフォルトで拒否）
  
  tags = local.sg_tags
  
  lifecycle {
    create_before_destroy = true
  }
}
