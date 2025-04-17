# AWS Batchコンテナーバージョン更新ガイド
**既存環境を維持しながら安全に移行するための手順**

## 目次
1. [はじめに](#はじめに)
2. [ブルー/グリーンデプロイメント方式の概要](#ブルーグリーンデプロイメント方式の概要)
3. [EC2コンピューティング環境の更新手順](#ec2コンピューティング環境の更新手順)
4. [Fargateコンピューティング環境の更新手順](#fargateコンピューティング環境の更新手順)
5. [移行のベストプラクティス](#移行のベストプラクティス)
6. [トラブルシューティング](#トラブルシューティング)
7. [まとめ](#まとめ)

## はじめに

AWS Batchのコンテナーバージョンを更新する際に、既存の環境をすぐに削除せず、安全に移行するための方法をこのドキュメントで説明します。本ガイドでは、主にブルー/グリーンデプロイメント方式を採用した移行手順について詳細を解説します。

## ブルー/グリーンデプロイメント方式の概要

ブルー/グリーンデプロイメントは、同時に2つの環境を運用し、トラフィックを徐々に移行させることで、リスクを最小限に抑えながらアプリケーションを更新する手法です。

- **ブルー環境**: 現在運用中の既存環境
- **グリーン環境**: 新しいコンテナーバージョンを導入した新環境

この方式の主なメリット:
- ダウンタイムなしで更新が可能
- 問題発生時に素早くロールバックできる
- 新旧環境を並行運用して安全に検証できる

## EC2コンピューティング環境の更新手順

### 1. 新しいコンピューティング環境の作成

```bash
aws batch create-compute-environment \
    --compute-environment-name Production-NewVersion \
    --type MANAGED \
    --state ENABLED \
    --service-role AWSServiceRoleForBatch \
    --compute-resources type=EC2,allocationStrategy=SPOT_CAPACITY_OPTIMIZED,minvCpus=0,maxvCpus=256,instanceTypes=c5,c5n,m5,r5,subnets=subnet-xxx,subnet-yyy,securityGroupIds=sg-zzz,instanceRole=ecsInstanceRole
```

重要なパラメータ:
- `compute-environment-name`: 新環境の名前（バージョンや日付を含めると管理しやすい）
- `allocationStrategy`: BEST_FIT_PROGRESSIVE、SPOT_CAPACITY_OPTIMIZED、またはSPOT_PRICE_CAPACITY_OPTIMIZEDを推奨
- 他のパラメーターは既存環境と合わせるが、新しいコンテナーバージョンを使用するよう設定

### 2. ジョブキューへの新環境の追加

```bash
aws batch update-job-queue \
    --job-queue YourJobQueue \
    --compute-environment-order order=1,computeEnvironment=Production-NewVersion order=2,computeEnvironment=Production-OldVersion
```

新環境を優先度の高い位置（順序値が小さい）に配置することがポイントです。これにより、新しいジョブは新環境で実行されるようになります。

### 3. 移行のモニタリングと検証

新環境が問題なく動作していることを確認するために以下を実施します:

- テストジョブの実行と結果の確認
- 処理性能のモニタリング
- ログの確認
- 必要に応じてAmazon CloudWatchのメトリクスを確認

### 4. 完全移行と古い環境の削除

新環境の安定稼働を確認できたら、古い環境を削除します:

```bash
# ジョブキューから古い環境を削除
aws batch update-job-queue \
    --job-queue YourJobQueue \
    --compute-environment-order order=1,computeEnvironment=Production-NewVersion

# 古い環境を無効化
aws batch update-compute-environment \
    --compute-environment Production-OldVersion \
    --state DISABLED

# 全てのジョブが終了したことを確認後、完全に削除
aws batch delete-compute-environment \
    --compute-environment Production-OldVersion
```

### 5. ロールバック計画

問題が発生した場合に備えて、以下のロールバック手順を用意しておきます:

```bash
# 環境の優先順位を元に戻す
aws batch update-job-queue \
    --job-queue YourJobQueue \
    --compute-environment-order order=1,computeEnvironment=Production-OldVersion order=2,computeEnvironment=Production-NewVersion
```

## Fargateコンピューティング環境の更新手順

### 1. 新しいFargateコンピューティング環境の作成

```bash
aws batch create-compute-environment \
    --compute-environment-name Fargate-NewVersion \
    --type MANAGED \
    --state ENABLED \
    --service-role AWSServiceRoleForBatch \
    --compute-resources type=FARGATE,maxvCpus=256,subnets=subnet-xxx,subnet-yyy,securityGroupIds=sg-zzz
```

Fargate特有の設定:
- `type=FARGATE`を指定
- AMI IDやインスタンスタイプの指定が不要
- コスト最適化のために`FARGATE_SPOT`も選択可能

### 2. 新しいジョブ定義の作成

Fargateでは、新しいコンテナイメージを使用するために新しいジョブ定義が必要です:

```bash
aws batch register-job-definition \
    --job-definition-name YourJobDefinition-NewVersion \
    --type container \
    --platform-capabilities FARGATE \
    --container-properties file://container-properties.json
```

container-properties.jsonの例:

```json
{
  "image": "your-container-registry/your-image:new-version",
  "resourceRequirements": [
    {"type": "VCPU", "value": "1"},
    {"type": "MEMORY", "value": "2048"}
  ],
  "executionRoleArn": "arn:aws:iam::your-account:role/ecsTaskExecutionRole",
  "networkConfiguration": {
    "assignPublicIp": "ENABLED"
  },
  "fargatePlatformConfiguration": {
    "platformVersion": "LATEST"
  }
}
```

### 3. ジョブキューへの新環境の追加

EC2環境と同様に新しいFargate環境をジョブキューに追加します:

```bash
aws batch update-job-queue \
    --job-queue YourJobQueue \
    --compute-environment-order order=1,computeEnvironment=Fargate-NewVersion order=2,computeEnvironment=Fargate-OldVersion
```

### 4. テストとモニタリング

新しい環境でテストジョブを実行し、正常に動作するか確認します:

```bash
aws batch submit-job \
    --job-name TestJob \
    --job-queue YourJobQueue \
    --job-definition YourJobDefinition-NewVersion
```

### 5. 移行完了後のクリーンアップ

EC2環境と同様に、安定稼働を確認した後に古い環境を削除します:

```bash
# ジョブキューから古い環境を削除
aws batch update-job-queue \
    --job-queue YourJobQueue \
    --compute-environment-order order=1,computeEnvironment=Fargate-NewVersion

# 古い環境を無効化→削除
aws batch update-compute-environment \
    --compute-environment Fargate-OldVersion \
    --state DISABLED

aws batch delete-compute-environment \
    --compute-environment Fargate-OldVersion
```

## 移行のベストプラクティス

1. **十分な検証期間の確保**
   - 両環境を並行運用して新環境を十分にテストする
   - 本番ワークロードの一部を段階的に移行する

2. **リソース計画**
   - 移行期間中は両環境のリソースが必要なため、十分なキャパシティを確保
   - コスト増加を考慮した予算計画

3. **監視とアラート**
   - 新環境の監視体制を強化
   - 問題検出のための適切なアラートを設定

4. **ドキュメント整備**
   - 環境設定の詳細を記録
   - 移行手順とロールバック手順を明確に文書化

5. **段階的移行**
   - 重要度の低いジョブから移行を開始
   - 安定性を確認しながら徐々に重要なジョブを移行

## トラブルシューティング

### 一般的な問題と解決策

1. **新環境でジョブが失敗する場合**
   - ジョブ定義とコンテナイメージの互換性を確認
   - IAMロールと権限設定を確認
   - CloudWatchログで詳細なエラーを確認

2. **パフォーマンス低下が見られる場合**
   - リソース設定を見直す
   - スケーリング設定を調整
   - インスタンスタイプを最適化

3. **環境の削除ができない場合**
   - 関連するジョブキューとの依存関係を確認
   - 実行中のジョブが完全に終了するまで待機

## まとめ

AWS Batchのコンテナーバージョン更新は、ブルー/グリーンデプロイメント方式を採用することで、既存環境を維持しながら安全に実施できます。この方法では、新旧環境を並行運用してリスクを最小化し、問題発生時には迅速にロールバックできる柔軟性を確保できます。

本ガイドで説明した手順に従うことで、EC2およびFargateコンピューティング環境の安全な更新が可能となります。環境の特性に合わせて手順をカスタマイズし、十分な検証を行うことで、スムーズな移行を実現してください。