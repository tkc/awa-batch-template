# AWS Batch Runner (`run_batch.py`)

このディレクトリには、AWS Batch ジョブのコンテナエントリーポイントとして機能するスクリプト (`run_batch.py`) が含まれています。このスクリプトは、`awa-batch-processor` ライブラリ（メインプロジェクト）の `sample1` 処理を実行します。

**重要:** このスクリプト (`run_batch.py`) は、AWS Batch 環境での実行専用に設計されており、パラメータを **環境変数** から読み込みます。ローカルでのテストや実行には、プロジェクトルートのメイン CLI (`poetry run cli sample1 ...`) を使用してください。

## AWS Batch での実行

AWS Batch でジョブを実行する際、この `run_batch.py` スクリプトが Docker コンテナ (`infra/batch/docker/Dockerfile` でビルド) 内で実行されます。

スクリプトは、`awa_batch_processor.src.models.Sample1Params` モデルで定義されたフィールドに対応する環境変数からパラメータを読み込みます (`load_config_from_env` を使用)。例えば、`Sample1Params` に `process_id` と `csv_path` フィールドがある場合、コンテナには `PROCESS_ID` と `CSV_PATH` という環境変数を設定する必要があります。

- **`PROCESS_ID`**: 処理を識別するための任意の ID（例: `batch-job-123`）。
- **`CSV_PATH`**: コンテナ内の処理対象 CSV ファイルへのフルパス（例: `/app/data/sample1_data.csv`）。Dockerfile でデータがどのようにコピーされるかを確認してください。

必要な環境変数は `src/models.py` の `Sample1Params` の定義によって決まります。大文字・小文字は区別され、環境変数名がモデルのフィールド名に対応します。

## 依存関係

このスクリプトは、Docker イメージビルド時に `awa-batch-processor` パッケージ（メインプロジェクトの `src` ディレクトリからビルドされたもの）がインストールされていることを前提としています。これは `infra/batch/src/pyproject.toml` の git 依存関係として定義されています。
