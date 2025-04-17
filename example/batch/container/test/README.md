# AWS Batch テンプレート - テスト用コンテナ

このディレクトリには、AWS Batch 用のテスト用 Docker コンテナをビルドするためのファイルが含まれています。

## 概要

テスト用コンテナは、AWS Batch ジョブのテスト実行用に設計されています。実際のプロダクション環境で使用される前に、バッチ処理の動作確認を行うことができます。

## ファイル構成

- `Dockerfile`: テスト用コンテナのビルド定義
- `build_and_push.sh`: Docker イメージをビルドし、ECR にプッシュするスクリプト
- `pyproject.toml`: プロジェクトの依存関係定義
- `run_batch.py`: バッチ処理を実行するメインスクリプト

## 前提条件

- Docker
- AWS CLI（設定済み）
- ECR リポジトリへのアクセス権限

## 使用方法

### Docker イメージのビルドとプッシュ

以下のコマンドを実行して、Docker イメージをビルドし、ECR にプッシュします：

```bash
./build_and_push.sh
```

スクリプトは以下の処理を行います：

- AWS ECR へのログイン
- Docker イメージのビルド（x86_64 アーキテクチャ向け）
- ECR へのイメージプッシュ

## 受け取ったパラメータのサンプル

```json
{
  "inputFile": "s3://example-bucket/input/data.csv",
  "outputPath": "s3://example-bucket/output/",
  "settings": {
    "batchSize": 64,
    "modelType": "classification",
    "maxIterations": 100,
    "learningRate": 0.01
  },
  "metadata": {
    "jobType": "batch-processing",
    "version": "1.0.0",
    "description": "サンプルバッチ処理ジョブ"
  }
}
```

## 関連リソース

- [Using uv in Docker](https://docs.astral.sh/uv/guides/integration/docker/)
