#!/usr/bin/env python3
"""
Fargate リソース設定機能付き AWS Batch ジョブ送信スクリプト
"""

import argparse
import boto3
import datetime
import uuid
import logging
import sys
import config


def configure_logging():
    """基本的なロギング設定"""
    logging.basicConfig(
        level=logging.INFO, format=config.LOG_FORMAT, datefmt=config.LOG_DATE_FORMAT
    )
    return logging.getLogger(__name__)


def parse_args():
    """コマンドライン引数のパース"""
    parser = argparse.ArgumentParser(
        description="Fargate リソース設定付き AWS Batch ジョブ送信ツール"
    )
    parser.add_argument(
        "--job-queue",
        default=config.FARGATE_CONFIG["job_queue"],
        help="使用するジョブキュー名",
    )
    parser.add_argument(
        "--job-definition",
        default=config.FARGATE_CONFIG["job_definition"],
        help="使用するジョブ定義名",
    )
    parser.add_argument(
        "--region", default=config.DEFAULT_REGION, help="AWS リージョン"
    )
    # Fargate のリソース設定用オプション
    parser.add_argument(
        "--vcpu",
        type=float,
        default=config.DEFAULT_RESOURCES["fargate"]["vcpu"],
        choices=config.VALID_FARGATE_VCPU,
        help=f"Fargate タスクに割り当てる vCPU 数 (有効値: {config.VALID_FARGATE_VCPU})",
    )
    parser.add_argument(
        "--memory",
        type=int,
        default=config.DEFAULT_RESOURCES["fargate"]["memory"],
        help=f"Fargate タスクに割り当てるメモリの MB 数 (例: {', '.join(map(str, config.VALID_FARGATE_MEMORY[:5]))}...)",
    )
    return parser.parse_args()


def main():
    """メイン処理"""
    # ロギング設定
    logger = configure_logging()
    args = parse_args()

    # メモリ値が有効かチェック
    if args.memory not in config.VALID_FARGATE_MEMORY:
        logger.error(
            f"無効なメモリ値です: {args.memory}MB。有効な値: {', '.join(map(str, config.VALID_FARGATE_MEMORY))}"
        )
        sys.exit(1)

    # ジョブ名を生成（タイムスタンプとUUIDを含む）
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    job_id_suffix = str(uuid.uuid4())[:8]
    job_name = f"fargate-resource-job-{timestamp}-{job_id_suffix}"

    # AWS Batch クライアントを作成
    try:
        batch = boto3.client("batch", region_name=args.region)
    except Exception as e:
        logger.error(f"AWS Batch クライアント作成エラー: {e}")
        return

    # 基本ジョブ送信パラメータ
    submit_params = {
        "jobName": job_name,
        "jobQueue": args.job_queue,
        "jobDefinition": args.job_definition,
        # shareIdentifier および schedulingPriority パラメータを使用しない
    }

    # Fargate リソース要件の設定
    resource_requirements = [
        {"type": "VCPU", "value": str(args.vcpu)},
        {"type": "MEMORY", "value": str(args.memory)},
    ]

    # コンテナオーバーライドにリソース要件を設定
    submit_params["containerOverrides"] = {
        "resourceRequirements": resource_requirements
    }

    # ログ出力
    logger.info(
        f"Fargate ジョブ送信: {job_name}, キュー: {args.job_queue}, 定義: {args.job_definition}"
    )
    logger.info(f"リソース設定: vCPU={args.vcpu}, メモリ={args.memory}MB")

    # ジョブを送信
    try:
        response = batch.submit_job(**submit_params)
        job_id = response["jobId"]
        logger.info(f"Fargate ジョブ送信成功: ID = {job_id}")
        print(job_id)  # 標準出力にジョブIDを出力
    except Exception as e:
        logger.error(f"Fargate ジョブ送信エラー: {e}")


if __name__ == "__main__":
    main()
