#!/usr/bin/env python3
"""
シンプルな AWS Batch Fargate ジョブ送信スクリプト
"""

import argparse
import boto3
import datetime
import uuid
import logging
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
        description="シンプルな AWS Batch Fargate ジョブ送信ツール"
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
    return parser.parse_args()


def main():
    """メイン処理"""
    # ロギング設定
    logger = configure_logging()
    args = parse_args()

    # ジョブ名を生成（タイムスタンプとUUIDを含む）
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    job_id_suffix = str(uuid.uuid4())[:8]
    job_name = f"fargate-job-{timestamp}-{job_id_suffix}"

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
    }

    # フェアシェアスケジューリングを使用する場合、shareIdentifierを追加
    if (
        config.FAIR_SHARE_CONFIG["fargate"]["use_fair_share"]
        and config.FAIR_SHARE_CONFIG["fargate"]["share_identifier"]
    ):
        submit_params["shareIdentifier"] = config.FAIR_SHARE_CONFIG["fargate"][
            "share_identifier"
        ]

    # ログ出力
    logger.info(
        f"Fargate ジョブ送信: {job_name}, キュー: {args.job_queue}, 定義: {args.job_definition}"
    )

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
