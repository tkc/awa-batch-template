# ベースイメージ
FROM python:3.11-slim

# ラベル
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="SageMaker Pipeline job Docker image"

# 作業ディレクトリの設定
WORKDIR /app

# 必要なパッケージをインストール
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

# SageMaker固有のプロジェクトファイルをコピー (ビルドコンテキストルートから)
COPY infra/sagemaker/src/pyproject.toml infra/sagemaker/src/poetry.lock ./

# SageMaker固有の依存関係をインストール
# 注意: このpoetry installはコピーされたpyproject.toml/poetry.lockに基づきます
RUN poetry install --no-interaction --no-ansi

# SageMakerのソースコードをコピー (ビルドコンテキストルートから)
COPY infra/sagemaker/src /app/

# PYTHONPATHを設定 (アプリのルートのみ)
ENV PYTHONPATH=/app

# デフォルトコマンドを設定 (例: pipeline.py を実行)
# 必要に応じてSageMaker Pipelineのステップ定義で上書きしてください
ENTRYPOINT ["poetry", "run", "python", "pipeline.py"]

# CMD は通常不要
