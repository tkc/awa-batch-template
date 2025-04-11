# AWS Batch 実行環境

このディレクトリには、AWS Batch でデータ処理ジョブを実行するための設定ファイルとスクリプトが含まれています。

## 構成要素

- `docker/Dockerfile`: AWS Batch ジョブを実行するための Docker イメージを定義します。
- `run_batch.py`: Docker コンテナ内で実行されるメインスクリプトです。環境変数から設定を読み込み、`src/batch_processor` の処理を実行します。
- `terraform/`: AWS Batch 環境（ジョブキュー、コンピューティング環境、ジョブ定義など）を構築するための Terraform コードが含まれています。

## Docker イメージのビルド

AWS Batch でジョブを実行するには、まず Docker イメージをビルドし、ECR (Elastic Container Registry) などのコンテナリポジトリにプッシュする必要があります。

```bash
# 1. Docker イメージのビルド
#    **重要:** このコマンドは **このディレクトリ** (`example/batch`) から実行してください。
#    (例: cd example/batch)
#    イメージ名は適宜変更してください (例: my-batch-job)

# 本番ファイル
docker build -t batch-processor-job -f docker/Dockerfile .

# TESTファイル
docker build -t batch-processor-job-test -f docker/DockerTestfile .

# 2. (オプション) ECR へのプッシュ
#    <your-aws-account-id>, <your-region>, <repository-name> を実際の値に置き換えてください
#    事前に ECR リポジトリを作成しておく必要があります (Terraform で作成可能)
# aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <your-aws-account-id>.dkr.ecr.<your-region>.amazonaws.com
# docker tag batch-processor-job:latest <your-aws-account-id>.dkr.ecr.<your-region>.amazonaws.com/<repository-name>:latest
# docker push <your-aws-account-id>.dkr.ecr.<your-region>.amazonaws.com/<repository-name>:latest
```

## テスト用イメージのビルドと実行

`DockerTestfile` を使用して、簡単なテストスクリプト (`run_batch_test.py`) を実行するイメージをビルドできます。これは、依存関係のインストールや基本的なコンテナ実行を確認するのに役立ちます。

```bash
# 1. テスト用イメージのビルド (example/batch ディレクトリから実行)
docker build -t batch-processor-job-test -f docker/DockerTestfile .

# 2. テスト用イメージの実行
docker run --rm batch-processor-job-test
# -> "success run_batch_test" と表示されれば成功
```

## 本番用イメージのローカルテスト実行

ビルドしたイメージをローカルでテスト実行できます。`run_batch.py` は環境変数から設定を読み込むため、`-e` オプションで必要な値を渡します。

```bash
# ローカル実行の例 (データファイルをボリュームマウントする場合)
# このコマンドは example/batch ディレクトリから実行することを想定
docker run --rm \
  -e PROCESS_ID="local-test-$(date +%s)" \
  -e CSV_PATH="/app/data/sample1_data.csv" \
  -v "$(pwd)/../../data":/app/data:ro \
  batch-processor-job

# または、Dockerfile を修正してデータをイメージ内に含める場合は以下のように実行
# (Dockerfile に COPY ../../data/sample1_data.csv /app/data/sample1_data.csv を追加し再ビルドした場合)
# docker run --rm \
#   -e PROCESS_ID="local-test-$(date +%s)" \
#   -e CSV_PATH="/app/data/sample1_data.csv" \
#   batch-processor-job

# Test実行
docker run --rm batch-processor-job-test
```

**注意:** 上記の `CSV_PATH` はコンテナ内のパスです。ボリュームマウントを使用しない場合は、Dockerfile を修正してデータファイルをイメージに含める必要があります。

## Terraform によるインフラ構築

`terraform/` ディレクトリ内の Terraform コードを使用して、AWS Batch の実行に必要なインフラストラクチャ（VPC、サブネット、セキュリティグループ、IAM ロール、ECR リポジトリ、Batch コンピューティング環境、ジョブキュー、ジョブ定義など）を構築できます。

### 前提条件

