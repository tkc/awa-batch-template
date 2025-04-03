import os
import sys
# from pathlib import Path # 不要

# Import explicitly from the installed 'awa_batch_processor' package
# Assuming the package structure allows importing from 'awa_batch_processor.src'
from awa-batch-processor.src.main import sample1  # type: ignore
from awa-batch-processor.src.models import Sample1Params  # type: ignore
from awa-batch-processor.src.config import load_config_from_env # type: ignore


def main():
    """
    AWS Batch実行用スクリプト。
    環境変数から設定を読み込み、sample1コマンドを実行する。
    (ローカル実行は poetry run cli を使用)
    """
    print("Starting batch execution using installed package...")

    try:
        # 環境変数から設定を読み込む
        # Sample1Paramsに必要な環境変数が設定されていることを期待する
        # (例: PROCESS_ID, CSV_PATH など)
        params = load_config_from_env(Sample1Params)
        print("Configuration loaded from environment variables.")

        # Execute the sample1 function
        print("Executing sample1 function...")
        sample1(params)
        print("sample1 function completed.")

    except ValueError as e: # Pydantic validation error or load_config_from_env error
        print(f"Configuration or validation error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
