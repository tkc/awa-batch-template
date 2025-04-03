# ベースイメージ (Python 3.11 に変更)
FROM python:3.11-slim

# ラベル
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="AWS Batch job Docker image using awa-batch-template library"

# 作業ディレクトリの設定
WORKDIR /app

# 必要なパッケージをインストール (gitはpoetryがgit依存関係をインストールするために必要)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Poetry のインストール
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    ln -s /root/.local/bin/poetry /usr/local/bin/

# Poetryの設定（仮想環境を作成しない）
RUN poetry config virtualenvs.create false

# Ensure the target directory exists (though WORKDIR should handle this)
RUN mkdir -p /app

# プロジェクトファイルをコピー (プロジェクトルートからの相対パスに変更)
COPY infra/batch/src/pyproject.toml infra/batch/src/poetry.lock infra/batch/src/README.md /app/

# 依存関係のインストール (ローカルの awa-batch-processor パッケージを含む)
# --no-root オプションは不要 (runner自体はパッケージではないため)
RUN poetry install --no-interaction --no-ansi

# 実行スクリプトをコピー (プロジェクトルートからの相対パスに変更)
COPY infra/batch/src/run_batch.py /app/run_batch.py

# データファイルをコピー (プロジェクトルートからの相対パス)
COPY data/sample1_data.csv /app/data/sample1_data.csv

# 環境変数の設定 (PYTHONPATH=/app のみで良いはず)
ENV PYTHONPATH=/app

# 新しいスクリプトを実行するようにENTRYPOINTを変更
ENTRYPOINT ["python", "/app/run_batch.py"]
