#!/usr/bin/env python3
"""
AWS Batchジョブ送信スクリプト
EC2およびFargateベースのコンピューティング環境に対応
フェアシェアスケジューリングポリシーに対応

使用例:
  # 基本的な使用法
  python submit_job.py --job-queue awa-batch-dev-ec2-high-priority --job-definition awa-batch-dev-ec2-sample1

  # パラメータファイルを使用
  python submit_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample --parameters-file params.json

  # タグを追加
  python submit_job.py --job-queue awa-batch-dev-ec2-high-priority --job-definition awa-batch-dev-ec2-sample1 --tags '{"Department":"Finance","Project":"Quarterly-Report"}'
"""

import argparse
import boto3
import datetime
import sys
import json
import os
import uuid
import logging


def configure_logging():
    """ロギングの設定"""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )
    return logging.getLogger(__name__)


def parse_arguments():
    """コマンドライン引数の解析"""
    parser = argparse.ArgumentParser(description="AWS Batchジョブ送信ツール")
    parser.add_argument(
        "--job-name-prefix",
        default=os.environ.get("AWS_BATCH_JOB_NAME_PREFIX", "my-batch-job"),
        help="ジョブ名のプレフィックス（環境変数 AWS_BATCH_JOB_NAME_PREFIX でも設定可能）"
    )
    parser.add_argument(
        "--job-queue",
        default=os.environ.get("AWS_BATCH_JOB_QUEUE", "awa-batch-dev-ec2-high-priority"),
        help="使用するジョブキュー（環境変数 AWS_BATCH_JOB_QUEUE でも設定可能）"
    )
    parser.add_argument(
        "--job-definition",
        default=os.environ.get("AWS_BATCH_JOB_DEFINITION", "awa-batch-dev-ec2-sample1"),
        help="使用するジョブ定義（環境変数 AWS_BATCH_JOB_DEFINITION でも設定可能）"
    )
    parser.add_argument(
        "--region",
        default=os.environ.get("AWS_REGION", "ap-northeast-1"),
        help="AWSリージョン（環境変数 AWS_REGION でも設定可能）"
    )
    parser.add_argument(
        "--share-identifier",
        default=os.environ.get("AWS_BATCH_SHARE_IDENTIFIER", "default"),
        help="フェアシェアスケジューリングのシェア識別子（環境変数 AWS_BATCH_SHARE_IDENTIFIER でも設定可能）"
    )
    parser.add_argument(
        "--scheduling-priority",
        type=int,
        default=int(os.environ.get("AWS_BATCH_SCHEDULING_PRIORITY", "0")),
        help="スケジューリング優先度（環境変数 AWS_BATCH_SCHEDULING_PRIORITY でも設定可能）"
    )
    parser.add_argument(
        "--parameters-file",
        type=str,
        help="ジョブパラメータを含むJSONファイルのパス"
    )
    parser.add_argument(
        "--tags",
        type=str,
        help="ジョブに付けるタグ（JSON形式の文字列。例: '{\"Department\":\"Finance\"}'）"
    )
    parser.add_argument(
        "--container-overrides-file",
        type=str,
        help="コンテナオーバーライド設定を含むJSONファイルのパス"
    )
    parser.add_argument(
        "--depends-on",
        type=str,
        help="依存ジョブのIDをカンマ区切りで指定（例: 'job-1,job-2'）"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="実際にジョブを送信せずパラメータを表示のみ"
    )
    parser.add_argument(
        "--array-size",
        type=int,
        help="配列ジョブのサイズ（指定すると配列ジョブとして送信）"
    )

    return parser.parse_args()


