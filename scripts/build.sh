#!/bin/bash
set -e

# カレントディレクトリをプロジェクトルートに設定
cd "$(dirname "$0")/.."

# 変数
IMAGE_NAME=${IMAGE_NAME:-"awa-batch-template"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

echo "=== Dockerイメージをビルドしています ==="
echo "イメージ名: ${IMAGE_NAME}"
echo "タグ: ${IMAGE_TAG}"

# Dockerイメージをビルド
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "=== ビルドが完了しました ==="
echo "ローカルでのテスト実行例:"
echo "docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} sample1"
echo "docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} sample2"
echo "docker run --rm ${IMAGE_NAME}:${IMAGE_TAG} sample3"