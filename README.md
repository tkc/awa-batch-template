# AWS データ処理パイプラインテンプレート

このリポジトリは、AWS 上でデータ処理パイプラインを構築するためのテンプレートプロジェクトです。AWS Batch と SageMaker Pipeline の両方の実行環境に対応しています。

Terraform を使用してインフラを構築し、Poetry で依存関係を管理しています。pydantic-settings を使用して環境変数や設定を柔軟に扱い、Pandas と Pandera を使用して CSV データのバリデーションと処理を行います。

## 機能

- サンプル CSV 処理コマンド (`sample1`)
- Pandera を使用した強力なデータバリデーション
- Pandas を利用したデータ処理と分析
- **AWS Batch** によるジョブ実行
- **SageMaker Pipeline** による複数ステップのワークフロー実行
- Terraform によるインフラのコード化
- Docker + ECR によるコンテナ化
- Poetry による依存関係管理
- pydantic-settings による設定管理
- リファクタリングされた明確なディレクトリ構造

## プロジェクト構造

```
/
├── .github/                       # GitHub関連ファイル
├── infra/                         # インフラストラクチャ関連コード
│   ├── batch/                     # AWS Batch関連
│   │   ├── docker/                # AWS Batch用Dockerファイル
│   │   │   └── Dockerfile         # AWS Batch用Dockerイメージ定義
│   │   ├── src/                   # AWS Batch実行用ソースコード
│   │   │   ├── pyproject.toml     # Batch専用の依存関係
│   │   │   └── run_batch.py       # AWS Batch実行用スクリプト
│   │   └── terraform/             # AWS Batch用Terraformコード
│   └── sagemaker/                 # SageMaker Pipeline関連
│       ├── docker/                # SageMaker用Dockerファイル
│       │   └── Dockerfile         # SageMaker Pipeline用Dockerイメージ定義
│       └── src/                   # SageMaker実行用ソースコード
│           ├── pyproject.toml     # SageMaker専用の依存関係
│           ├── pipeline.py        # SageMaker Pipeline定義
│           └── run_all_samples.py # 複数のサンプル実行用スクリプト
├── samples/                       # サンプルデータファイル
│   └── sample1_data.csv           # 学生データ (サンプル)
├── scripts/                       # ユーティリティスクリプト
├── src/                           # アプリケーションコア
│   ├── cli.py                     # コマンドラインインターフェース
│   ├── config.py                  # 設定管理
│   ├── logger_config.py           # ロギング設定
│   ├── main.py                    # メイン処理ロジック
│   ├── models.py                  # Pydanticモデル定義
│   ├── requirements.txt           # Docker用依存関係リスト
│   └── schemas.py                 # Panderaスキーマ定義
├── tests/                         # テストコード
├── .env.sample                    # 環境変数サンプル
├── Develop.md                     # 開発ガイド
├── poetry.lock                    # Poetryロックファイル
├── pyproject.toml                 # Poetryプロジェクト設定
└── README.md                      # このファイル
```

## 主要コンポーネント

### コアアプリケーション (`src/`)

- **cli.py**: コマンドラインインターフェース（ローカル実行用）
- **main.py**: データ処理のコアロジック
- **models.py**: Pydanticを使用したデータモデル定義
- **schemas.py**: Panderaを使用したデータ検証スキーマ
- **config.py**: 設定読み込みロジック
- **logger_config.py**: 構造化ロギング設定

### AWS Batch (`infra/batch/`)

AWS Batch環境でPythonスクリプトを実行するためのコンポーネント：

- **docker/Dockerfile**: AWS Batch用のDockerイメージ定義
- **src/run_batch.py**: AWS Batch実行用のエントリーポイント
- **terraform/**: AWS Batch環境をTerraformで定義

### SageMaker Pipeline (`infra/sagemaker/`)

SageMaker Pipelineを使用したワークフローを構築するためのコンポーネント：

- **docker/Dockerfile**: SageMaker Pipeline用のDockerイメージ定義
- **src/pipeline.py**: SageMaker Pipelineの定義
- **src/run_all_samples.py**: 複数のサンプル処理を順次実行するスクリプト

## 実行環境

このプロジェクトは、以下の環境で実行できます：

### 1. ローカル環境 (`src/cli.py`)

開発やテスト目的に最適。`poetry`を使用して依存関係をインストールし、コマンドラインから直接実行します。

```bash
# 依存関係のインストール
poetry install

# サンプルコマンドの実行
poetry run cli sample1 --config_file=path/to/config.json
```

### 2. AWS Batch (`infra/batch/`)

大規模な分散バッチ処理に適しています。

```bash
# Dockerイメージのビルドとプッシュ
cd infra/batch
docker build -t your-repo/batch-image:latest -f docker/Dockerfile .
docker push your-repo/batch-image:latest

# Terraform でインフラをデプロイ
cd terraform
terraform init
terraform apply
```

### 3. SageMaker Pipeline (`infra/sagemaker/`)

機械学習ワークフローや複数ステップの処理パイプラインに最適です。

```bash
# Dockerイメージのビルドとプッシュ
cd infra/sagemaker
docker build -t your-repo/sagemaker-image:latest -f docker/Dockerfile .
docker push your-repo/sagemaker-image:latest

# パイプラインの登録/更新
python src/pipeline.py \
  --pipeline-name my-pipeline \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/SageMakerPipelineRole \
  --region us-east-1
```

## サンプル処理: `sample1`

このテンプレートにはサンプル処理コマンド `sample1` が含まれています：

- **処理内容**: 学生データ (ID, 名前, 年齢, スコア) を含む CSV ファイルを読み込み、Panderaでのデータ検証を行います
- **スキーマ定義**: `src/schemas.py`
- **パラメータ定義**: `src/models.py`

## 設定管理

プロジェクトでは複数の設定管理方法をサポートしています：

1. **JSON設定ファイル**: `--config_file=path/to/config.json` で指定
2. **環境変数**: AWS Batchでは環境変数で設定パラメータを渡す
3. **S3上の設定ファイル**: SageMaker Pipelineでは S3 上の設定ファイルを使用

## 高度な機能

### 1. マルチステップ処理（SageMaker Pipeline）

`infra/sagemaker/src/run_all_samples.py` を使用して、複数の処理ステップを連続実行できます。例：

```
ステップ1: 第1の設定ファイルで sample1 を実行
ステップ2: 第2の設定ファイルで sample1 を実行
```

### 2. ロギング

構造化ロギングを `src/logger_config.py` で設定しています。JSON形式のログが出力され、CloudWatchとの統合が容易です。

### 3. エラーハンドリング

Panderaを使用したデータバリデーションにより、早期にデータ品質の問題を検出できます。

## 始めるには

1. リポジトリをクローンする
2. `.env.sample` を `.env` にコピーして必要に応じて編集
3. `poetry install` で依存関係をインストール
4. サンプルコマンドを実行: `poetry run cli sample1 --config_file=path/to/config.json`

## 貢献

プルリクエストを歓迎します。大きな変更を加える前に、まずIssueでディスカッションを開始してください。

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。
