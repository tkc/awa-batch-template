# AWS Batch ジョブ送信ツール

## submit_job.py

この Python スクリプトは、AWS Batch ジョブを簡単に送信するためのツールです。特にフェアシェアスケジューリングポリシーが設定されたジョブキューに対応しています。

### 使用方法

```bash
# 基本的なジョブ送信（デフォルト設定で実行）
python submit_job.py

# 異なるジョブキューにジョブを送信
python submit_job.py --job-queue awa-batch-dev-low-priority

# シェア識別子を指定してジョブを送信
python submit_job.py --share-identifier team-a

# 優先度を指定してジョブを送信
python submit_job.py --scheduling-priority 10

# パラメータファイルを指定してジョブを送信
python submit_job.py --parameters-file sample_params.json

# 複数のオプションを組み合わせる
python submit_job.py --job-queue awa-batch-dev-low-priority --share-identifier team-b --scheduling-priority 5 --parameters-file custom_params.json
```

### パラメータ一覧

| パラメータ            | 説明                                       | デフォルト値                |
| --------------------- | ------------------------------------------ | --------------------------- |
| --job-name-prefix     | ジョブ名のプレフィックス                   | my-batch-job                |
| --job-queue           | 使用するジョブキュー                       | awa-batch-dev-high-priority |
| --job-definition      | 使用するジョブ定義                         | awa-batch-dev-sample1       |
| --share-identifier    | フェアシェア識別子                         | default                     |
| --scheduling-priority | スケジューリング優先度                     | 0                           |
| --parameters-file     | ジョブパラメータを含む JSON ファイルのパス | なし                        |

### シェア識別子について

`--share-identifier` パラメータは、フェアシェアスケジューリングポリシーが設定されたジョブキューでジョブを実行する際に必須となるパラメータです。このパラメータにより：

- 複数のユーザーやチーム間でバッチリソースを公平に共有できます
- 各シェアグループのリソース使用量が追跡され、時間の経過とともに公平に配分されます
- 同じシェア識別子を持つジョブは同じグループとして扱われます

デフォルト値は「default」に設定されていますが、必要に応じてチームやプロジェクト名など、より具体的な識別子を指定できます。

### ジョブパラメータファイルの指定

`--parameters-file` オプションを使用すると、JSON ファイルからジョブパラメータを読み込むことができます。これにより複雑なパラメータセットを簡単に管理できます。

#### パラメータファイルの例 (sample_params.json)

```json
{
  "input_file": "s3://my-bucket/data.csv",
  "output_path": "s3://my-bucket/results/",
  "debug_mode": "true",
  "max_retry": "3"
}
```

このファイルを使用してジョブを実行するには：

```bash
python submit_job.py --parameters-file sample_params.json
```

指定したパラメータは、コンテナ内で環境変数としてアクセスできます。これにより、同じコンテナイメージを使用しながら、実行時に異なる設定やデータを処理することが可能になります。

#### 注意点：

- JSON ファイル形式が正しくない場合はエラーになります
- ファイルが存在しない場合もエラーになります
- パラメータは文字列としてコンテナに渡されるため、必要に応じてコンテナ内で型変換を行ってください

### 実行例と出力

```
ジョブをサブミット中...
  ジョブ定義: awa-batch-dev-sample1
  ジョブキュー: awa-batch-dev-high-priority
  ジョブ名: my-batch-job-20250411121937
  シェア識別子: default
  スケジューリング優先度: 0
  パラメータファイル: sample_params.json
ジョブサブミット成功: ジョブID = 16450d46-ef5d-4e7a-8f1f-55bec7ac6afc
```

## AWS Batch 確認用コマンド

ジョブの送信後、以下のコマンドを使用して AWS Batch の状態を確認できます。

### ジョブ関連

