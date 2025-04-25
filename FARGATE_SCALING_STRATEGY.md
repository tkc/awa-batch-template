# AWS Batch Fargate スケーリング設定ガイド

## 目次

1. [はじめに](#はじめに)
2. [Fargate におけるスケーリングの特徴](#fargateにおけるスケーリングの特徴)
3. [基本的なスケーリング設定](#基本的なスケーリング設定)
4. [ワークロードタイプ別のスケーリング戦略](#ワークロードタイプ別のスケーリング戦略)
5. [モニタリングとチューニング](#モニタリングとチューニング)
6. [ベストプラクティス](#ベストプラクティス)
7. [まとめ](#まとめ)

## はじめに

AWS Batch on Fargate は、サーバーレスコンピューティングを利用したバッチ処理を実現します。EC2 とは異なり、Fargate ではインスタンスの管理が不要でより簡単にスケーリングを設定できます。このドキュメントでは、Fargate を利用した AWS Batch のスケーリング設定について説明します。

## Fargate におけるスケーリングの特徴

Fargate を使用した AWS Batch のスケーリングには、EC2 と比較していくつかの重要な違いがあります：

### EC2 と Fargate のスケーリング比較

| 機能                   | EC2                        | Fargate                       |
| ---------------------- | -------------------------- | ----------------------------- |
| インスタンス管理       | 必要                       | 不要（サーバーレス）          |
| インスタンスタイプ選択 | 必要                       | 不要（vCPU とメモリのみ指定） |
| スケーリング粒度       | インスタンス単位           | タスク単位（より細かい）      |
| スケーリング速度       | インスタンス起動時間に依存 | 通常より高速                  |
| キャパシティ制限       | インスタンス数制限あり     | アカウントのタスク制限のみ    |

### Fargate スケーリングの主要パラメータ

- **maxvCpus**: コンピューティング環境がスケールアップできる vCPU の最大数
- **subnets**: Fargate タスクが起動するサブネット
- **securityGroupIds**: Fargate タスクに適用するセキュリティグループ

## 基本的なスケーリング設定

### Fargate コンピューティング環境の作成

```bash
aws batch create-compute-environment \
    --compute-environment-name fargate-compute-env \
    --type MANAGED \
    --state ENABLED \
    --compute-resources type=FARGATE,\
       maxvCpus=256,\
       subnets=subnet-xxx,subnet-yyy,\
       securityGroupIds=sg-zzz \
    --service-role AWSServiceRoleForBatch
```

### Fargate Spot を使用した低コスト環境の作成

```bash
aws batch create-compute-environment \
    --compute-environment-name fargate-spot-compute-env \
    --type MANAGED \
    --state ENABLED \
    --compute-resources type=FARGATE_SPOT,\
       maxvCpus=256,\
       subnets=subnet-xxx,subnet-yyy,\
       securityGroupIds=sg-zzz \
    --service-role AWSServiceRoleForBatch
```

### ハイブリッド環境の設定（Fargate + Fargate Spot）

```bash
# Fargate（オンデマンド）環境
aws batch create-compute-environment \
    --compute-environment-name fargate-ondemand-env \
    --type MANAGED \
    --state ENABLED \
    --compute-resources type=FARGATE,\
       maxvCpus=128,\
       subnets=subnet-xxx,subnet-yyy,\
       securityGroupIds=sg-zzz \
    --service-role AWSServiceRoleForBatch

# Fargate Spot環境
aws batch create-compute-environment \
    --compute-environment-name fargate-spot-env \
    --type MANAGED \
    --state ENABLED \
    --compute-resources type=FARGATE_SPOT,\
       maxvCpus=256,\
       subnets=subnet-xxx,subnet-yyy,\
       securityGroupIds=sg-zzz \
    --service-role AWSServiceRoleForBatch

# 両方を使用するジョブキュー
aws batch create-job-queue \
    --job-queue-name hybrid-fargate-queue \
    --state ENABLED \
    --priority 1 \
    --compute-environment-order order=1,computeEnvironment=fargate-ondemand-env \
                                order=2,computeEnvironment=fargate-spot-env
```

## ワークロードタイプ別のスケーリング戦略

### 小規模処理向けジョブ定義

Fargate では、ジョブ定義でリソース要件を指定することがスケーリングの核心です：

```bash
# 小規模処理用ジョブ定義
aws batch register-job-definition \
    --job-definition-name small-fargate-job \
    --type container \
    --platform-capabilities FARGATE \
    --container-properties '{
        "image": "your-repo/your-image:version",
        "command": ["process.sh", "--mode=small"],
        "resourceRequirements": [
            {"type": "VCPU", "value": "1"},
            {"type": "MEMORY", "value": "2048"}
        ],
        "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
        "jobRoleArn": "arn:aws:iam::account:role/BatchJobRole",
        "networkConfiguration": {
            "assignPublicIp": "ENABLED"
        }
    }'
```

### 大規模処理向けジョブ定義

```bash
# 大規模処理用ジョブ定義
aws batch register-job-definition \
    --job-definition-name large-fargate-job \
    --type container \
    --platform-capabilities FARGATE \
    --container-properties '{
        "image": "your-repo/your-image:version",
        "command": ["process.sh", "--mode=large"],
        "resourceRequirements": [
            {"type": "VCPU", "value": "4"},
            {"type": "MEMORY", "value": "16384"}
        ],
        "executionRoleArn": "arn:aws:iam::account:role/ecsTaskExecutionRole",
        "jobRoleArn": "arn:aws:iam::account:role/BatchJobRole",
        "networkConfiguration": {
            "assignPublicIp": "ENABLED"
        }
    }'
```

### Fargate の使用可能な vCPU とメモリの組み合わせ

Fargate では、以下の組み合わせのみが有効です：

| vCPU | メモリ（MiB）の選択肢                    |
| ---- | ---------------------------------------- |
| 0.25 | 512, 1024, 2048                          |
| 0.5  | 1024, 2048, 3072, 4096                   |
| 1    | 2048, 3072, 4096, 5120, 6144, 7168, 8192 |
| 2    | 4096 〜 16384（1024 単位で増加）         |
| 4    | 8192 〜 30720（1024 単位で増加）         |
| 8    | 16384 〜 61440（4096 単位で増加）        |
| 16   | 32768 〜 122880（8192 単位で増加）       |

**注意**: 最新の組み合わせは AWS ドキュメントで確認してください。

### ジョブキューの優先順位設定

ワークロードに応じたジョブキューの設定：

```bash
# オンデマンドFargateを使用するジョブキュー
aws batch create-job-queue \
    --job-queue-name fargate-queue \ # 名前を変更
    --state ENABLED \
    --priority 100 \ # 必要に応じて優先度を調整
    --compute-environment-order order=1,computeEnvironment=fargate-ondemand-env

# 標準ジョブ向けキュー（Fargate Spot優先）
aws batch create-job-queue \
    --job-queue-name standard-priority-queue \
    --state ENABLED \
    --priority 50 \
    --compute-environment-order order=1,computeEnvironment=fargate-spot-env \
                                order=2,computeEnvironment=fargate-ondemand-env
```

## モニタリングとチューニング

### 主要モニタリングメトリクス

Fargate のスケーリングパフォーマンスを監視するための主要メトリクス：

1. **AWS Batch メトリクス**:

   - `JobsSubmitted`: 送信されたジョブの数
   - `JobsPending`: 保留中のジョブの数
   - `JobsRunning`: 実行中のジョブの数
   - `JobsFailed`: 失敗したジョブの数

2. **Fargate リソース制限関連**:
   - リージョンごとの Fargate タスク数の制限
   - vCPU の合計使用量

### CloudWatch ダッシュボードの設定

```bash
aws cloudwatch put-dashboard \
    --dashboard-name FargateScalingDashboard \
    --dashboard-body file://fargate-dashboard.json
```

`fargate-dashboard.json`の例：

```json
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/Batch", "JobsSubmitted", "JobQueue", "your-fargate-queue"],
          [".", "JobsPending", ".", "."],
          [".", "JobsRunning", ".", "."],
          [".", "JobsFailed", ".", "."]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "your-region",
        "title": "Fargate Batch Job Metrics"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "AWS Batch Service"],
          [".", "MemoryUtilization", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "your-region",
        "title": "Fargate Resource Utilization"
      }
    }
  ]
}
```

## ベストプラクティス

### Fargate スケーリングのベストプラクティス

1. **適切なリソース要件の指定**

   - ジョブの実際のニーズに合わせて vCPU とメモリを指定
   - 過大なリソース割り当てを避ける
   - ジョブごとに適切なリソースプロファイルを作成

2. **Fargate Spot の活用**

   - 非重要または再試行可能なワークロードには Fargate Spot を使用
   - コスト削減効果は最大 70%
   - 中断耐性のあるジョブデザインを検討

3. **maxvCpus の最適化**

   - アカウントの制限とコスト管理を考慮して設定
   - 必要以上に高く設定しない
   - 定期的にスケーリング上限を見直す

4. **ネットワーク設定の最適化**

   - 複数のサブネットを指定して可用性を向上
   - VPC エンドポイントを使用してデータ転送コストを削減
   - 必要に応じて NAT ゲートウェイを設定

5. **ジョブ定義のバージョン管理**
   - リソース要件の異なるバージョンを作成
   - ワークロードパターンに応じて適切なバージョンを使用
   - 定期的にリソース要件を最適化

## まとめ

AWS Batch on Fargate は、サーバーレスアプローチにより管理オーバーヘッドを大幅に削減し、タスク単位の細かいスケーリングを実現します。適切なリソース要件の設定と、Fargate（オンデマンド）と Fargate Spot を組み合わせたハイブリッド戦略により、コストとパフォーマンスのバランスを取ったスケーリングが可能になります。

Fargate の主な利点は、インスタンス管理が不要なことと、タスク単位でリソースを正確に割り当てられることです。小規模処理と大規模処理の両方に対応するには、ジョブ定義で適切なリソース要件を指定し、優先度設定されたジョブキューを活用することが重要です。

定期的なモニタリングと最適化を行い、実際のワークロードパターンに基づいてスケーリング設定を調整することで、AWS Batch on Fargate の能力を最大限に活用できます。
