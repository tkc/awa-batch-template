# AWS Batch Fargateジョブ送信ツール

このツールは、AWS Batch上でFargateタイプのジョブを簡単に送信するためのPythonスクリプトです。EC2タイプのジョブ送信と異なり、Fargate特有の設定（リソース要件やプラットフォームバージョンなど）にも対応しています。

## 特徴

- AWS Batch Fargateジョブ専用の送信ツール
- vCPUとメモリのリソース要件を柔軟に指定可能
- フェアシェアスケジューリングポリシーに対応
- ジョブ間の依存関係を設定可能
- 配列ジョブのサポート
- 環境変数やコマンドのオーバーライド機能
- ドライラン機能（実際に送信せず確認のみ）
- JSONファイルによるパラメータ設定のサポート

## 前提条件

- Python 3.6以降
- boto3ライブラリ
- AWS認証情報の設定（環境変数、AWSプロファイル、IAMロールなど）

## インストール

```bash
# 必要なライブラリをインストール
pip install boto3
```

## 使用方法

### 基本的な使用法

```bash
# 基本的な使用法
python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample
```

### リソース指定を使用する

```bash
# vCPUとメモリを指定
python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample --vcpu 1 --memory 2048
```

### 環境変数とコマンドを指定する

```bash
# 環境変数とコマンドをオーバーライド
python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority \
    --job-definition awa-batch-dev-fargate-sample \
    --command '["echo", "Hello World"]' \
    --environment '{"ENV1":"value1", "ENV2":"value2"}'
```

### フェアシェアスケジューリングを使用する

```bash
# シェア識別子と優先度を指定
python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority \
    --job-definition awa-batch-dev-fargate-sample \
    --share-identifier A1 \
    --scheduling-priority 10
```

### 配列ジョブを送信する

```bash
# 10個のタスクからなる配列ジョブを送信
python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority \
    --job-definition awa-batch-dev-fargate-sample \
    --array-size 10
```

### ドライランを実行する

```bash
# 実際に送信せずパラメータを確認
python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority \
    --job-definition awa-batch-dev-fargate-sample \
    --vcpu 2 --memory 4096 \
    --dry-run
```

### 依存ジョブを指定する

```bash
# 他のジョブの完了を待ってから実行
python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority \
    --job-definition awa-batch-dev-fargate-sample \
    --depends-on job-1234567890abcdef0,job-0fedcba0987654321
```

## パラメータリファレンス

| パラメータ | 説明 | デフォルト |
|------------|------|------------|
| `--job-name-prefix` | ジョブ名のプレフィックス | `fargate-job` |
| `--job-queue` | 使用するジョブキュー | `awa-batch-dev-fargate-high-priority` |
| `--job-definition` | 使用するジョブ定義 | `awa-batch-dev-fargate-sample` |
| `--region` | AWSリージョン | `ap-northeast-1` |
| `--vcpu` | Fargateタスクに割り当てるvCPUの数 | ジョブ定義による |
| `--memory` | Fargateタスクに割り当てるメモリのMB数 | ジョブ定義による |
| `--platform-version` | Fargateプラットフォームバージョン（注：ジョブ定義レベルでしか設定できません） | `LATEST` |
| `--share-identifier` | フェアシェアスケジューリングのシェア識別子 | なし |
| `--scheduling-priority` | スケジューリング優先度 | `0` |
| `--command` | 実行するコマンド（JSON配列形式） | ジョブ定義による |
| `--environment` | 環境変数（JSON形式） | ジョブ定義による |
| `--parameters-file` | ジョブパラメータを含むJSONファイルのパス | なし |
| `--container-overrides-file` | コンテナオーバーライド設定を含むJSONファイルのパス | なし |
| `--tags` | ジョブに付けるタグ（JSON形式） | なし |
| `--depends-on` | 依存ジョブのIDをカンマ区切りで指定 | なし |
| `--array-size` | 配列ジョブのサイズ | なし |
| `--dry-run` | 実際にジョブを送信せずパラメータを表示のみ | `false` |

