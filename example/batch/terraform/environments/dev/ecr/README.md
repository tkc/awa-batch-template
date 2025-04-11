# AWS ECRリポジトリの作成

このディレクトリには、AWS Batch用のDockerイメージを保存するためのECRリポジトリを作成するTerraformコードが含まれています。

## 作成されるリソース

以下のECRリポジトリが作成されます：

- `awa-batch-dev-batch` - AWS Batchジョブ用のイメージリポジトリ

このリポジトリには以下の設定が適用されます：

- タグの上書きが可能（MUTABLE）
- イメージプッシュ時に自動スキャン有効
- AES256暗号化
- 30日以上経過したイメージは最新10個を残して自動削除するライフサイクルポリシー

## 使用方法

### 初期化

```bash
terraform init
```

### プラン確認

```bash
terraform plan
```

### リソース作成

```bash
terraform apply
```

確認メッセージが表示されたら、`yes`と入力してリソースを作成します。

### リソース削除

```bash
terraform destroy
```

## ECRリポジトリへのイメージプッシュ

作成されたリポジトリにイメージをプッシュするには、以下のコマンドを実行します。

```bash
# リポジトリURLの取得
REPO_URL=$(terraform output -raw repository_url)

# AWS ECRログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(echo $REPO_URL | cut -d '/' -f 1)

# イメージタグ付け
docker tag your-image:latest $REPO_URL:latest

# イメージプッシュ
docker push $REPO_URL:latest
```

## タグ付けの方針

以下のようなタグ付け方針を推奨します：

- `latest` - 最新の安定版
- `vX.Y.Z` - セマンティックバージョニングによるタグ（例：v1.2.3）
- `dev` - 開発版
- `YYYYMMDD` - 日付ベースのタグ（例：20250411）

## 注意事項

- このTerraformスクリプトはローカルバックエンド（`backend.tf`）を使用しています。本番環境では、S3バックエンドなどのリモートバックエンドを使用することを推奨します。
- 必要に応じて、`variables.tf`を編集して、プロジェクト名、環境名、AWSリージョンを変更できます。
