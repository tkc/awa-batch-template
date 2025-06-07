#------------------------------------------------------------------------------
# ローカル変数定義
# プロジェクト全体で使用する共通の値を定義します。
# これにより、命名規則の一貫性とタグ管理の簡素化を実現します。
#------------------------------------------------------------------------------
locals {
  # リソース名のプレフィックス
  # 例: "awa-batch-dev" のような形式で、環境ごとにリソースを識別できます
  name_prefix = "${var.project_name}-${var.environment}"
  
  # すべてのリソースに適用する共通タグ
  # コスト管理、リソースの追跡、自動化の際に重要な役割を果たします
  common_tags = merge(
    var.common_tags,  # 外部から渡される追加のタグ
    {
      "Project"     = var.project_name  # プロジェクト名（例: awa-batch）
      "Environment" = var.environment   # 環境名（例: dev, staging, prod）
      "ManagedBy"   = "terraform"       # インフラ管理ツール（手動変更を防ぐ指標）
    }
  )
}

#------------------------------------------------------------------------------
# VPCとネットワーク設定
# AWS Batchのコンピューティング環境が動作するための基本的なネットワーク基盤を構築します。
# このセクションでは、VPC、サブネット、ルーティングなどを設定します。
#------------------------------------------------------------------------------

# Virtual Private Cloud (VPC) の作成
# VPCは、AWS内に作成される仮想ネットワークで、他のAWSアカウントから論理的に分離されています。
# これにより、セキュアなネットワーク環境でバッチジョブを実行できます。
resource "aws_vpc" "main" {
  # VPCのIPアドレス範囲（CIDR表記）
  # 例: "10.0.0.0/16" = 10.0.0.0 〜 10.0.255.255 (65,536個のIPアドレス)
  cidr_block           = var.vpc_cidr_block
  
  # DNSサポートを有効化（AWSが提供するDNSサーバーを使用）
  # これにより、VPC内のリソースがDNS名前解決を行えます
  enable_dns_support   = true
  
  # DNSホスト名を有効化（EC2インスタンスにパブリックDNS名を割り当て）
  # 例: ec2-192-168-1-1.ap-northeast-1.compute.amazonaws.com
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-vpc"
    }
  )
}

# インターネットゲートウェイ (IGW) の作成
# IGWは、VPCとインターネット間の通信を可能にするゲートウェイです。
# パブリックサブネット内のリソースがインターネットと通信するために必要です。
# 注意: IGW自体に料金はかかりませんが、データ転送には料金が発生します。
resource "aws_internet_gateway" "gw" {
  # このIGWを接続するVPCのID
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-igw"
    }
  )
}

# パブリックサブネットの作成
# パブリックサブネットは、インターネットゲートウェイへのルートを持つサブネットです。
# 主な用途:
# - NAT Gatewayの配置
# - ロードバランサーの配置
# - パブリックIPが必要なリソースの配置
resource "aws_subnet" "public" {
  # var.public_subnet_cidr_blocksの要素数だけサブネットを作成
  # 例: ["10.0.1.0/24", "10.0.2.0/24"] なら2つのサブネットを作成
  count                   = length(var.public_subnet_cidr_blocks)
  
  # サブネットを作成するVPC
  vpc_id                  = aws_vpc.main.id
  
  # 各サブネットのIPアドレス範囲
  # count.indexを使って配列から順番に取得
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  
  # アベイラビリティゾーン（AZ）の割り当て
  # 複数のAZに分散配置することで高可用性を実現
  # element関数とモジュロ演算で、AZを循環的に割り当て
  availability_zone       = element(var.availability_zones, count.index % length(var.availability_zones))
  
  # 起動時の自動パブリックIP割り当てを無効化
  # false = より安全（NAT GatewayはElastic IPを個別に割り当て）
  # true = このサブネットで起動したインスタンスに自動的にパブリックIPを付与
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-public-subnet-${count.index + 1}"
    }
  )
}

