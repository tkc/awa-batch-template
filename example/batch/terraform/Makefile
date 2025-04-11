# AWS Batch リソース一括作成/削除用 Makefile

.PHONY: help create-all init-all apply-all destroy-all clean-all \
	create-network create-iam create-ecr create-ec2 create-fargate \
	clean-fargate clean-ec2 clean-ecr clean-iam clean-network

# デフォルトターゲット（ヘルプを表示）
help:
	@echo "使用方法:"
	@echo "  make create-all         - すべてのTerraformリソースを一括作成します"
	@echo "  make clean-all          - すべてのTerraformリソースを初期化して削除します"
	@echo "  make init-all           - すべてのTerraformモジュールを初期化します"
	@echo "  make apply-all          - すべてのTerraformリソースを適用します"
	@echo "  make destroy-all        - すべてのTerraformリソースを削除します"
	@echo ""
	@echo "  --- 一括作成コマンド ---"
	@echo "  make create-network     - ネットワークリソースを作成します"
	@echo "  make create-iam         - IAMリソースを作成します"
	@echo "  make create-ecr         - ECRリポジトリを作成します"
	@echo "  make create-ec2         - EC2リソースを作成します"
	@echo "  make create-fargate     - Fargateリソースを作成します"
	@echo ""
	@echo "  --- 一括削除コマンド ---"
	@echo "  make clean-fargate      - Fargateリソースのみ削除します"
	@echo "  make clean-ec2          - EC2リソースのみ削除します"
	@echo "  make clean-ecr          - ECRリポジトリのみ削除します"
	@echo "  make clean-iam          - IAMリソースのみ削除します"
	@echo "  make clean-network      - ネットワークリソースのみ削除します"

# すべてのリソースを作成（初期化してから作成）
create-all: init-all apply-all

# すべてのリソースを適用（依存関係を考慮して順序を設定）
apply-all: create-network create-iam create-ecr create-ec2 create-fargate
	@echo "すべてのリソースの作成が完了しました"

# ネットワークリソースの作成
create-network:
	@echo "ネットワークリソースを作成しています..."
	@cd environments/dev/network && terraform init && terraform apply -auto-approve
	@echo "ネットワークリソースの作成完了"

# IAMリソースの作成
create-iam:
	@echo "IAMリソースを作成しています..."
	@cd environments/dev/iam && terraform init && terraform apply -auto-approve
	@echo "IAMリソースの作成完了"

# ECRリポジトリの作成
create-ecr:
	@echo "ECRリポジトリを作成しています..."
	@cd environments/dev/ecr && terraform init && terraform apply -auto-approve
	@echo "ECRリポジトリの作成完了"

# EC2リソースの作成
create-ec2:
	@echo "EC2リソースを作成しています..."
	@cd environments/dev/resources && terraform init && terraform apply -auto-approve
	@echo "EC2リソースの作成完了"

# Fargateリソースの作成
create-fargate:
	@echo "Fargateリソースを作成しています..."
	@cd environments/dev/resources_fargate && terraform init && terraform apply -auto-approve
	@echo "Fargateリソースの作成完了"

# すべてのモジュールを初期化
init-all:
	@echo "すべてのTerraformモジュールを初期化しています..."
	@cd environments/dev/resources_fargate && terraform init
	@cd environments/dev/resources && terraform init
	@cd environments/dev/ecr && terraform init
	@cd environments/dev/iam && terraform init
	@cd environments/dev/network && terraform init
	@echo "初期化完了"

# すべてのリソースを削除（初期化してから削除）
clean-all: init-all destroy-all

# リソース削除の順序は依存関係を考慮して設定（先にFargateとEC2を削除）
destroy-all: clean-fargate clean-ec2 clean-ecr clean-iam clean-network
	@echo "すべてのリソースの削除が完了しました"

# Fargateリソースの削除
clean-fargate:
	@echo "Fargateリソースを削除しています..."
	@cd environments/dev/resources_fargate && terraform destroy -auto-approve || true
	@echo "Fargateリソースの削除完了"

# EC2リソースの削除
clean-ec2:
	@echo "EC2リソースを削除しています..."
	@cd environments/dev/resources && terraform destroy -auto-approve || true
	@echo "EC2リソースの削除完了"

# ECRリポジトリの削除
clean-ecr:
	@echo "ECRリポジトリを削除しています..."
	@cd environments/dev/ecr && terraform destroy -auto-approve || true
	@echo "ECRリポジトリの削除完了"

# IAMリソースの削除
clean-iam:
	@echo "IAMリソースを削除しています..."
	@cd environments/dev/iam && terraform destroy -auto-approve || true
	@echo "IAMリソースの削除完了"

# ネットワークリソースの削除
clean-network:
	@echo "ネットワークリソースを削除しています..."
	@cd environments/dev/network && terraform destroy -auto-approve || true
	@echo "ネットワークリソースの削除完了"
