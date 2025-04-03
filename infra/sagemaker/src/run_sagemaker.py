import argparse
import sys
import os
import glob

# infra/sagemaker/src/pyproject.toml で定義された git 依存関係をインポート
# パッケージ名は pyproject.toml のキーに合わせる (awa-batch-processor)
# 実際のインポート名は git リポジトリ内のパッケージ構造に依存するが、
# ここでは pyproject.toml のキー名と同じ 'awa_batch_processor' と仮定する
# (もし違えば ModuleNotFoundError が発生するので、その際に修正する)
from awa_batch_processor.config import load_config_from_file
from awa_batch_processor.main import sample1
from awa_batch_processor.models import Sample1Params

def find_config_file(config_dir):
    """Finds the first .json file in the specified directory."""
    json_files = glob.glob(os.path.join(config_dir, "*.json"))
    if not json_files:
        print(f"Error: No .json configuration file found in directory {config_dir}", file=sys.stderr)
        return None
    return json_files[0]

def run_sample1_from_config(config_file_path):
    """Loads config from file and runs the sample1 function."""
    if not config_file_path:
        return False # Indicate failure

    print(f"Running sample1 function with config file: {config_file_path}")
    try:
        # Load configuration from the JSON file using the updated Sample1Params model (now with process_id)
        params = load_config_from_file(Sample1Params, config_file_path)
        print("Configuration loaded from JSON file.")

        # Execute the sample1 function directly
        print("Executing sample1 function...")
        sample1(params)
        print("sample1 function completed.")
        return True # Indicate success

    except FileNotFoundError:
        # Error already printed by load_config_from_file
        return False
    except ValueError as e:
        # Error already printed by load_config_from_file or validation error
        print(f"Configuration or validation error: {e}", file=sys.stderr)
        return False
    except Exception as e:
        print(f"An unexpected error occurred during sample1 execution: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config-dir1", type=str, required=True, help="Path to the first configuration directory.")
    parser.add_argument("--config-dir2", type=str, required=True, help="Path to the second configuration directory.")
    # Add arguments for intermediate data paths if needed
    # parser.add_argument("--intermediate-output-dir", type=str, default="/opt/ml/processing/intermediate", help="Directory for intermediate output.")

    args = parser.parse_args()

    # --- Run first sample1 ---
    print("--- Starting first sample1 run ---")
    config_file1 = find_config_file(args.config_dir1)
    success1 = run_sample1_from_config(config_file1)
    if not success1:
        print("First sample1 run failed. Exiting.")
        sys.exit(1)
    print("--- First sample1 run finished ---")

    # --- Placeholder for using output of first run ---
    # (Logic remains the same, potentially modifying config_file2 or passing data)

    # --- Run second sample1 ---
    print("\n--- Starting second sample1 run ---")
    config_file2 = find_config_file(args.config_dir2)
    # Potentially modify run_sample1_from_config call or the config file based on step 1 output here
    success2 = run_sample1_from_config(config_file2)
    if not success2:
        print("Second sample1 run failed. Exiting.")
        sys.exit(1)
    print("--- Second sample1 run finished ---")

    print("\nBoth sample1 runs completed successfully.")
    sys.exit(0)