# プライベートサブネットの作成
# プライベートサブネットは、インターネットから直接アクセスできないサブネットです。
# インターネットへの通信はNAT Gateway経由で行います。
# 主な用途:
# - バッチジョブの実行環境（EC2/Fargate）
# - データベース
# - アプリケーションサーバー
# セキュリティ上、ほとんどのリソースはプライベートサブネットに配置すべきです。
resource "aws_subnet" "private" {
  # var.private_subnet_cidr_blocksの要素数だけサブネットを作成
  count             = length(var.private_subnet_cidr_blocks)
  
  # サブネットを作成するVPC
  vpc_id            = aws_vpc.main.id
  
  # 各サブネットのIPアドレス範囲
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  
  # アベイラビリティゾーンの割り当て（パブリックサブネットと同じロジック）
  # 同じAZにパブリックとプライベートのペアを作ることで、
  # 同一AZ内でNAT Gatewayへの通信が可能（レイテンシとコストの最適化）
  availability_zone = element(var.availability_zones, count.index % length(var.availability_zones))

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-private-subnet-${count.index + 1}"
    }
  )
}

#------------------------------------------------------------------------------
# NAT Gateway の設定
# NAT Gatewayは、プライベートサブネット内のリソースがインターネットへ
# アウトバウンド通信を行うために必要です（インバウンドは不可）。
# 主な用途:
# - ソフトウェアアップデート
# - 外部APIへのアクセス
# - S3やECRなどのAWSサービスへのアクセス（VPCエンドポイントがない場合）
# コスト: 約$45/月 + データ転送料金
#------------------------------------------------------------------------------

# Elastic IP (EIP) の作成
# NAT Gatewayには固定のパブリックIPアドレスが必要です。
# EIPは、インスタンスの停止・起動に関わらず同じIPアドレスを維持します。
# 注意: 未使用のEIPには料金が発生します（約$3.6/月）
resource "aws_eip" "nat" {
  # "vpc" = VPC内で使用するEIP（EC2-Classicは廃止済み）
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-nat-eip"
    }
  )
}

# NAT Gateway の作成
# AWS管理型のNATサービスで、高可用性と自動スケーリングを提供します。
# メリット:
# - メンテナンス不要（パッチ適用など）
# - 高可用性（同一AZ内で冗長化）
# - 最大45Gbpsの帯域幅
# デメリット:
# - コストが高い（約$45/月 + データ転送料金）
# 代替案: NAT Instance（EC2）を使用すると約$3.8/月に削減可能
resource "aws_nat_gateway" "nat" {
  # 先ほど作成したElastic IPを割り当て
  allocation_id = aws_eip.nat.id
  
  # NAT Gatewayを配置するパブリックサブネット
  # 最初のパブリックサブネット（[0]）を使用
  # 高可用性が必要な場合は、各AZにNAT Gatewayを作成
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-nat-gw"
    }
  )

  # 明示的な依存関係の定義
  # Internet GatewayがないとNAT Gatewayは機能しないため
  depends_on = [aws_internet_gateway.gw]
}

# パブリックルートテーブルの作成
# ルートテーブルは、サブネット内のトラフィックの送信先を決定します。
# パブリックサブネット用のルートテーブルには、インターネットへのルートが含まれます。
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # デフォルトルート（すべてのトラフィック）をInternet Gatewayへ
  route {
    # "0.0.0.0/0" = すべてのIPアドレス（インターネット全体）
    # VPC内の通信は、より具体的なルート（ローカルルート）が自動的に優先されます
    cidr_block = "0.0.0.0/0"
    
    # トラフィックの送信先：Internet Gateway
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-public-rtb"  # rtb = Route Table
    }
  )
}

# パブリックサブネットとパブリックルートテーブルの関連付け
# サブネットとルートテーブルを関連付けることで、
# そのサブネット内のリソースがルートテーブルのルールに従ってトラフィックを送信します。
# 関連付けがない場合、サブネットはVPCのメインルートテーブルを使用します。
resource "aws_route_table_association" "public" {
  # パブリックサブネットの数だけ関連付けを作成
  count          = length(aws_subnet.public)
  
  # 関連付けるサブネットのID
  subnet_id      = aws_subnet.public[count.index].id
  
  # 関連付けるルートテーブルのID
  route_table_id = aws_route_table.public.id
}

# プライベートルートテーブルの作成
# プライベートサブネット用のルートテーブルです。
# インターネットへの直接ルートは含まず、NAT Gateway経由でのみ外部通信可能です。
# これにより、外部からの直接アクセスを防ぎつつ、必要な外部通信を許可します。
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # ルートは別リソースで定義（aws_route）
  # これにより、NAT Gatewayの作成後にルートを追加できます

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-private-rtb"
    }
  )
}

