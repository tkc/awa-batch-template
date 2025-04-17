#!/usr/bin/env python3
"""
コンテナオーバーライド機能付き AWS Batch EC2 ジョブ送信スクリプト
"""

import argparse
import boto3
import datetime
import uuid
import logging
import json
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
        description="AWS Batch EC2 ジョブ送信ツール（オーバーライド機能付き）"
    )
    parser.add_argument(
        "--job-queue",
        default=config.EC2_CONFIG["job_queue"],
        help="使用するジョブキュー名",
    )
    parser.add_argument(
        "--job-definition",
        default=config.EC2_CONFIG["job_definition"],
        help="使用するジョブ定義名",
    )
    parser.add_argument(
        "--region", default=config.DEFAULT_REGION, help="AWS リージョン"
    )
    # コンテナオーバーライド用のオプション
    parser.add_argument(
        "--command",
        type=str,
        help='実行するコマンド（JSON配列形式の文字列。例: \'["echo", "hello"]\'）',
    )
    parser.add_argument(
        "--environment",
        type=str,
        help='環境変数（JSON形式の文字列。例: \'{"KEY1":"VALUE1", "KEY2":"VALUE2"}\'）',
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
    job_name = f"ec2-override-job-{timestamp}-{job_id_suffix}"

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

    # フェアシェアスケジューリングを使用する場合、必要なパラメータを追加
    if config.FAIR_SHARE_CONFIG["ec2"]["use_fair_share"]:
        if config.FAIR_SHARE_CONFIG["ec2"]["share_identifier"]:
            submit_params["shareIdentifier"] = config.FAIR_SHARE_CONFIG["ec2"][
                "share_identifier"
            ]
        if config.FAIR_SHARE_CONFIG["ec2"]["scheduling_priority"] is not None:
            submit_params["schedulingPriorityOverride"] = config.FAIR_SHARE_CONFIG[
                "ec2"
            ]["scheduling_priority"]

    # コンテナオーバーライドの処理
    container_overrides = {}

    # コマンドオーバーライド
    if args.command:
        try:
            command = json.loads(args.command)
            container_overrides["command"] = command
            logger.info(f"コマンドをオーバーライド: {command}")
        except json.JSONDecodeError as e:
            logger.error(f"コマンドのJSON形式が不正: {e}")
            sys.exit(1)

    # 環境変数オーバーライド
    if args.environment:
        try:
            env_dict = json.loads(args.environment)
            environment = [{"name": k, "value": v} for k, v in env_dict.items()]
            container_overrides["environment"] = environment
            logger.info(f"環境変数をオーバーライド: {environment}")
        except json.JSONDecodeError as e:
            logger.error(f"環境変数のJSON形式が不正: {e}")
            sys.exit(1)

    # コンテナオーバーライドがあれば追加
    if container_overrides:
        submit_params["containerOverrides"] = container_overrides

    # ログ出力
    logger.info(
        f"EC2 ジョブ送信: {job_name}, キュー: {args.job_queue}, 定義: {args.job_definition}"
    )

    # ジョブを送信
    try:
        response = batch.submit_job(**submit_params)
        job_id = response["jobId"]
        logger.info(f"EC2 ジョブ送信成功: ID = {job_id}")
        print(job_id)  # 標準出力にジョブIDを出力
    except Exception as e:
        logger.error(f"EC2 ジョブ送信エラー: {e}")


if __name__ == "__main__":
    main()
