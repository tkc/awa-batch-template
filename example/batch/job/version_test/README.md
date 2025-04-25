# AWS Batch ジョブ送信スクリプト集

このディレクトリには、AWS Batch ジョブを送信するための様々な Python スクリプトが含まれています。各スクリプトは特定の機能に特化しており、必要に応じて利用できます。

## 共通の前提条件

- Python 3.6 以上
- boto3 ライブラリのインストール (`pip install boto3`)
- AWS 認証情報の設定 (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN)
- 設定ファイル `config.py` の適切な構成

## 共通設定ファイル (`config.py`)

新しく追加された共通設定ファイルには、以下の設定が含まれています：

- EC2 と Fargate 用の各種デフォルト設定
- リソース設定のデフォルト値（vCPU、メモリ）
- フェアシェアスケジューリング関連の設定
- Fargate 用の有効なリソース値
- ロギングフォーマット

## スクリプト一覧

### EC2 用スクリプト

#### 1. シンプルなジョブ送信 (`ec2_simple_submit_job.py`)

最も基本的な機能のみを持ったスクリプトです。ジョブ名、ジョブキュー、ジョブ定義を指定してジョブを送信します。

```bash
python ec2_simple_submit_job.py --job-queue awa-batch-dev-ec2 --job-definition awa-batch-dev-ec2-sample1
```

#### 2. コンテナオーバーライド付きジョブ送信 (`ec2_submit_job_with_overrides.py`)

ジョブ定義で設定されているコンテナのコマンドや環境変数をオーバーライドするスクリプトです。

```bash
python ec2_submit_job_with_overrides.py --job-queue awa-batch-dev-ec2 --job-definition awa-batch-dev-ec2-sample1 --command '["echo", "Hello World"]' --environment '{"ENV_VAR1":"value1", "ENV_VAR2":"value2"}'
```

#### 3. リソース設定付きジョブ送信 (`ec2_submit_resource_job.py`)

EC2 ジョブのリソース設定（vCPU、メモリ）をカスタマイズするスクリプトです。

```bash
python ec2_submit_resource_job.py --job-queue awa-batch-dev-ec2 --job-definition awa-batch-dev-ec2-sample1 --vcpus 2 --memory 2048
```

#### 4. 配列ジョブ送信 (`ec2_submit_array_job.py`)

複数の同一ジョブを一括で送信する配列ジョブ用のスクリプトです。

```bash
python ec2_submit_array_job.py --job-queue awa-batch-dev-ec2 --job-definition awa-batch-dev-ec2-sample1 --array-size 10
```

#### 5. パラメータファイル付きジョブ送信 (`ec2_submit_job_with_params.py`) - 新規追加

JSON ファイルからパラメータを読み込み、ジョブにパラメータとして渡すスクリプトです。

```bash
python ec2_submit_job_with_params.py --job-queue awa-batch-dev-ec2 --job-definition awa-batch-dev-ec2-sample1 --params-file parameters.json
```

### Fargate 用スクリプト

#### 1. シンプルなジョブ送信 (`fargate_simple_submit_job.py`)

Fargate 用の基本的なジョブ送信スクリプトです。

```bash
python fargate_simple_submit_job.py --job-queue awa-batch-dev-fargate --job-definition awa-batch-dev-fargate-sample
```

#### 2. コンテナオーバーライド付きジョブ送信 (`fargate_submit_job_with_overrides.py`)

Fargate ジョブのコンテナ設定をオーバーライドするスクリプトです。

```bash
python fargate_submit_job_with_overrides.py --job-queue awa-batch-dev-fargate --job-definition awa-batch-dev-fargate-sample --command '["echo", "Hello World"]' --environment '{"ENV_VAR1":"value1"}'
```

#### 3. リソース設定付きジョブ送信 (`fargate_submit_resource_job.py`)

Fargate リソース設定（vCPU、メモリ）をカスタマイズするスクリプトです。

```bash
python fargate_submit_resource_job.py --job-queue awa-batch-dev-fargate --job-definition awa-batch-dev-fargate-sample --vcpu 1 --memory 2048
```

#### 4. 配列ジョブ送信 (`fargate_submit_array_job.py`)

Fargate 用の配列ジョブ送信スクリプトです。

```bash
python fargate_submit_array_job.py --job-queue awa-batch-dev-fargate --job-definition awa-batch-dev-fargate-sample --array-size 10
```

#### 5. パラメータファイル付きジョブ送信 (`fargate_submit_job_with_params.py`) - 新規追加

JSON ファイルからパラメータを読み込み、Fargate ジョブにパラメータとして渡すスクリプトです。

```bash
python fargate_submit_job_with_params.py --job-queue awa-batch-dev-fargate --job-definition awa-batch-dev-fargate-sample --params-file parameters.json
```

## Makefile による実行

便利な Makefile が用意されており、簡単にジョブを送信できます。

```bash
# すべてのジョブを実行
make run-all

# EC2ジョブのみ実行
make run-all-ec2

# Fargateジョブのみ実行
make run-all-fargate

# 個別のジョブを実行
make ec2-simple
make fargate-params
```

使用可能なコマンドの一覧を表示するには：

```bash
make help
```

## 特記事項

### フェアシェアスケジューリング対応

- EC2 ジョブキューには、フェアシェアスケジューリングポリシーが設定されており、対応するパラメータ（shareIdentifier、schedulingPriorityOverride）が必要です。
- Fargate ジョブキューには、標準のスケジューリングが使用されています。
- これらの設定は `config.py` で管理されています。

### ジョブパラメータ

新しく追加されたパラメータファイル機能を使うと、JSON ファイルからジョブパラメータを読み込むことができます。サンプルのパラメータファイル `parameters.json` を参照してください。

### エラーハンドリング

すべてのスクリプトは、エラー発生時に標準エラー出力にエラーメッセージを出力し、正常終了しない場合は非ゼロの終了コードを返します。

### ログ形式

すべてのスクリプトは、共通のログ形式を使用しています：

```
YYYY-MM-DD HH:MM:SS - LEVEL - メッセージ
```

## 注意事項

1. すべてのスクリプトは、正常にジョブが送信された場合、標準出力にジョブ ID を出力します。これにより、他のスクリプトやシェルからジョブ ID を取得できます。

2. フェアシェアスケジューリングを使用する場合は、対象のジョブキューにフェアシェアスケジューリングポリシーが設定されている必要があります。

3. 配列ジョブでは、各ジョブは環境変数 `AWS_BATCH_JOB_ARRAY_INDEX` で 0 から（配列サイズ-1）までの値を取得できます。

4. Fargate リソース設定は Fargate コンピュート環境でのみ有効です。EC2 コンピュート環境では異なるパラメータ（vcpus ではなく vcpu）を使用しています。
