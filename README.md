# AWS Batch Template

AWS Batch を使用したデータ処理パイプラインのテンプレートプロジェクトです。Terraform を使用してインフラを構築し、Poetry で依存関係を管理しています。pydantic-settings を使用して環境変数や設定を柔軟に扱い、Pandas と Pandera を使用して CSV データのバリデーションと処理を行います。GitHub Actions による自動デプロイ機能も備えています。

## 機能

- サンプル CSV 処理コマンド（sample1）
- Pandera を使用した強力なデータバリデーション
- Pandas を利用したデータ処理と分析
- AWS Batch によるジョブ実行
- Terraform によるインフラのコード化
- Docker + ECR によるコンテナ化
- Poetry による依存関係管理
- pydantic-settings による設定管理
- GitHub Actions による自動デプロイ

## プロジェクト構造

```
/
├── .github/                        # GitHub関連
│   └── workflows/                  # GitHub Actions設定
│       └── deploy-on-release.yml   # リリース時デプロイワークフロー
├── README.md                       # プロジェクト説明
├── .gitignore                      # Gitの除外ファイル設定
├── .env.sample                     # 環境変数サンプル
├── pyproject.toml                  # Poetry設定
├── Dockerfile                      # Dockerイメージ定義
├── samples/                        # サンプルCSVファイル
│   └── sample1_data.csv            # 学生データ (サンプル)
├── src/                            # アプリケーションコード (パッケージ)
│   ├── cli.py                  # ローカル実行用CLI
│   ├── batch_cli.py            # AWS Batch実行用CLI
│   ├── main.py                 # 各サンプル処理のコアロジック
│   ├── config.py               # 設定読み込みロジック
│   ├── models.py               # Pydanticモデル定義
│   ├── schemas.py              # Panderaスキーマ定義
│   ├── logger_config.py        # ロガー設定
│   └── requirements.txt        # Dockerイメージ用 (poetry export)
├── terraform/                      # Terraform構成ファイル
│   ├── main.tf                     # メインのTerraform設定
│   ├── variables.tf                # 変数定義
│   ├── outputs.tf                  # 出力定義
│   ├── vpc.tf                      # VPC設定
│   ├── batch_main.tf               # AWS Batch共通設定
│   ├── batch_sample1.tf            # Sample1ジョブ定義 (例)
│   ├── ecr.tf                      # ECRリポジトリ設定
│   ├── s3.tf                       # S3バケット設定
└── scripts/                        # デプロイ関連スクリプト
    ├── build.sh                    # Dockerイメージビルドスクリプト
    └── deploy.sh                   # デプロイスクリプト
```

## サンプル CSV データの処理

このテンプレートにはサンプル CSV 処理コマンド `sample1` が含まれています：

1. **sample1**: 学生データの処理
   - CSV の形式: ID, 名前, 年齢, スコア
   - 処理内容: 基本的な統計情報の計算（平均スコア、最高スコア、最低スコア）など (現在はバリデーションのみ)

### Pandera によるデータバリデーション

`sample1` コマンドでは、Pandera を使用してデータを検証しています。Pandera はデータフレームのスキーマ検証を行うライブラリで、以下のような検証を実施しています：

- 列の型チェック（整数、文字列、浮動小数点など）
- 値の範囲チェック（最小値、最大値）
- カスタムバリデーションルール（合計値のチェックなど）

スキーマは `src/schemas.py` で定義されています。

## セットアップ手順

### 前提条件

- AWS CLI
- Terraform
- Docker
- Poetry（Python パッケージ管理）

### インフラのセットアップ

1. Terraform の初期化

```bash
cd terraform
terraform init
```

2. リソースの作成

```bash
terraform apply
```

### アプリケーションのビルドとデプロイ

#### 手動デプロイ

1. ローカルで Docker イメージをビルド

```bash
./scripts/build.sh
```

2. ECR にイメージをプッシュ

```bash
./scripts/deploy.sh
```

#### GitHub Actions による自動デプロイ

このリポジトリには、GitHub Release を作成すると自動的に ECR にイメージをデプロイするワークフローが含まれています。

設定手順:

1. GitHub リポジトリにシークレットを追加:

   - `AWS_ACCESS_KEY_ID`: AWS アクセスキー ID
   - `AWS_SECRET_ACCESS_KEY`: AWS シークレットアクセスキー

   注: 使用する IAM ユーザーには、ECR、Batch、S3 などへのアクセス権限が必要です。

2. リリースの作成:

   - GitHub リポジトリで「Releases」タブに移動
   - 「Draft a new release」をクリック
   - タグバージョンとリリースタイトルを入力
   - 「Publish release」をクリック

3. 自動デプロイの進捗:
   - リリースの作成後、GitHub Actions タブでワークフローの進捗を確認できます
   - ワークフローは Terraform の適用と ECR へのイメージのデプロイを自動的に行います

## 利用方法

### AWS Batch ジョブの実行

AWS Management Console または AWS CLI を使用してジョブを実行できます。パラメータは **JSON 形式** で渡します。

CLI での実行例 (環境変数を使用):

```bash
# sample1 を実行
aws batch submit-job \
    --job-name "sample1-test-cli" \
    --job-queue "your-job-queue-name" \
    --job-definition "your-batch-cli-job-definition" \
    --container-overrides '{"command":["poetry", "run", "batch-cli", "sample1"],"environment":[{"name":"INPUT_PATH","value":"s3://your-bucket/input/sample1_data.csv"},{"name":"OUTPUT_PATH","value":"s3://your-bucket/output/sample1.csv"},{"name":"MIN_SCORE","value":"70"}]}'

```

_`your-job-queue-name` と `your-batch-cli-job-definition` は実際の環境に合わせてください。_
_`your-batch-cli-job-definition` は `poetry run batch-cli sample1` を実行するように設定します。_

### ローカルでのテスト実行

Poetry を使用してローカルで直接実行するか、Docker を使用してコンテナ内でテストできます。

#### Poetry での実行 (`cli` コマンド)

パラメータは、`--config_file` オプションで JSON ファイルを指定します。

```bash
# 依存関係のインストール
poetry install

# sample1: 設定ファイルで実行
poetry run cli sample1 --config_file=samples/params_sample1.json
```

#### Docker での実行 (`cli` コマンド)

パラメータは、`--config_file` オプションでマウントした JSON ファイルのパスを指定します。

```bash
# イメージのビルド (初回のみ)
./scripts/build.sh

# sample1: 設定ファイルで実行
docker run --rm -v $(pwd)/samples:/app/samples -v $(pwd)/output:/app/output awa-batch-template:latest cli sample1 --config_file=samples/params_sample1.json
```

_出力ディレクトリ (`output`) もマウントしています。_

## 設定管理

このプロジェクトでは、pydantic-settings を使用して設定を管理しています。設定は以下の方法で指定できます:

1. 環境変数
2. .env ファイル
3. コマンドライン引数

優先順位:
コマンドライン引数 > 環境変数 > .env ファイル > デフォルト値

### .env ファイルの使用

開発環境では、`.env`ファイルを使用できます:

```bash
cp .env.sample .env
# .envファイルを編集して設定を行う
```