# プライベートルートテーブルのデフォルトルート（NAT Gateway経由）
# プライベートサブネットからインターネットへのアウトバウンド通信を可能にします。
# 重要: これはアウトバウンドのみで、インターネットからの直接アクセスは不可能です。
resource "aws_route" "private_nat" {
  # ルートを追加するルートテーブル
  route_table_id         = aws_route_table.private.id
  
  # 宛先：すべてのインターネットアドレス
  destination_cidr_block = "0.0.0.0/0"
  
  # 経由地：NAT Gateway
  # これにより、プライベートサブネットのリソースは
  # NAT Gatewayを通じてインターネットにアクセスできます
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# プライベートサブネットとプライベートルートテーブルの関連付け
# 各プライベートサブネットに、NAT Gateway経由のルートを適用します。
resource "aws_route_table_association" "private" {
  # プライベートサブネットの数だけ関連付けを作成
  count          = length(aws_subnet.private)
  
  # 関連付けるルートテーブル（NAT Gatewayへのルートを含む）
  route_table_id = aws_route_table.private.id
  
  # 関連付けるサブネット
  subnet_id      = aws_subnet.private[count.index].id
}

#------------------------------------------------------------------------------
# セキュリティグループ
# セキュリティグループは、インスタンスレベルのファイアウォールとして機能します。
# インバウンド（受信）とアウトバウンド（送信）のトラフィックを制御します。
#------------------------------------------------------------------------------

# VPCデフォルトセキュリティグループのカスタマイズ
# すべてのVPCには自動的にデフォルトセキュリティグループが作成されます。
# デフォルトでは同じセキュリティグループ間の通信をすべて許可するため、
# セキュリティリスクとなる可能性があります。
# ベストプラクティス: デフォルトSGは使用せず、用途別のSGを作成する
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # ルールを一切定義しないことで、すべてのトラフィックを拒否
  # （インバウンド・アウトバウンドともに）
  # これにより、誤ってデフォルトSGを使用してもトラフィックは流れません

  tags = merge(
    local.common_tags,
    {
      # 名前に"do-not-use"を含めることで、使用すべきでないことを明示
      Name = "${local.name_prefix}-default-sg-do-not-use"
    }
  )
}



#------------------------------------------------------------------------------
# VPCフローログ
# VPCフローログは、VPC内のネットワークトラフィックをキャプチャして記録します。
# セキュリティ分析、トラブルシューティング、コンプライアンスに使用されます。
# 記録内容：送信元/宛先IP、ポート、プロトコル、パケット数、バイト数、
#          アクション（ACCEPT/REJECT）など
#------------------------------------------------------------------------------

# VPCフローログ用のCloudWatch Logsグループ
# フローログのデータを保存するための専用ロググループです。
# コスト考慮事項：
# - ログの保存にはストレージ料金が発生
# - データ取り込みにも料金が発生（約$0.50/GB）
resource "aws_cloudwatch_log_group" "flow_log" {
  # ロググループ名（AWS推奨の命名規則に従う）
  name              = "/aws/vpc/${local.name_prefix}"
  
  # ログの保持期間（日数）
  # 7日間 = コスト最適化（必要に応じて延長可能）
  # 無期限 = 0、その他の選択肢: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
  retention_in_days = 7

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-flow-log"
    }
  )
}

# VPCフローログ用のIAMロール
# VPCフローログサービスがCloudWatch Logsにログを書き込むために必要な権限を付与します。
# このロールがないと、フローログは動作しません。
resource "aws_iam_role" "flow_log" {
  name = "${local.name_prefix}-vpc-flow-log-role"

  # 信頼ポリシー（Assume Role Policy）
  # vpc-flow-logs.amazonaws.comサービスがこのロールを引き受けることを許可
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"  # ロールの引き受けを許可
        Effect = "Allow"
        Principal = {
          # VPCフローログサービスのみがこのロールを使用可能
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# VPCフローログ用のIAMポリシー
# フローログがCloudWatch Logsを操作するための具体的な権限を定義します。
resource "aws_iam_role_policy" "flow_log" {
  name = "${local.name_prefix}-vpc-flow-log-policy"
  role = aws_iam_role.flow_log.id

  # CloudWatch Logsへの書き込み権限
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",      # ロググループの作成
          "logs:CreateLogStream",     # ログストリームの作成
          "logs:PutLogEvents",        # ログイベントの書き込み
          "logs:DescribeLogGroups",   # ロググループの情報取得
          "logs:DescribeLogStreams"   # ログストリームの情報取得
        ]
        Effect = "Allow"
        # セキュリティのベストプラクティスとしては、
        # 特定のロググループARNに制限することが推奨されますが、
        # フローログの初期作成時には"*"が必要
        Resource = "*"
      }
    ]
  })
}