1.  **Terraform のインストール:**
    Terraform がローカル環境にインストールされている必要があります。インストールされていない場合は、[公式ウェブサイト](https://developer.hashicorp.com/terraform/downloads) の手順に従ってインストールしてください。
    (例: macOS の場合 `brew install terraform`)

2.  **AWS 認証情報の設定:**
    Terraform が AWS アカウントを操作するための認証情報が必要です。以下のいずれかの方法で設定してください。

    - **環境変数:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` (オプション), `AWS_REGION` を設定します。
    - **共有認証情報ファイル:** `~/.aws/credentials` ファイルに認証情報を設定します。
    - **IAM ロール:** EC2 インスタンスや ECS タスクなど、IAM ロールが割り当てられた環境で実行する場合は、自動的に認証情報が使用されます。

    詳細は [AWS Provider の認証ドキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration) を参照してください。

### 状態管理 (State Management)

デフォルトでは、Terraform の状態は `example/batch/terraform` ディレクトリ内に `terraform.tfstate` という名前のローカルファイルとして保存されます。チームで作業する場合や状態ファイルを安全に管理したい場合は、`main.tf` 内の `backend "s3"` ブロックのコメントを解除し、S3 バケットと DynamoDB テーブルを設定してリモート状態管理を有効にすることを推奨します。

### 実行手順

```bash
# Terraform ディレクトリへ移動
cd example/batch/terraform

# Terraform の初期化
terraform init

# (オプション) 実行計画の確認
terraform plan

# インフラの構築
terraform apply

# インフラの削除 (注意: 管理下の全リソースが削除されます)
terraform destroy
```

詳細については、`terraform/README.md` (もし存在すれば) を参照してください。

### インフラの削除

Terraform で構築したインフラストラクチャを削除するには、以下のコマンドを実行します。

```bash
# Terraform ディレクトリへ移動
cd example/batch/terraform

# インフラの削除
terraform destroy
```

**警告:** `terraform destroy` コマンドは、Terraform によって管理されている **すべての** リソースを AWS 環境から削除します。この操作は元に戻せません。実行する前に、削除されるリソースをよく確認し、プロンプトで `yes` と入力してください。

## AWS CLI によるインフラ構築とジョブ実行 (代替)

Terraform を使用する代わりに、AWS CLI を使用して手動で AWS Batch 環境を構築し、ジョブを実行することも可能です。以下に手順の概要を示します。

**注意:** 以下のコマンドのプレースホルダー (`your-region`, `aws_account_id`, `my-batch-repository`, `my-job-definition`, `my-job-queue`, `my-compute-environment`, `subnet-id1`, `sg-id`, `your-instance-role-arn`, `your-service-role-arn`, `my-command` など) は、実際の環境に合わせて適切な値に置き換えてください。

### 1. Docker イメージのビルドと ECR へのプッシュ

```bash
# Docker イメージのビルド (example/batch ディレクトリから実行)
# イメージ名は適宜変更してください
docker build -t my-batch-job -f docker/Dockerfile .

# ECR リポジトリの作成 (存在しない場合)
aws ecr create-repository --repository-name my-batch-repository --region ap-northeast-1

# ECR へのログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.ap-northeast-1.amazonaws.com

# Docker イメージのタグ付け
docker tag my-batch-job:latest aws_account_id.dkr.ecr.ap-northeast-1.amazonaws.com/my-batch-repository:latest

# Docker イメージのプッシュ
docker push aws_account_id.dkr.ecr.ap-northeast-1.amazonaws.com/my-batch-repository:latest
```

### 2. AWS Batch コンピューティング環境の作成 (既存のものがない場合)

ジョブを実行するためのコンピューティングリソースを定義します。事前に適切な IAM ロール (Instance Role, Service Role) やネットワークリソース (VPC, Subnet, Security Group) が必要です。

```bash
aws batch create-compute-environment \
    --compute-environment-name my-compute-environment \
    --type MANAGED \
    --state ENABLED \
    --compute-resources '{
        "type": "EC2",
        "minvCpus": 0,
        "maxvCpus": 4,
        "desiredvCpus": 0,
        "instanceTypes": ["optimal"],
        "subnets": ["subnet-id1", "subnet-id2"],
        "securityGroupIds": ["sg-id"],
        "instanceRole": "your-instance-role-arn"
    }' \
    --service-role your-service-role-arn \
    --region ap-northeast-1
```

### 3. AWS Batch ジョブキューの作成

実行待ちのジョブを保持するキューを作成します。作成したコンピューティング環境に関連付けます。

```bash
# コンピューティング環境の ARN を取得 (例)
COMPUTE_ENV_ARN=$(aws batch describe-compute-environments --compute-environments my-compute-environment --query "computeEnvironments[0].computeEnvironmentArn" --output text --region ap-northeast-1)

aws batch create-job-queue \
    --job-queue-name my-job-queue \
    --state ENABLED \
    --priority 1 \
    --compute-environment-order '[{"order":1,"computeEnvironment":"'"$COMPUTE_ENV_ARN"'"}]' \
    --region ap-northeast-1
```

### 4. AWS Batch ジョブ定義の作成

実行するコンテナイメージ、リソース要件、コマンドなどを定義します。

```bash
# ECR イメージ URI を変数に設定 (例)
IMAGE_URI="aws_account_id.dkr.ecr.ap-northeast-1.amazonaws.com/my-batch-repository:latest"

aws batch register-job-definition \
    --job-definition-name my-job-definition \
    --type container \
    --container-properties '{
        "image": "'"$IMAGE_URI"'",
        "vcpus": 1,
        "memory": 2048,
        "command": ["python", "run_batch.py", "sample1", "--param1", "value1", "--param2", "value2"],
        "jobRoleArn": "your-job-role-arn",
        "environment": [
          {"name": "S3_BUCKET", "value": "your-s3-bucket-name"},
          {"name": "ENVIRONMENT", "value": "dev"}
        ]
    }' \
    --region ap-northeast-1
```

_注意:_ `command` 配列内のコマンドや引数、`jobRoleArn`, `environment` 変数は、実際のジョブに合わせて修正してください。

### 5. AWS Batch ジョブの投入

作成したジョブ定義とジョブキューを指定して、ジョブを実行します。

```bash
aws batch submit-job \
    --job-name my-cli-job-$(date +%s) \
    --job-queue my-job-queue \
    --job-definition my-job-definition \
    --region ap-northeast-1
```

ジョブのステータスは AWS マネジメントコンソールや `aws batch describe-jobs` コマンドで確認できます。

### 6. ECR リポジトリの削除

不要になった ECR リポジトリは以下のコマンドで削除できます。

```bash
aws ecr delete-repository --repository-name my-batch-repository --region ap-northeast-1 --force
```

**警告:** `--force` オプションを使用すると、リポジトリ内にイメージが存在していても強制的に削除されます。このオプションを使用しない場合は、事前にリポジトリ内のすべてのイメージを削除する必要があります (`aws ecr batch-delete-image` コマンドなどを使用)。

## ジョブの実行

Terraform でインフラが構築され、Docker イメージが ECR にプッシュされた後、AWS マネジメントコンソール、AWS CLI、または SDK を使用して AWS Batch ジョブをサブミットできます。ジョブ定義には、ECR にプッシュした Docker イメージの URI を指定します。
