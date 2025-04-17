#!/usr/bin/env python3
"""
環境変数オーバーライドでJSONパラメータを送信するAWS Batch Fargateジョブ送信スクリプト
"""
import argparse
import boto3
import datetime
import uuid
import logging
import json
import sys
import os
import config

def configure_logging():
    """基本的なロギング設定"""
    logging.basicConfig(
        level=logging.INFO,
        format=config.LOG_FORMAT,
        datefmt=config.LOG_DATE_FORMAT
    )
    return logging.getLogger(__name__)

def parse_args():
    """コマンドライン引数のパース"""
    parser = argparse.ArgumentParser(description="環境変数オーバーライドでJSONパラメータを送信するAWS Batch Fargateジョブ送信ツール")
    parser.add_argument("--job-queue", default=config.FARGATE_CONFIG["job_queue"],
                        help="使用するジョブキュー名")
    parser.add_argument("--job-definition", default=config.FARGATE_CONFIG["job_definition"],
                        help="使用するジョブ定義名")
    parser.add_argument("--region", default=config.DEFAULT_REGION,
                        help="AWS リージョン")
    parser.add_argument("--params-file", required=True,
                        help="ジョブパラメータを含むJSONファイルのパス")
    return parser.parse_args()

def load_params_file(file_path):
    """JSONパラメータファイルを読み込む"""
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"パラメータファイルが見つかりません: {file_path}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        raise ValueError(f"パラメータファイルのJSON形式が不正です: {e}")

def main():
    """メイン処理"""
    # ロギング設定
    logger = configure_logging()
    args = parse_args()
    
    # パラメータファイルを読み込む
    try:
        config_data = load_params_file(args.params_file)
        logger.info(f"パラメータファイルを読み込みました: {args.params_file}")
    except Exception as e:
        logger.error(f"パラメータファイル読み込みエラー: {e}")
        sys.exit(1)
    
    # ジョブ名を生成（タイムスタンプとUUIDを含む）
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    job_id_suffix = str(uuid.uuid4())[:8]
    job_name = f"fargate-env-override-job-{timestamp}-{job_id_suffix}"
    
    # AWS Batch クライアントを作成
    try:
        batch = boto3.client("batch", region_name=args.region)
    except Exception as e:
        logger.error(f"AWS Batch クライアント作成エラー: {e}")
        return
    
    # ログ出力
    logger.info(f"Fargate ジョブ送信: {job_name}, キュー: {args.job_queue}, 定義: {args.job_definition}")
    logger.info(f"パラメータ: {json.dumps(config_data, ensure_ascii=False)}")
    
    # JSON文字列に変換
    config_json_str = json.dumps(config_data)
    
    # 環境変数をフラット化したバージョンも作成
    flattened_env_vars = []
    
    # CONFIG環境変数としてJSONを設定
    flattened_env_vars.append({
        'name': 'CONFIG',
        'value': config_json_str
    })
    
    # 個別のトップレベルパラメータも環境変数として設定
    for key, value in config_data.items():
        if isinstance(value, (str, int, float, bool)):
            # プリミティブな値の場合は直接環境変数に設定
            flattened_env_vars.append({
                'name': f'PARAM_{key.upper()}',
                'value': str(value)
            })
        elif isinstance(value, dict):
            # ネストされた辞書の場合、JSON文字列として設定
            flattened_env_vars.append({
                'name': f'PARAM_{key.upper()}',
                'value': json.dumps(value)
            })
    
    # ジョブを送信 - containerOverridesの環境変数として渡す
    try:
        response = batch.submit_job(
            jobName=job_name,
            jobQueue=args.job_queue,
            jobDefinition=args.job_definition,
            containerOverrides={
                'environment': flattened_env_vars
            }
        )
        
        job_id = response["jobId"]
        logger.info(f"Fargate ジョブ送信成功: ID = {job_id}")
        print(job_id)  # 標準出力にジョブIDを出力
    except Exception as e:
        logger.error(f"Fargate ジョブ送信エラー: {e}")

if __name__ == "__main__":
    main()
