#!/usr/bin/env python3
"""
AWS Batch ジョブ送信のための共通設定ファイル
"""

import os

# 基本設定
DEFAULT_REGION = "ap-northeast-1"

# 環境変数からプロジェクト環境を取得（デフォルトは dev）
ENV = os.environ.get("AWS_BATCH_ENV", "dev")

# プロジェクト名
PROJECT_NAME = "awa-batch"

# 環境ごとの接頭辞
NAME_PREFIX = f"{PROJECT_NAME}-{ENV}"

# EC2関連の設定
EC2_CONFIG = {
    "job_queue": f"{NAME_PREFIX}-ec2",
    "job_definition": f"{NAME_PREFIX}-ec2-sample1",
    "array_job_queue": f"{NAME_PREFIX}-ec2", 
}

# Fargate関連の設定
FARGATE_CONFIG = {
    "job_queue": f"{NAME_PREFIX}-fargate", # 
    "job_definition": f"{NAME_PREFIX}-fargate-sample",
    "array_job_queue": f"{NAME_PREFIX}-fargate",
}

# デフォルトのリソース設定
DEFAULT_RESOURCES = {
    "ec2": {
        "vcpu": 1,
        "memory": 2048,
    },
    "fargate": {
        "vcpu": 0.5,
        "memory": 1024,
    },
}

# リトライ設定
RETRY_ATTEMPTS = 3

# 有効なvCPU値（Fargate用）
VALID_FARGATE_VCPU = [0.25, 0.5, 1, 2, 4, 8, 16]

# 有効なメモリ値（Fargate用、MB単位）
VALID_FARGATE_MEMORY = [
    512,
    1024,
    2048,
    3072,
    4096,
    5120,
    6144,
    7168,
    8192,
    9216,
    10240,
    11264,
    12288,
    13312,
    14336,
    15360,
    16384,
]

# フェアシェアスケジューリング設定
FAIR_SHARE_CONFIG = {
    "ec2": {
        "use_fair_share": True,  # EC2キューはフェアシェアスケジューリングを使用
        "share_identifier": "default",  # 共有リソースの識別子
        "scheduling_priority": 1,  # スケジューリング優先度（高い値ほど優先）
    },
    "fargate": {
        "use_fair_share": False,  # Fargateキューはフェアシェアスケジューリングを使用しない
        "share_identifier": None,
        "scheduling_priority": None,
    },
}

# ログフォーマット
LOG_FORMAT = "%(asctime)s - %(levelname)s - %(message)s"
LOG_DATE_FORMAT = "%Y-%m-%d %H:%M:%S"
