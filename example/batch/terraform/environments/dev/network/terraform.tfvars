aws_region   = "ap-northeast-1"
environment  = "dev"
project_name = "awa-batch"

# VPC設定
vpc_cidr_block             = "10.0.0.0/16"
availability_zones         = ["ap-northeast-1a", "ap-northeast-1c"]
public_subnet_cidr_blocks  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidr_blocks = ["10.0.11.0/24", "10.0.12.0/24"]
