#!/usr/bin/env python3
"""
AWS Batchコンテナ内でパラメータを取得するスクリプト
"""

import sys
import os
import json

def main():
    try:
        print("=== バッチジョブ開始 ===")
        print("version: 1.0.3")

        # 基本的な環境変数を表示
        print("\n=== 基本環境変数 ===")
        print(f"ENVIRONMENT: {os.environ.get('ENVIRONMENT', '未設定')}")
        print(f"AWS_BATCH_JOB_ID: {os.environ.get('AWS_BATCH_JOB_ID', '未設定')}")
        print(f"AWS_BATCH_JOB_ATTEMPT: {os.environ.get('AWS_BATCH_JOB_ATTEMPT', '未設定')}")
        print(f"AWS_BATCH_JOB_QUEUE: {os.environ.get('AWS_BATCH_JOB_QUEUE', '未設定')}")
        
        print("\n--- JSONパラメータの取得 ---")

        try:
            config = json.loads(os.environ['CONFIG'])
            print(json.dumps(config, indent=2, ensure_ascii=False))
        except json.JSONDecodeError as e:
            print(f"JSONパース中にエラーが発生しました: {e}", file=sys.stderr)
        
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