# VPCフローログの設定
# 実際にVPCのトラフィックログを有効化します。
resource "aws_flow_log" "main" {
  # フローログサービスが使用するIAMロール
  iam_role_arn    = aws_iam_role.flow_log.arn
  
  # ログの保存先（CloudWatch Logs）
  # 他の選択肢：S3バケット（より安価だが、リアルタイム分析が困難）
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  
  # 記録するトラフィックのタイプ
  # "ALL" = 許可されたトラフィックと拒否されたトラフィックの両方
  # "ACCEPT" = 許可されたトラフィックのみ
  # "REJECT" = 拒否されたトラフィックのみ（セキュリティ分析に有用）
  traffic_type    = "ALL"
  
  # フローログを有効化するVPC
  vpc_id          = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-flow-log"
    }
  )
}

#------------------------------------------------------------------------------
# VPCエンドポイント
# VPCエンドポイントを使用すると、インターネットゲートウェイ、NATデバイス、
# VPN接続、AWS Direct Connect接続を使用せずに、VPCとサポートされている
# AWSサービス間でプライベート接続を確立できます。
# メリット：
# - セキュリティ向上（トラフィックがインターネットを経由しない）
# - パフォーマンス向上（AWS内部ネットワークを使用）
# - コスト削減（NAT Gatewayのデータ転送料金を回避）
#------------------------------------------------------------------------------

# VPCエンドポイント用セキュリティグループ
# Interface型VPCエンドポイントを将来追加する場合に使用します。
# Gateway型のS3エンドポイントには不要ですが、ECR、CloudWatch Logs等の
# Interface型エンドポイントには必要です。
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # HTTPS通信を許可（Interface型エンドポイントはHTTPS経由でアクセス）
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]  # VPC内からのみアクセス可能
    description = "Allow HTTPS from VPC"
  }

  # すべてのアウトバウンド通信を許可
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
      Name = "${local.name_prefix}-vpc-endpoints-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# S3 VPCエンドポイント（Gateway型）
# Gateway型エンドポイントの特徴：
# - 完全無料（作成・使用ともに料金なし）
# - S3とDynamoDBのみサポート
# - ルートテーブルにエントリを追加することで動作
# - 同一リージョンのS3バケットへのアクセスに使用
# 
# このエンドポイントが必要な理由：
# 1. ECRがコンテナイメージレイヤーをS3に保存
# 2. バッチジョブが他アカウントのS3からデータを取得
# 3. NAT Gatewayのデータ転送コストを削減
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  
  # サービス名（リージョンごとに異なる）
  # 形式: com.amazonaws.{region}.s3
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  # このエンドポイントを使用するルートテーブル
  # プライベートとパブリック両方のサブネットからS3にアクセス可能にする
  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.public.id
  ]
  
  # エンドポイントポリシー（S3へのアクセス制御）
  # このポリシーは、VPCからS3へのアクセスを制限します
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"  # VPC内のすべてのリソースに許可
        Action = [
          "s3:GetObject",          # オブジェクトの読み取り
          "s3:ListBucket",         # バケット内容の一覧表示
          "s3:GetBucketLocation"   # バケットのリージョン確認
        ]
        # Resource = "*" により、すべてのS3バケットへのアクセスを許可
        # これにより、他アカウントのS3バケットからもデータ取得可能
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:PutObject",     # オブジェクトの書き込み（ECR用）
          "s3:PutObjectAcl"   # オブジェクトのACL設定（ECR用）
        ]
        # ECRがイメージレイヤーをS3に保存するために必要
        Resource = "*"
      }
    ]
  })
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-s3-endpoint"
    }
  )
}

# 注意事項:
# - Interface型エンドポイント（ECR、CloudWatch Logs等）は有料のため、
#   コスト削減を優先する場合は作成しない
# - S3エンドポイント経由でアクセスできるのは同一リージョンのS3のみ
# - クロスリージョンのS3アクセスは引き続きNAT Gateway経由となる