```bash
# 特定のジョブの詳細を確認
aws batch describe-jobs --jobs <job-id> --region ap-northeast-1

# ジョブのステータスのみを取得
aws batch describe-jobs --jobs <job-id> --region ap-northeast-1 --query 'jobs[0].status'

# ジョブの終了コードを取得（失敗時に原因調査に役立つ）
aws batch describe-jobs --jobs <job-id> --region ap-northeast-1 --query 'jobs[0].container.exitCode'

# ジョブの最新のステータス理由を確認
aws batch describe-jobs --jobs <job-id> --region ap-northeast-1 --query 'jobs[0].statusReason'

# ジョブの試行履歴を確認 (リトライ情報を含む)
aws batch describe-jobs --jobs <job-id> --region ap-northeast-1 --query 'jobs[0].attempts'

# ジョブのログストリーム名を取得 (CloudWatch Logsで確認するため)
aws batch describe-jobs --jobs <job-id> --region ap-northeast-1 --query 'jobs[0].container.logStreamName'
```

### ジョブキュー関連

```bash
# すべてのジョブキューを一覧表示
aws batch describe-job-queues --region ap-northeast-1

# 特定のジョブキューの詳細を確認
aws batch describe-job-queues --job-queues awa-batch-dev-high-priority --region ap-northeast-1

# ジョブキュー内のジョブを一覧表示（RUNNING状態）
aws batch list-jobs --job-queue awa-batch-dev-high-priority --job-status RUNNING --region ap-northeast-1

# ジョブキュー内のジョブを一覧表示（SUCCEEDED状態）
aws batch list-jobs --job-queue awa-batch-dev-high-priority --job-status SUCCEEDED --region ap-northeast-1

# ジョブキュー内のジョブを一覧表示（FAILED状態）
aws batch list-jobs --job-queue awa-batch-dev-high-priority --job-status FAILED --region ap-northeast-1

# ジョブキュー内のジョブを一覧表示（SUBMITTED状態）
aws batch list-jobs --job-queue awa-batch-dev-high-priority --job-status SUBMITTED --region ap-northeast-1
```

### コンピューティング環境関連

```bash
# すべてのコンピューティング環境を一覧表示
aws batch describe-compute-environments --region ap-northeast-1

# 特定のコンピューティング環境の詳細を確認
aws batch describe-compute-environments --compute-environments awa-batch-dev-on-demand --region ap-northeast-1

# コンピューティング環境のステータスを確認
aws batch describe-compute-environments --compute-environments awa-batch-dev-on-demand --region ap-northeast-1 --query 'computeEnvironments[0].status'

# コンピューティング環境のステータス理由を確認 (エラー時)
aws batch describe-compute-environments --compute-environments awa-batch-dev-on-demand --region ap-northeast-1 --query 'computeEnvironments[0].statusReason'
```

### ジョブ定義関連

```bash
# すべてのジョブ定義を一覧表示
aws batch describe-job-definitions --region ap-northeast-1

# 特定のジョブ定義の詳細を確認
aws batch describe-job-definitions --job-definitions awa-batch-dev-sample1 --region ap-northeast-1

# 特定のジョブ定義の最新リビジョンのみを確認
aws batch describe-job-definitions --job-definitions awa-batch-dev-sample1 --status ACTIVE --region ap-northeast-1
```

### CloudWatch Logs 関連

```bash
# ジョブのログを確認 (ログストリーム名が必要)
LOG_STREAM=$(aws batch describe-jobs --jobs <job-id> --region ap-northeast-1 --query 'jobs[0].container.logStreamName' --output text)
aws logs get-log-events --log-group-name /aws/batch/awa-batch-dev --log-stream-name $LOG_STREAM --region ap-northeast-1

# 最新の50行のログを取得
aws logs get-log-events --log-group-name /aws/batch/awa-batch-dev --log-stream-name $LOG_STREAM --limit 50 --region ap-northeast-1 --query 'events[*].message'
```

### スケジューリングポリシー関連

```bash
# すべてのスケジューリングポリシーを一覧表示
aws batch describe-scheduling-policies --region ap-northeast-1

# 特定のスケジューリングポリシーの詳細を確認
aws batch describe-scheduling-policies --arns <スケジューリングポリシーARN> --region ap-northeast-1
```

これらのコマンドを使用して、AWS Batch ジョブの実行状況を確認し、問題が発生した場合のトラブルシューティングに役立てることができます。

### 注意事項

- 適切な AWS 認証情報が設定されていることを確認してください
- フェアシェアスケジューリングポリシーが有効な環境では、必ずシェア識別子を指定する必要があります
- 環境に応じてリージョン（`ap-northeast-1`）とリソース名を適切に変更してください
