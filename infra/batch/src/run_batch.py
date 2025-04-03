import os
import sys

# Assuming the package installed via poetry from the git repo is named 'awa_batch_processor'
# and its structure allows importing like this.
# This requires the src directory to be importable as 'awa_batch_processor'.
# We might need to adjust pyproject.toml's package definition if it's just `src`.
# Import from the installed package (name defined in the library's pyproject.toml, assumed 'awa_batch_processor')
# Note: The actual import path depends on how the library exposes its modules.
# Assuming the library's pyproject.toml defines the package name as 'awa_batch_processor'
# and the structure is src/awa_batch_processor/... or similar.
# Import from the installed git dependency 'awa-batch-processor'
# The actual import name depends on the package structure in the git repo,
# assuming it's 'awa_batch_processor' based on the key in pyproject.toml.
from awa_batch_processor.config import load_config_from_env
from awa_batch_processor.main import sample1
from awa_batch_processor.models import Sample1Params


def main():
    """
    AWS Batch実行用スクリプト。
    環境変数から設定を読み込み、sample1コマンドを実行する。
    """
    print("Starting batch execution using installed package...")
    try:
        # Load configuration from environment variables (expects PROCESS_ID and CSV_PATH env vars)
        params = load_config_from_env(Sample1Params)
        print("Configuration loaded from environment variables.")

        # Execute the sample1 function
        print("Executing sample1 function...")
        sample1(params)
        print("sample1 function completed.")

    except ValueError as e:
        print(f"Configuration or validation error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
