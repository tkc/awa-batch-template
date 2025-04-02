#!/bin/bash
set -e

# カレントディレクトリをプロジェクトルートに設定
cd "$(dirname "$0")/.."

# 変数
AWS_REGION=${AWS_REGION:-"ap-northeast-1"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

# ECRリポジトリ名を取得（Terraformの出力から）
ECR_REPOSITORY=$(cd terraform && terraform output -raw ecr_repository_name)
if [ -z "$ECR_REPOSITORY" ]; then
  echo "ERROR: ECRリポジトリが見つかりません。先にTerraformを適用してください。"
  exit 1
fi

# AWSアカウントIDを取得
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPOSITORY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo "=== Dockerイメージをビルドして、ECRにプッシュします ==="
echo "ECRリポジトリ: ${ECR_REPOSITORY_URI}"
echo "タグ: ${IMAGE_TAG}"

# ECRにログイン
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Dockerイメージをビルド
echo "Dockerイメージをビルドしています..."
docker build -t ${ECR_REPOSITORY_URI}:${IMAGE_TAG} .

# ECRにプッシュ
echo "イメージをECRにプッシュしています..."
docker push ${ECR_REPOSITORY_URI}:${IMAGE_TAG}

echo "=== デプロイが完了しました ==="
echo "イメージ: ${ECR_REPOSITORY_URI}:${IMAGE_TAG}"
