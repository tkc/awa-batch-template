#!/usr/bin/env python3
"""
AWS Batch Fargateジョブ送信スクリプト
Fargateベースのコンピューティング環境専用のジョブ送信に対応
必要なリソース設定やFargate固有のオプションを指定可能

使用例:
  # 基本的な使用法
  python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample

  # コンテナオーバーライドを使用してリソース設定をカスタマイズ
  python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample --vcpu 2 --memory 4096

  # パラメータファイルを使用
  python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample --parameters-file params.json

  # タグを追加
  python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample --tags '{"Department":"Finance","Project":"Quarterly-Report"}'
  
  # フェアシェアスケジューリングポリシーを使用
  python submit_fargate_job.py --job-queue awa-batch-dev-fargate-high-priority --job-definition awa-batch-dev-fargate-sample --share-identifier A1 --scheduling-priority 10
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
    parser = argparse.ArgumentParser(description="AWS Batch Fargateジョブ送信ツール")
    parser.add_argument(
        "--job-name-prefix",
        default=os.environ.get("AWS_BATCH_JOB_NAME_PREFIX", "fargate-job"),
        help="ジョブ名のプレフィックス（環境変数 AWS_BATCH_JOB_NAME_PREFIX でも設定可能）"
    )
    parser.add_argument(
        "--job-queue",
        default=os.environ.get("AWS_BATCH_JOB_QUEUE", "awa-batch-dev-fargate-high-priority"),
        help="使用するジョブキュー（環境変数 AWS_BATCH_JOB_QUEUE でも設定可能）"
    )
    parser.add_argument(
        "--job-definition",
        default=os.environ.get("AWS_BATCH_JOB_DEFINITION", "awa-batch-dev-fargate-sample"),
        help="使用するジョブ定義（環境変数 AWS_BATCH_JOB_DEFINITION でも設定可能）"
    )
    parser.add_argument(
        "--region",
        default=os.environ.get("AWS_REGION", "ap-northeast-1"),
        help="AWSリージョン（環境変数 AWS_REGION でも設定可能）"
    )
    parser.add_argument(
        "--share-identifier",
        default=os.environ.get("AWS_BATCH_SHARE_IDENTIFIER", ""),
        help="フェアシェアスケジューリングのシェア識別子（環境変数 AWS_BATCH_SHARE_IDENTIFIER でも設定可能）"
    )
    parser.add_argument(
        "--scheduling-priority",
        type=int,
        default=int(os.environ.get("AWS_BATCH_SCHEDULING_PRIORITY", "0")),
        help="スケジューリング優先度（環境変数 AWS_BATCH_SCHEDULING_PRIORITY でも設定可能）"
    )
    parser.add_argument(
        "--vcpu",
        type=float,
        help="Fargateタスクに割り当てるvCPUの数（例: 0.25, 0.5, 1, 2, 4）"
    )
    parser.add_argument(
        "--memory",
        type=int,
        help="Fargateタスクに割り当てるメモリのMB数（例: 512, 1024, 2048, 4096）"
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
        "--command",
        type=str,
        help="実行するコマンド（JSON配列形式の文字列。例: '[\"echo\", \"hello\"]'）"
    )
    parser.add_argument(
        "--environment",
        type=str,
        help="環境変数（JSON形式の文字列。例: '{\"KEY1\":\"VALUE1\", \"KEY2\":\"VALUE2\"}'）"
    )
    parser.add_argument(
        "--depends-on",
        type=str,
        help="依存ジョブのIDをカンマ区切りで指定（例: 'job-1,job-2'）"
    )
    parser.add_argument(
        "--platform-version",
        type=str,
        default="LATEST",
        help="Fargate プラットフォームバージョン（例: 'LATEST', '1.4.0'）"
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

    # Fargateのコンテナオーバーライドを構築
    container_overrides = {}
    
    # コマンドオーバーライド
    if args.command:
        try:
            command = json.loads(args.command)
            container_overrides["command"] = command
        except json.JSONDecodeError as e:
            logger.error(f"コマンドのJSON形式が不正です: {e}")
            sys.exit(1)

    # 環境変数オーバーライド
    if args.environment:
        try:
            env_dict = json.loads(args.environment)
            environment = [{"name": k, "value": v} for k, v in env_dict.items()]
            container_overrides["environment"] = environment
        except json.JSONDecodeError as e:
            logger.error(f"環境変数のJSON形式が不正です: {e}")
            sys.exit(1)

    # リソース要件オーバーライド (Fargate特有)
    resource_requirements = []
    if args.vcpu:
        resource_requirements.append({
            "type": "VCPU",
            "value": str(args.vcpu)
        })
    
    if args.memory:
        resource_requirements.append({
            "type": "MEMORY",
            "value": str(args.memory)
        })

    if resource_requirements:
        container_overrides["resourceRequirements"] = resource_requirements

    # 注：Fargateプラットフォーム設定はコンテナオーバーライドではなく、別のパラメータとして指定する必要があります

    # コンテナオーバーライドファイルがある場合は読み込んでマージ
    if args.container_overrides_file:
        file_overrides = load_json_file(args.container_overrides_file, logger)
        container_overrides.update(file_overrides)

    # コンテナオーバーライドがある場合は追加
    if container_overrides:
        submit_params["containerOverrides"] = container_overrides

    # フェアシェアスケジューリングのパラメータを追加
    if args.share_identifier:
        submit_params["shareIdentifier"] = args.share_identifier
    
    if args.scheduling_priority != 0:
        submit_params["schedulingPriorityOverride"] = args.scheduling_priority

    # 配列ジョブのパラメータを追加
    if args.array_size and args.array_size > 0:
        submit_params["arrayProperties"] = {"size": args.array_size}

    # ログ出力用の辞書を作成
    log_data = {
        "action": "Fargateジョブサブミット",
        "job_definition": args.job_definition,
        "job_queue": args.job_queue,
        "job_name": job_name,
        "region": args.region,
        "timestamp": datetime.datetime.now().isoformat()
    }

    # シェア識別子と優先度があれば追加
    if args.share_identifier:
        log_data["share_identifier"] = args.share_identifier
    
    if args.scheduling_priority != 0:
        log_data["scheduling_priority"] = args.scheduling_priority

    # リソース設定を追加
    if args.vcpu:
        log_data["vcpu"] = args.vcpu
    
    if args.memory:
        log_data["memory"] = args.memory
    
    # プラットフォームバージョンを追加
    if args.platform_version:
        log_data["platform_version"] = args.platform_version

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

    # Fargateプラットフォーム設定をジョブ定義のオーバーライドとして追加
    if args.platform_version:
        if "containerOverrides" not in submit_params:
            submit_params["containerOverrides"] = {}
            
        # ジョブ定義プロパティを使用して実装する場合、現在のAWS Batch APIでは
        # ジョブ送信時にプラットフォームバージョンを指定する方法が限られています
        # Terraformの場合はジョブ定義で指定するか、ECSタスク定義を使用する必要があります
        
        # プラットフォームバージョンの指定はジョブ定義で行うことをログに記録
        logger.info(f"Fargateプラットフォームバージョン {args.platform_version} はジョブ送信時には指定できません。ジョブ定義で設定してください")
        
    # 実行前ログの出力
    logger.info(f"Fargateジョブ送信パラメータ: {json.dumps(log_data, ensure_ascii=False)}")


    try:
        response = batch.submit_job(**submit_params)
        job_id = response["jobId"]
        
        # 成功ログの出力
        log_data["status"] = "success"
        log_data["job_id"] = job_id
        logger.info(f"Fargateジョブ送信成功: {json.dumps(log_data, ensure_ascii=False)}")
        
        # 標準出力にジョブIDを出力（他のスクリプトから利用しやすくするため）
        print(job_id)
    except Exception as e:
        # エラーログの出力
        log_data["status"] = "error"
        log_data["error_message"] = str(e)
        logger.error(f"Fargateジョブ送信エラー: {json.dumps(log_data, ensure_ascii=False)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
