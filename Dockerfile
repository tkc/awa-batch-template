# ベースイメージ
FROM python:3.9-slim

# ラベル
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="AWS Batch job Docker image with Poetry"

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

# プロジェクトファイルをコピー
COPY pyproject.toml poetry.lock* ./

# 依存関係のインストール
RUN poetry install --no-dev --no-interaction --no-ansi

# アプリケーションコードをコピー
COPY src/ /app/src/

# 環境変数ファイルが存在する場合はコピー (シェル構文を削除)
COPY .env* /app/

# 環境変数の設定
ENV PYTHONPATH=/app

# AWS CLI v2のインストール（必要な場合）
# RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
#     unzip awscliv2.zip && \
#     ./aws/install && \
#     rm -rf aws awscliv2.zip

# デフォルトコマンドを設定 (Poetry スクリプトを使用)
ENTRYPOINT ["poetry", "run"]

# CMD instruction removed as it's typically overridden in AWS Batch
