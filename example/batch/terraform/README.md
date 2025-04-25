# AWS Batch Terraform モジュール（EC2 と Fargate）

このリポジトリには、AWS Batch リソースを管理するための Terraform モジュールが含まれています。EC2 と Fargate の両方のコンピューティング環境に対応しています。

## ディレクトリ構造

```
terraform/
├── modules/
│   ├── network/                # ネットワークリソース用モジュール
│   ├── iam/                    # IAMリソース用モジュール
│   ├── resources_ec2/          # EC2ベースのAWS Batchリソース用モジュール
│   └── resources_fargate/      # Fargateベースのバッチリソース用モジュール
├── environments/
│   └── dev/
│       ├── network/            # 開発環境のネットワーク設定
│       ├── iam/                # 開発環境のIAM設定
│       ├── ec2/                # 開発環境のEC2バッチリソース設定
│       └── fargate/            # 開発環境のFargateバッチリソース設定
└── shared/
    └── backend.tf              # 共有のバックエンド設定
```

## モジュールの使い分け

### EC2 と Fargate の主な違い

| 特徴         | EC2                           | Fargate                              |
| ------------ | ----------------------------- | ------------------------------------ |
| サーバー管理 | EC2 インスタンスの管理が必要  | サーバーレス（インスタンス管理不要） |
| コスト       | スポットインスタンスで安価    | 使用分のみの課金だが EC2 より高め    |
| リソース指定 | インスタンスタイプを選択      | vCPU とメモリを指定                  |
| スケーリング | min/max/desired の vCPUs 設定 | 最大 vCPUs のみ設定                  |
| 起動速度     | インスタンス起動時間が必要    | 比較的速く起動                       |
| リソース効率 | ベストエフォート配置          | タスクごとの厳密なリソース保証       |

### いつどちらを使うべきか

**EC2 ベースを選ぶ場合**:

- コスト効率が重要
- 大量のバッチジョブを実行する場合
- スポットインスタンスを活用したい場合
- カスタム AMI やインスタンス設定が必要な場合

**Fargate を選ぶ場合**:

- 簡単な管理が重要
- サーバーレスアーキテクチャを維持したい
- 予測不可能なワークロードがある場合
- 小規模なタスクを多数実行する場合
- ECS や Fargate とのインテグレーションがある場合

## 使用方法

### 1. 前提条件

- Terraform v1.0.0 以上
- AWS CLI 設定済み
- 十分な IAM 権限

### 2. モジュールのデプロイ手順

EC2 と Fargate 環境を別々にデプロイするには、以下の順序で実行します：

```bash
# まずネットワークリソースをデプロイ
cd environments/dev/network
terraform init
terraform apply

# 次にIAMリソースをデプロイ
cd ../iam
terraform init
terraform apply

# EC2ベースのバッチ環境をデプロイ
cd ../ec2
terraform init
terraform apply

# Fargateベースのバッチ環境をデプロイ（オプション）
cd ../fargate
terraform init
terraform apply
```

### 3. バッチジョブの実行

ジョブを送信するには、先に作成したジョブキューとジョブ定義 ARN を使用します。

#### EC2 環境へのジョブ送信

```bash
cd /Users/takeshiiijima/github/awa-batch-template/example/batch/job/version_test # ディレクトリパスを修正
python ec2_simple_submit_job.py --job-queue awa-batch-dev-ec2 --job-definition awa-batch-dev-ec2-sample1 # ジョブキュー名を修正
```

#### Fargate 環境へのジョブ送信

```bash
cd /Users/takeshiiijima/github/awa-batch-template/example/batch/job/version_test # ディレクトリパスを修正
python fargate_simple_submit_job.py --job-queue awa-batch-dev-fargate --job-definition awa-batch-dev-fargate-sample # ジョブキュー名を修正
```

## カスタマイズ

### EC2 環境の設定変更

`environments/dev/ec2/terraform.tfvars` を編集して、以下のパラメータを変更できます：

- インスタンスタイプ
- 最大・最小・希望する vCPUs
- コンテナイメージ
- その他のパラメータ

### Fargate 環境の設定変更

`environments/dev/fargate/terraform.tfvars` を編集して、以下のパラメータを変更できます：

- Fargate vCPU (0.25, 0.5, 1, 2, 4 のいずれか)
- Fargate メモリ (512, 1024, 2048, 4096 等)
- 最大 vCPUs
- コンテナイメージ

## 注意事項

- EC2 と Fargate の両方を同時にデプロイすると、名前の競合を避けるために異なるリソース名が使用されます。
- EC2 環境と Fargate 環境はそれぞれ独立してデプロイおよび破棄できます。
- バッチジョブの実行時には、適切なジョブキューとジョブ定義を指定してください。
- Fargate ジョブ定義では、`vcpus`と`memory`の代わりに`resourceRequirements`を使用します。
- Fargate には、EC2 と異なる実行ロール（execution role）が必要です。

## リソースの破棄

```bash
# Fargate環境の破棄
cd environments/dev/fargate
terraform destroy

# EC2環境の破棄
cd ../ec2
terraform destroy

# IAMリソースの破棄
cd ../iam
terraform destroy

# ネットワークリソースの破棄
cd ../network
terraform destroy
```
