# SageMaker Pipeline 実行ガイド

このドキュメントは、`src/sagemaker` パッケージに含まれる SageMaker Pipeline の実行に関するガイドラインを提供します。

## 概要

このパッケージは、SageMaker Pipeline を使用してデータ処理ジョブを実行するためのコンポーネントを含みます。

- `pipeline.py`: SageMaker Pipeline の定義と登録/更新を行うスクリプト。
- `run_all_samples.py`: パイプラインのステップ内で複数の `sample1` コマンドを順次実行するためのスクリプト。
- `Dockerfile`: SageMaker Pipeline で使用する Docker イメージをビルドするための定義ファイル。

## 実行方法

### 1. Docker イメージのビルドとプッシュ

SageMaker Pipeline で使用する Docker イメージをビルドし、ECR リポジトリにプッシュします。ビルドコンテキストはプロジェクトのルートディレクトリを指定する必要があります。

```bash
# プロジェクトルートディレクトリで実行
docker build -t YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/your-sagemaker-image:latest -f src/sagemaker/Dockerfile .

# ECR にログイン (必要に応じて)
aws ecr get-login-password --region YOUR_REGION | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com

# イメージをプッシュ
docker push YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/your-sagemaker-image:latest
```

**注意:** `YOUR_ACCOUNT_ID`, `YOUR_REGION`, `your-sagemaker-image:latest` は実際の値に置き換えてください。

### 2. パイプラインの登録/更新

`pipeline.py` スクリプトを実行して、SageMaker Pipeline を登録または更新します。実行には AWS 認証情報と `sagemaker` ライブラリが必要です。

```bash
# プロジェクトルートディレクトリで実行
python src/sagemaker/pipeline.py \
    --pipeline-name my-sample1-pipeline \
    --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/YourPipelineUpsertRole \
    --region YOUR_REGION
```

**注意:**

- `--role-arn` には、パイプラインの登録/更新に必要な権限を持つ IAM ロールを指定してください。
- `--region` には、パイプラインを作成する AWS リージョンを指定してください。

### 3. パイプラインの実行

SageMaker コンソールまたは AWS SDK (例: Boto3) を使用して、登録したパイプラインの実行を開始します。実行時には、`pipeline.py` で定義されたパイプラインパラメータを指定する必要があります。

例 (Boto3 を使用):

```python
import boto3

sagemaker_client = boto3.client("sagemaker")

response = sagemaker_client.start_pipeline_execution(
    PipelineName='my-sample1-pipeline', # パイプライン名
    PipelineParameters=[
        {'Name': 'ProcessingInstanceType', 'Value': 'ml.m5.large'},
        {'Name': 'ProcessingInstanceCount', 'Value': '1'},
        # {'Name': 'InputData', 'Value': 's3://your-bucket/input/sample1_data.csv'}, # Not used by steps currently
        {'Name': 'ConfigFile1', 'Value': 's3://your-bucket/config/params_run1.json'}, # Path to first config
        {'Name': 'ConfigFile2', 'Value': 's3://your-bucket/config/params_run2.json'}, # Path to second config
        # {'Name': 'OutputData1', 'Value': 's3://your-bucket/output/run1/'}, # Output path for first run (if outputs are added)
        # {'Name': 'OutputData2', 'Value': 's3://your-bucket/output/run2/'}, # Output path for second run (if outputs are added)
        {'Name': 'ProcessingImageUri', 'Value': 'YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/your-sagemaker-image:latest'},
        {'Name': 'ExecutionRoleArn', 'Value': 'arn:aws:iam::YOUR_ACCOUNT_ID:role/YourStepExecutionRole'} # ステップ実行用のロール
    ]
)

print(f"Pipeline execution started: {response['PipelineExecutionArn']}")
```

**注意:**

- `PipelineParameters` の値は、実際の環境に合わせて設定してください。
- `ExecutionRoleArn` には、パイプラインの各ステップ（Processing ジョブなど）を実行するための権限を持つ IAM ロールを指定してください。

## 設定

SageMaker Pipeline の実行時パラメータは、パイプラインの実行開始時に指定します。パラメータの詳細は `src/sagemaker/pipeline.py` の `define_parameters` 関数を参照してください。

処理ステップ内で使用される設定（`sample1` コマンドのパラメータ）は、`ConfigFile` パラメータで指定された S3 上の JSON ファイルから読み込まれます。JSON ファイルの形式は、プロジェクトルートの `src/models.py` を参照してください。
