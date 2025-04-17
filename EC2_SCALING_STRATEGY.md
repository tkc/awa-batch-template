# AWS Batch シンプルスケーリング設定ガイド

## 目次
1. [はじめに](#はじめに)
2. [AWS Batchのスケーリングメカニズム](#aws-batchのスケーリングメカニズム)
3. [基本的なスケーリング設定](#基本的なスケーリング設定)
4. [ワークロードタイプ別のスケーリング戦略](#ワークロードタイプ別のスケーリング戦略)
5. [モニタリングとチューニング](#モニタリングとチューニング)
6. [ベストプラクティス](#ベストプラクティス)
7. [まとめ](#まとめ)

## はじめに

AWS Batchのスケーリング設定は、リソースの効率的な利用とコスト最適化を実現するために重要な要素です。本ドキュメントでは、小規模処理と大規模処理の両方に対応できる単一環境の基本的なスケーリング設定について解説します。

## AWS Batchのスケーリングメカニズム

AWS Batchは、以下の主要なパラメータを使用してスケーリングを制御します：

### コアスケーリングパラメータ

- **minvCpus**: コンピューティング環境が常に維持するvCPUの最小数
- **maxvCpus**: コンピューティング環境がスケールアップできるvCPUの最大数
- **desiredvCpus**: コンピューティング環境が目標とするvCPU数

### スケーリングの基本的な仕組み

1. **スケールアウト**：
   - ジョブキューにジョブが到着し、実行リソースが不足している場合
   - AWS Batchは自動的に新しいインスタンスを起動
   - ジョブ実行に必要なリソースが確保されるまでスケールアウト

2. **スケールイン**：
   - インスタンスがアイドル状態になるとスケールイン対象に
   - アイドル時間が一定期間続くとインスタンスが終了

## 基本的なスケーリング設定

### 単一環境の設定例

```bash
aws batch create-compute-environment \
    --compute-environment-name universal-compute-env \
    --type MANAGED \
    --state ENABLED \
    --compute-resources type=EC2,\
       allocationStrategy=SPOT_PRICE_CAPACITY_OPTIMIZED,\
       minvCpus=0,\
       maxvCpus=256,\
       desiredvCpus=0,\
       instanceTypes=t3.medium,t3.large,c5.large,c5.xlarge,c5.2xlarge,m5.large,m5.xlarge,r5.large,\
       subnets=subnet-xxx,subnet-yyy,\
       securityGroupIds=sg-zzz,\
       spotIamFleetRole=arn:aws:iam::account:role/AmazonEC2SpotFleetRole,\
       instanceRole=ecsInstanceRole \
    --service-role AWSServiceRoleForBatch
```

### アロケーション戦略の選択

| アロケーション戦略 | 説明 | 推奨ユースケース |
|-------------------|------|-----------------|
| `BEST_FIT_PROGRESSIVE` | コスト最適化を優先し、新しいインスタンスタイプも考慮 | コスト効率重視の汎用環境 |
| `SPOT_CAPACITY_OPTIMIZED` | 中断リスクが最も低いスポットを選択 | 長時間実行ジョブや中断に弱いワークロード |
| `SPOT_PRICE_CAPACITY_OPTIMIZED` | 価格と中断リスクのバランスを取る（推奨） | 多様なワークロードの混合環境 |

### インスタンスタイプの選択

幅広いワークロードに対応するためには、様々なサイズのインスタンスタイプを指定します：

**インスタンスタイプ選択のガイドライン**:
- **小規模処理用**: t3.medium, c5.large, m5.large
- **中規模処理用**: c5.xlarge, m5.xlarge, r5.large
- **大規模処理用**: c5.2xlarge, m5.2xlarge, r5.xlarge

## ワークロードタイプ別のスケーリング戦略

### 小規模処理向けスケーリング設定

```bash
# 小規模処理に最適化されたスケーリング設定
aws batch update-compute-environment \
    --compute-environment universal-compute-env \
    --compute-resources minvCpus=0,maxvCpus=128,instanceTypes=t3.medium,t3.large,c5.large,c5.xlarge
```

**特徴**:
- 小型インスタンスタイプを優先
- 迅速なスケールアウト/インを実現
- 多数の小規模ジョブを効率的に処理

### 大規模処理向けスケーリング設定

```bash
# 大規模処理に最適化されたスケーリング設定
aws batch update-compute-environment \
    --compute-environment universal-compute-env \
    --compute-resources minvCpus=8,maxvCpus=256,instanceTypes=c5.2xlarge,c5.4xlarge,m5.2xlarge,r5.xlarge
```

**特徴**:
- 大型インスタンスタイプを優先
- 最小vCPUを高めに設定して常にリソースを確保
- 長時間実行ジョブのためのリソース安定性を確保

### 混合ワークロード向けバランス設定

```bash
# 混合ワークロード向けのバランスの取れたスケーリング設定
aws batch update-compute-environment \
    --compute-environment universal-compute-env \
    --compute-resources minvCpus=4,maxvCpus=256,instanceTypes=t3.medium,c5.large,c5.xlarge,c5.2xlarge,m5.large,m5.xlarge
```

**特徴**:
- 多様なインスタンスタイプを使用
- 適度なminvCpus値でベースラインリソースを確保
- 様々なサイズのジョブに対応可能

## モニタリングとチューニング

### 主要モニタリングメトリクス

効果的なスケーリング設定のためには、以下のメトリクスを定期的に監視します：

1. **AWS Batchメトリクス**:
   - `JobsSubmitted`: 送信されたジョブの数
   - `JobsPending`: 保留中のジョブの数
   - `JobsRunning`: 実行中のジョブの数
   - `JobsFailed`: 失敗したジョブの数

2. **コンピューティング環境メトリクス**:
   - `CPUUtilization`: CPUの使用率
   - `MemoryUtilization`: メモリの使用率

3. **EC2メトリクス**:
   - `CPUReservation`: 予約されているCPUの割合
   - `MemoryReservation`: 予約されているメモリの割合

### CloudWatchダッシュボードの設定

CloudWatchダッシュボードを作成して、主要メトリクスを一元的に監視します：

```bash
aws cloudwatch put-dashboard \
    --dashboard-name BatchScalingDashboard \
    --dashboard-body file://batch-dashboard.json
```

`batch-dashboard.json`の例：

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
          [ "AWS/Batch", "JobsSubmitted", "JobQueue", "your-job-queue" ],
          [ ".", "JobsPending", ".", "." ],
          [ ".", "JobsRunning", ".", "." ],
          [ ".", "JobsFailed", ".", "." ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "your-region",
        "title": "Batch Job Metrics"
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
          [ "AWS/ECS", "CPUUtilization", "ClusterName", "your-batch-cluster" ],
          [ ".", "MemoryUtilization", ".", "." ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "your-region",
        "title": "Compute Resource Utilization"
      }
    }
  ]
}
```

## ベストプラクティス

### スケーリング設定のベストプラクティス

1. **適切なminvCpus設定**
   - 処理の緊急性に応じて調整
   - 0に設定すると完全なオンデマンドスケーリングが可能
   - 基本的なキャパシティを確保したい場合は適切な値を設定

2. **インスタンスタイプの多様化**
   - 適切なインスタンスファミリーを選択（計算集約型、メモリ最適化型など）
   - 複数のサイズを含めてジョブサイズに対応
   - スポットインスタンスの可用性向上のため複数のインスタンスタイプを指定

3. **maxvCpusの適切な設定**
   - 予算とワークロードに合わせて設定
   - 想定される最大同時実行数より余裕を持たせる
   - コスト管理としても機能

4. **スポットインスタンスの活用**
   - コスト削減のためスポットインスタンスを活用
   - 中断耐性のあるワークロードに最適
   - `SPOT_PRICE_CAPACITY_OPTIMIZED`を使用して中断リスクとコストのバランスを取る

5. **ジョブ定義の最適化**
   - ジョブのリソース要件を適切に指定（vCPU、メモリ）
   - 過大なリソース要求を避ける
   - コンテナの最適化（軽量イメージ、効率的なコード）

## まとめ

AWS Batchのスケーリング設定を適切に行うことで、小規模処理と大規模処理の両方を単一環境で効率的に処理できます。ワークロードの性質に合わせたインスタンスタイプの選択と、適切なvCPU設定が重要です。

このガイドで説明した基本的なスケーリング設定を適用し、定期的なモニタリングとチューニングを行うことで、コストとパフォーマンスのバランスが取れたAWS Batch環境を実現できます。実際のワークロードパターンに基づいて設定を調整し、継続的に最適化していくことをお勧めします。