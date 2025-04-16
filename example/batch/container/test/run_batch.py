import sys
import os
import json

def main():
    try:
        print("=== バッチジョブ開始 ===")
        
        # 基本的な環境変数を表示
        print("\n=== 基本環境変数 ===")
        print(f"ENVIRONMENT: {os.environ.get('ENVIRONMENT', '未設定')}")
        print(f"AWS_BATCH_JOB_ID: {os.environ.get('AWS_BATCH_JOB_ID', '未設定')}")
        print(f"AWS_BATCH_JOB_ATTEMPT: {os.environ.get('AWS_BATCH_JOB_ATTEMPT', '未設定')}")
        print(f"AWS_BATCH_JOB_QUEUE: {os.environ.get('AWS_BATCH_JOB_QUEUE', '未設定')}")
        
        # パラメータとして渡された環境変数を表示
        print("\n=== パラメータとして渡された環境変数 ===")
        params = {}
        for key, value in os.environ.items():
            # AWS Batchのパラメータは環境変数として渡される
            # 例：{"input_file": "data.csv"} → "input_file": "data.csv" として環境変数に設定される
            if key not in ['ENVIRONMENT', 'AWS_BATCH_JOB_ID', 'AWS_BATCH_JOB_ATTEMPT', 
                         'AWS_BATCH_JOB_QUEUE', 'PATH', 'HOSTNAME', 'HOME', 'AWS_DEFAULT_REGION',
                         'AWS_REGION', 'AWS_EXECUTION_ENV', 'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY']:
                params[key] = value
                print(f"{key}: {value}")
        
        # パラメータが存在する場合、処理ロジックの例
        if 'input_file' in params:
            print(f"\n入力ファイル '{params['input_file']}' を処理します...")
            # ここに実際の処理ロジックを追加
            
        if 'debug_mode' in params and params['debug_mode'].lower() == 'true':
            print("\n=== デバッグモード有効 ===")
            print("すべての環境変数をJSON形式で出力:")
            print(json.dumps({k: v for k, v in os.environ.items() if not k.startswith('AWS_SECRET')}, indent=2))
        
        # 処理成功
        print("\n=== バッチジョブ正常終了 ===")
        
    except ValueError as e:  # Pydantic validation error or load_config_from_env error
        print(f"Configuration or validation error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
