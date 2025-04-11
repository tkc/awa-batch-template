# AWS データ処理パイプラインテンプレート

このリポジトリは、AWS 上でデータ処理パイプラインを構築するためのテンプレートプロジェクトです。AWS Batch と SageMaker Pipeline の両方の実行環境に対応しています。

Terraform を使用してインフラを構築し、Poetry で依存関係を管理しています。

## ローカルでの実行

開発やテストのために、ローカル環境でサンプルコマンドを実行できます。

```bash
# 依存関係のインストール
poetry install

# サンプルコマンドの実行 (sample1)
poetry run cli sample1 --config_file=data/params_sample1.json
```

## AWS 環境での実行

AWS Batch または SageMaker Pipeline を使用して実行することも可能です。

- **AWS Batch:** 詳細は `example/batch/README.md` を参照してください。
- **SageMaker Pipeline:** 詳細は `example/sagemaker/` ディレクトリ内のファイルを参照してください。
