#!/bin/bash
set -e

# 設定
ECR_REPOSITORY="awa-batch-dev-batch"
IMAGE_TAG="latest"
AWS_REGION="ap-northeast-1"
DOCKERFILE="Dockerfile"

# AWS アカウントID取得
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECRリポジトリURI
ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

# 現在のディレクトリを保存
CURRENT_DIR=$(pwd)

# example/batch ディレクトリに移動
cd $(dirname "$0")/..

echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Building Docker image for x86_64 architecture..."
docker buildx build --platform=linux/amd64 -f docker/${DOCKERFILE} -t ${ECR_REPO_URI}:${IMAGE_TAG} .

echo "Pushing image to ECR..."
docker push ${ECR_REPO_URI}:${IMAGE_TAG}

echo "Done! Image pushed to ${ECR_REPO_URI}:${IMAGE_TAG}"

# 元のディレクトリに戻る
cd $CURRENT_DIR
