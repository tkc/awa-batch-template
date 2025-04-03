# AWS Batch Runner (`run_batch.py`)

このディレクトリには、AWS Batch ジョブのコンテナエントリーポイントとして機能するスクリプト (`run_batch.py`) が含まれています。このスクリプトは、`awa-batch-processor` ライブラリ（メインプロジェクト）の `sample1` 処理を実行します。

**重要:** このスクリプト (`run_batch.py`) は、AWS Batch 環境での実行を主眼としており、パラメータを **環境変数** から読み込みます。コアロジックのローカルテストには、プロジェクトルートのメイン CLI (`poetry run cli sample1 ...`) の使用を推奨します。

## ローカルでの直接実行 (デバッグ等)

`run_batch.py` スクリプト自体をローカルで直接実行する必要がある場合（例: Batch 環境固有の動作をシミュレートしたい場合など）、**`poetry run` を使用して Poetry の仮想環境を有効にする必要があります。** これにより、依存関係 (`awa_batch_processor` パッケージ) が正しく解決されます。

実行前に、必要な環境変数を設定してください。**また、この `infra/batch/src` ディレクトリからコマンドを実行する必要があります。**

```bash
# infra/batch/src ディレクトリにいることを確認

# 例: 環境変数を設定
export PROCESS_ID="local-debug-$(date +%s)"
# CSVパスは現在のディレクトリ(infra/batch/src)からの相対パス
export CSV_PATH="../../data/sample1_data.csv"

# poetry run を付けて実行
poetry run python run_batch.py
```

**注意:**

- このディレクトリ (`infra/batch/src`) 以外から `poetry run python infra/batch/src/run_batch.py` を実行すると、依存関係が正しく解決されず `ModuleNotFoundError` が発生する可能性があります。
- `poetry run` を付けずに実行した場合も `ModuleNotFoundError` が発生します。

## AWS Batch での実行

AWS Batch でジョブを実行する際、この `run_batch.py` スクリプトが Docker コンテナ (`infra/batch/docker/Dockerfile` でビルド) 内で実行されます。

スクリプトは、`awa_batch_processor.src.models.Sample1Params` モデルで定義されたフィールドに対応する環境変数からパラメータを読み込みます (`load_config_from_env` を使用)。例えば、`Sample1Params` に `process_id` と `csv_path` フィールドがある場合、コンテナには `PROCESS_ID` と `CSV_PATH` という環境変数を設定する必要があります。

- **`PROCESS_ID`**: 処理を識別するための任意の ID（例: `batch-job-123`）。
- **`CSV_PATH`**: コンテナ内の処理対象 CSV ファイルへのフルパス（例: `/app/data/sample1_data.csv`）。Dockerfile でデータがどのようにコピーされるかを確認してください。

必要な環境変数は `src/models.py` の `Sample1Params` の定義によって決まります。大文字・小文字は区別され、環境変数名がモデルのフィールド名に対応します。

## 依存関係

このスクリプトは、Docker イメージビルド時に `awa-batch-processor` パッケージ（メインプロジェクトの `src` ディレクトリからビルドされたもの）がインストールされていることを前提としています。これは `infra/batch/src/pyproject.toml` の git 依存関係として定義されています。
