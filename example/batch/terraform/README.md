# AWS Batch Terraform モジュール（EC2とFargate）

このリポジトリには、AWS Batchリソースを管理するためのTerraformモジュールが含まれています。EC2とFargateの両方のコンピューティング環境に対応しています。

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

### EC2とFargateの主な違い

| 特徴 | EC2 | Fargate |
|------|-----|---------|
| サーバー管理 | EC2インスタンスの管理が必要 | サーバーレス（インスタンス管理不要） |
| コスト | スポットインスタンスで安価 | 使用分のみの課金だがEC2より高め |
| リソース指定 | インスタンスタイプを選択 | vCPUとメモリを指定 |
| スケーリング | min/max/desiredのvCPUs設定 | 最大vCPUsのみ設定 |
| 起動速度 | インスタンス起動時間が必要 | 比較的速く起動 |
| リソース効率 | ベストエフォート配置 | タスクごとの厳密なリソース保証 |

### いつどちらを使うべきか

**EC2ベースを選ぶ場合**:
- コスト効率が重要
- 大量のバッチジョブを実行する場合
- スポットインスタンスを活用したい場合
- カスタムAMIやインスタンス設定が必要な場合

**Fargateを選ぶ場合**:
- 簡単な管理が重要
- サーバーレスアーキテクチャを維持したい
- 予測不可能なワークロードがある場合
- 小規模なタスクを多数実行する場合
- ECSやFargateとのインテグレーションがある場合

## 使用方法

### 1. 前提条件

- Terraform v1.0.0以上
- AWS CLI設定済み
- 十分なIAM権限

### 2. モジュールのデプロイ手順

EC2とFargate環境を別々にデプロイするには、以下の順序で実行します：

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

ジョブを送信するには、先に作成したジョブキューとジョブ定義ARNを使用します。

#### EC2環境へのジョブ送信

```bash
cd /Users/takeshiiijima/github/awa-batch-template/example/batch/job
python submit_job.py --job-queue awa-batch-dev-ec2-high-priority --job-definition awa-batch-dev-ec2-sample1
```

#### Fargate環境へのジョブ送信

```bash
cd /Users/takeshiiijima/github/awa-batch-template/example/batch/job
python submit_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample
```

## カスタマイズ

### EC2環境の設定変更

`environments/dev/ec2/terraform.tfvars` を編集して、以下のパラメータを変更できます：

- インスタンスタイプ
- 最大・最小・希望するvCPUs
- コンテナイメージ
- その他のパラメータ

### Fargate環境の設定変更

`environments/dev/fargate/terraform.tfvars` を編集して、以下のパラメータを変更できます：

- Fargate vCPU (0.25, 0.5, 1, 2, 4のいずれか)
- Fargateメモリ (512, 1024, 2048, 4096等)
- 最大vCPUs
- コンテナイメージ

## 注意事項

- EC2とFargateの両方を同時にデプロイすると、名前の競合を避けるために異なるリソース名が使用されます。
- EC2環境とFargate環境はそれぞれ独立してデプロイおよび破棄できます。
- バッチジョブの実行時には、適切なジョブキューとジョブ定義を指定してください。
- Fargateジョブ定義では、`vcpus`と`memory`の代わりに`resourceRequirements`を使用します。
- Fargateには、EC2と異なる実行ロール（execution role）が必要です。

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