def load_json_file(file_path, logger):
    """JSONファイルを読み込む"""
    try:
        with open(file_path, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        logger.error(f"ファイル '{file_path}' が見つかりません")
        sys.exit(1)
    except json.JSONDecodeError as e:
        logger.error(f"ファイル '{file_path}' のJSON形式が不正です: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"ファイル '{file_path}' の読み込み中にエラーが発生しました: {e}")
        sys.exit(1)


def main():
    logger = configure_logging()
    args = parse_arguments()

    # ジョブ名を生成（現在時刻とUUIDを含める）
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    job_id_suffix = str(uuid.uuid4())[:8]  # UUIDの先頭8文字を使用
    job_name = f"{args.job_name_prefix}-{timestamp}-{job_id_suffix}"

    # AWS Batchクライアントを作成
    try:
        batch = boto3.client("batch", region_name=args.region)
    except Exception as e:
        logger.error(f"AWS Batchクライアントの作成に失敗しました: {e}")
        sys.exit(1)

    # ジョブ送信パラメータを構築
    submit_params = {
        "jobName": job_name,
        "jobQueue": args.job_queue,
        "jobDefinition": args.job_definition,
    }

    # フェアシェアスケジューリングのパラメータを追加
    if hasattr(args, "share_identifier") and args.share_identifier:
        submit_params["shareIdentifier"] = args.share_identifier
    
    if hasattr(args, "scheduling_priority") and args.scheduling_priority is not None:
        submit_params["schedulingPriorityOverride"] = args.scheduling_priority

    # 配列ジョブのパラメータを追加
    if args.array_size and args.array_size > 0:
        submit_params["arrayProperties"] = {"size": args.array_size}

    # ログ出力用の辞書を作成
    log_data = {
        "action": "ジョブサブミット",
        "job_definition": args.job_definition,
        "job_queue": args.job_queue,
        "job_name": job_name,
        "region": args.region,
        "timestamp": datetime.datetime.now().isoformat()
    }

    # シェア識別子と優先度があれば追加
    if hasattr(args, "share_identifier") and args.share_identifier:
        log_data["share_identifier"] = args.share_identifier
    
    if hasattr(args, "scheduling_priority") and args.scheduling_priority is not None:
        log_data["scheduling_priority"] = args.scheduling_priority

    # 配列ジョブ情報を追加
    if args.array_size and args.array_size > 0:
        log_data["array_size"] = args.array_size

    # 依存ジョブのパラメータを追加
    if args.depends_on:
        job_ids = [job_id.strip() for job_id in args.depends_on.split(",")]
        dependencies = [{"jobId": job_id, "type": "SEQUENTIAL"} for job_id in job_ids]
        submit_params["dependsOn"] = dependencies
        log_data["depends_on"] = job_ids

    # オプションのパラメータファイル
    if args.parameters_file:
        params = load_json_file(args.parameters_file, logger)
        submit_params["parameters"] = params
        log_data["parameters_file"] = args.parameters_file
        log_data["parameters"] = params

    # オプションのコンテナオーバーライドファイル
    if args.container_overrides_file:
        container_overrides = load_json_file(args.container_overrides_file, logger)
        submit_params["containerOverrides"] = container_overrides
        log_data["container_overrides_file"] = args.container_overrides_file
        log_data["container_overrides"] = container_overrides

    # オプションのタグ
    if args.tags:
        try:
            tags = json.loads(args.tags)
            if isinstance(tags, dict):
                submit_params["tags"] = tags
                log_data["tags"] = tags
            else:
                logger.error("タグはJSON形式の辞書である必要があります")
                sys.exit(1)
        except json.JSONDecodeError as e:
            logger.error(f"タグのJSON形式が不正です: {e}")
            sys.exit(1)

    # ドライラン（実行せずパラメータを表示のみ）
    if args.dry_run:
        log_data["dry_run"] = True
        logger.info("ドライラン - 実際のジョブは送信されません")
        logger.info(f"送信パラメータ: {json.dumps(submit_params, ensure_ascii=False, indent=2)}")
        return

    # 実行前ログの出力
    logger.info(f"ジョブ送信パラメータ: {json.dumps(log_data, ensure_ascii=False)}")

    try:
        response = batch.submit_job(**submit_params)
        job_id = response["jobId"]
        
        # 成功ログの出力
        log_data["status"] = "success"
        log_data["job_id"] = job_id
        logger.info(f"ジョブ送信成功: {json.dumps(log_data, ensure_ascii=False)}")
        
        # 標準出力にジョブIDを出力（他のスクリプトから利用しやすくするため）
        print(job_id)
    except Exception as e:
        # エラーログの出力
        log_data["status"] = "error"
        log_data["error_message"] = str(e)
        logger.error(f"ジョブ送信エラー: {json.dumps(log_data, ensure_ascii=False)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
