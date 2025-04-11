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
# VPCとネットワーク設定
#----------------------------------------------------------------------

# VPCの作成
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-vpc"
    }
  )
}

# インターネットゲートウェイの作成とVPCへのアタッチ
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-igw"
    }
  )
}

# パブリックサブネットの作成
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = element(var.availability_zones, count.index % length(var.availability_zones)) # AZを順番に割り当て
  map_public_ip_on_launch = true # パブリックIPを自動割り当て

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-public-subnet-${count.index + 1}"
    }
  )
}

# プライベートサブネットの作成
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = element(var.availability_zones, count.index % length(var.availability_zones)) # AZを順番に割り当て

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-private-subnet-${count.index + 1}"
    }
  )
}

# Elastic IP for NAT Gateway (パブリックサブネットと同じ数だけ作成)
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks) # 通常は1つだが、冗長構成も考慮
  domain = "vpc" # Newer AWS accounts require 'domain' argument

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-nat-eip-${count.index + 1}"
    }
  )
}

# NATゲートウェイの作成 (パブリックサブネットに配置)
resource "aws_nat_gateway" "nat" {
  count         = length(var.public_subnet_cidr_blocks)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-nat-gw-${count.index + 1}"
    }
  )

  # Ensure Internet Gateway is created before NAT Gateway
  depends_on = [aws_internet_gateway.gw]
}

# パブリックルートテーブルの作成
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-public-rtb"
    }
  )
}

# パブリックサブネットとパブリックルートテーブルの関連付け
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# プライベートルートテーブルの作成 (AZごとに作成)
resource "aws_route_table" "private" {
  count  = length(var.availability_zones) # AZごとにルートテーブルを作成
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    # 対応するAZのNATゲートウェイにルーティング
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, count.index % length(aws_nat_gateway.nat.*.id))
  }

  tags = merge(
    local.common_tags,
    {
      # AZ名を含めて一意にする
      "Name" = "${local.name_prefix}-private-rtb-${element(var.availability_zones, count.index)}"
    }
  )
}

# プライベートサブネットとプライベートルートテーブルの関連付け
# 各プライベートサブネットを、それが属するAZに対応するルートテーブルに関連付ける
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  # element(var.availability_zones, count.index % length(var.availability_zones)) でサブネットのAZを取得
  # index(var.availability_zones, ...) でそのAZが var.availability_zones の何番目かを取得
  # そのインデックスを使って対応するルートテーブルを選択
  route_table_id = aws_route_table.private[index(var.availability_zones, element(var.availability_zones, count.index % length(var.availability_zones)))].id
  subnet_id      = aws_subnet.private[count.index].id
}

#----------------------------------------------------------------------
# VPCエンドポイント
#----------------------------------------------------------------------

# VPCエンドポイント用のセキュリティグループ
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

# VPCエンドポイントモジュール
module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.1.2"

  vpc_id             = aws_vpc.main.id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([aws_route_table.private.*.id, aws_route_table.public.*.id])
      tags            = { Name = "${local.name_prefix}-s3-endpoint" }
    },
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      subnet_ids          = aws_subnet.private.*.id
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      private_dns_enabled = true
      tags                = { Name = "${local.name_prefix}-ecr-api-endpoint" }
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      subnet_ids          = aws_subnet.private.*.id
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      private_dns_enabled = true
      tags                = { Name = "${local.name_prefix}-ecr-dkr-endpoint" }
    },
    logs = {
      service             = "logs"
      service_type        = "Interface"
      subnet_ids          = aws_subnet.private.*.id
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      private_dns_enabled = true
      tags                = { Name = "${local.name_prefix}-logs-endpoint" }
    },
    ecs = {
      service             = "ecs"
      service_type        = "Interface"
      subnet_ids          = aws_subnet.private.*.id
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      private_dns_enabled = true
      tags                = { Name = "${local.name_prefix}-ecs-endpoint" }
    },
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      subnet_ids          = aws_subnet.private.*.id
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      private_dns_enabled = true
      tags                = { Name = "${local.name_prefix}-ssm-endpoint" }
    }
  }

  tags = local.common_tags
}