## 環境変数による設定

以下の環境変数を使用することで、コマンドライン引数を省略できます：

- `AWS_BATCH_JOB_NAME_PREFIX` - ジョブ名のプレフィックス
- `AWS_BATCH_JOB_QUEUE` - ジョブキュー名
- `AWS_BATCH_JOB_DEFINITION` - ジョブ定義名
- `AWS_REGION` - AWSリージョン
- `AWS_BATCH_SHARE_IDENTIFIER` - シェア識別子
- `AWS_BATCH_SCHEDULING_PRIORITY` - スケジューリング優先度

## EC2とFargateの違い

AWS BatchのFargateコンピューティング環境とEC2コンピューティング環境には以下のような違いがあります：

### Fargate固有の特徴

1. **コンテナ化のみ**：Fargateはコンテナベースのみをサポート
2. **リソース指定方法の違い**：Fargateでは`resourceRequirements`を使用
3. **プラットフォームバージョン**：Fargateでは`platformVersion`の指定が必要（ジョブ定義レベルで設定）
4. **ネットワーク設定**：Fargateでは`networkConfiguration`が必要
5. **サポートされるvCPU/メモリ値に制限**：Fargateは特定の組み合わせのみをサポート

> **重要**: Fargateのプラットフォームバージョンは、ジョブ定義の作成時に指定する必要があります。ジョブ送信時にはコンテナオーバーライドとしてプラットフォームバージョンを指定することはできません。

### サポートされるFargateのvCPU/メモリ組み合わせ

| vCPU値 | サポートされるメモリ範囲 (MB) |
|--------|---------------------------|
| 0.25   | 512, 1024, 2048           |
| 0.5    | 1024, 2048, 3072, 4096    |
| 1      | 2048, 3072, 4096, 5120, 6144, 7168, 8192 |
| 2      | 4096〜16384 (1024単位)     |
| 4      | 8192〜30720 (1024単位)     |
| 8      | 16384〜61440 (4096単位)    |
| 16     | 32768〜122880 (8192単位)   |

## エラーハンドリング

スクリプトは以下のような場合にエラーを出力し、非ゼロの終了コードで終了します：

- AWS認証情報が不正または不足している
- 指定されたJSONファイルが見つからない、または形式が不正
- ジョブ送信時にAWS Batchサービスからエラーが返される
- リソース要件が無効な値の場合（サポートされない組み合わせ）

## ベストプラクティス

1. **適切なリソース指定**：Fargateでは、タスクに必要な最小限のリソースを指定することでコスト最適化を図れます
2. **タグの活用**：課金やモニタリングのために、適切なタグをジョブに設定しましょう
3. **バッチ処理の最適化**：可能な限り配列ジョブを使用し、大量のジョブを効率的に処理しましょう
4. **セキュリティ設定**：最小権限の原則に従い、ジョブ定義に適切なIAMロールを設定しましょう
5. **コスト最適化**：低優先度のタスクにはFargate Spotを使用し、コストを最大60%削減できます

## トラブルシューティング

### よくあるエラーと解決方法

1. **"AccessDeniedException"**
   - 原因: IAM権限の不足
   - 解決: ジョブ実行ロールとタスク実行ロールの権限を確認

2. **"INVALID"コンピューティング環境**
   - 原因: サービスロール権限の不足、VPC設定の問題
   - 解決: AWSBatchServiceRoleポリシーの適用を確認、VPCエンドポイントの設定を確認

3. **"InvalidParameterValue" (vCPU/メモリ)**
   - 原因: サポートされていないvCPUとメモリの組み合わせ
   - 解決: サポートされている組み合わせのみを使用（上記テーブル参照）

4. **VPCエンドポイント関連の接続エラー**
   - 原因: プライベートサブネット内でECRやその他のAWSサービスに接続できない
   - 解決: 必要なVPCエンドポイント(ECR, S3, CloudWatch Logs)の設定を確認
