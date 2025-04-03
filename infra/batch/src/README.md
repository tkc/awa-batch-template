# AWS Batch 実行ガイド

このドキュメントは、AWS Batch 環境でデータ処理ジョブを実行するためのガイドラインを提供します。

## 概要

このディレクトリには、AWS Batch 環境でデータ処理ジョブを実行するためのコンポーネントが含まれています：

- `run_batch.py`: AWS Batch ジョブのエントリーポイントスクリプト。環境変数から設定を読み込み、インストールされた `awa_batch_processor` パッケージの `sample1` コマンドを実行します。
- `pyproject.toml`: AWS Batch 実行環境用の Poetry 設定ファイル。メインプロジェクトを Git 依存関係としてインストールするよう定義されています。
- `poetry.lock`: 依存関係のロックファイル。

## セットアップ

### Docker イメージのビルド

AWS Batch で使用する Docker イメージは、`infra/batch/docker/Dockerfile` を使用してビルドします。ビルドコンテキストは **プロジェクトのルートディレクトリ** から行うことが重要です：

```bash
# プロジェクトルートディレクトリで実行
docker build -t your-ecr-repo/batch-processor:latest -f infra/batch/docker/Dockerfile .

# イメージをECRにプッシュ
aws ecr get-login-password --region YOUR_REGION | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com
docker tag your-ecr-repo/batch-processor:latest YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/your-ecr-repo:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/your-ecr-repo:latest
```

### インフラストラクチャのセットアップ

AWS Batch 実行環境は Terraform を使用して構築できます：

```bash
cd infra/batch/terraform
terraform init
terraform apply
```

## パラメータ設定

AWS Batch ジョブのパラメータは、以下の方法で設定できます：

1. **環境変数**: ジョブ送信時に `--container-overrides` の `environment` で指定します。

   主な環境変数：
   - `CONFIG_FILE`: 設定ファイルのパス（S3など）
   - `AWS_REGION`: AWSリージョン
   - `LOG_LEVEL`: ログレベル（INFO、DEBUG、WARNINGなど）

2. **設定ファイル**: S3バケットにJSON形式の設定ファイルを配置し、`CONFIG_FILE`環境変数で参照します。  
   設定ファイルの形式は以下の例の通りです：

   ```json
   {
     "input_file": "s3://your-bucket/input/sample_data.csv",
     "output_file": "s3://your-bucket/output/result.csv",
     "validate_only": false
   }
   ```

## AWS Batch ジョブの実行

### AWS コンソールからの実行

1. AWS Management Console にログイン
2. AWS Batch サービスに移動
3. 「ジョブ」→「ジョブの送信」を選択
4. ジョブ定義とジョブキューを選択
5. 「コンテナオーバーライド」セクションで環境変数を指定

### AWS CLI からの実行

```bash
aws batch submit-job \
    --job-name "sample1-batch-job" \
    --job-queue "your-job-queue-name" \
    --job-definition "your-batch-job-definition" \
    --container-overrides '{
        "environment": [
            {"name": "CONFIG_FILE", "value": "s3://your-bucket/config/params.json"},
            {"name": "LOG_LEVEL", "value": "INFO"}
        ]
    }'
```

### AWS SDK (Python) からの実行

```python
import boto3

batch_client = boto3.client('batch')

response = batch_client.submit_job(
    jobName='sample1-batch-job',
    jobQueue='your-job-queue-name',
    jobDefinition='your-batch-job-definition',
    containerOverrides={
        'environment': [
            {'name': 'CONFIG_FILE', 'value': 's3://your-bucket/config/params.json'},
            {'name': 'LOG_LEVEL', 'value': 'INFO'}
        ]
    }
)

print(f"Job submitted with ID: {response['jobId']}")
```

## ログとモニタリング

AWS Batch ジョブのログは CloudWatch Logs に保存されます。ログを確認するには：

1. AWS Management Console で CloudWatch サービスに移動
2. 「ロググループ」を選択
3. AWS Batch のロググループ（通常は `/aws/batch/job`）を選択
4. 該当するジョブIDのログストリームを選択

## エラーハンドリング

`run_batch.py` は以下のようなエラーハンドリングを実装しています：

- 設定読み込みエラー: 環境変数からの設定読み込みに失敗した場合、エラーメッセージと共に終了コード 1 で終了
- 検証エラー: スキーマ検証などに失敗した場合、エラーメッセージと共に終了コード 1 で終了
- 予期しないエラー: その他の例外が発生した場合、エラーメッセージと共に終了コード 1 で終了

エラーメッセージは CloudWatch Logs で確認できます。

## 依存関係の更新

このプロジェクトは Git リポジトリからメインコードを依存関係としてインストールします。依存関係のバージョンを更新するには、`pyproject.toml` の `rev` パラメータを変更します：

```toml
[tool.poetry.dependencies]
awa-batch-processor = { git = "https://github.com/tkc/awa-batch-template.git", rev = "v0.0.2" }
```

更新後は Docker イメージを再ビルドしてデプロイする必要があります。

## ベストプラクティス

- **冪等性の確保**: 処理ロジックは複数回実行しても安全なように設計する
- **適切なリソース割り当て**: ジョブ定義で適切なCPU/メモリを設定する
- **タイムアウト設定**: 長時間実行されるジョブには適切なタイムアウトを設定する
- **再試行戦略**: 一時的な障害の場合は自動再試行を設定する
- **十分なログ出力**: デバッグ用に詳細なログを出力する
