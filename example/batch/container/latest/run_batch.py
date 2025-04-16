import sys

from batch_processor import sample1  # type: ignore
from batch_processor.config import load_config_from_env  # type: ignore
from batch_processor.models import Sample1Params  # type: ignore


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

    except ValueError as e:  # Pydantic validation error or load_config_from_env error
        print(f"Configuration or validation error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
