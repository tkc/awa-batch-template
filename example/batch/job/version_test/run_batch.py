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
        
        # 基本的な環境変数を表示
        print("\n=== 基本環境変数 ===")
        print(f"ENVIRONMENT: {os.environ.get('ENVIRONMENT', '未設定')}")
        print(f"AWS_BATCH_JOB_ID: {os.environ.get('AWS_BATCH_JOB_ID', '未設定')}")
        print(f"AWS_BATCH_JOB_ATTEMPT: {os.environ.get('AWS_BATCH_JOB_ATTEMPT', '未設定')}")
        
        # すべての環境変数を表示
        print("\n=== 全環境変数 ===")
        for key, value in sorted(os.environ.items()):
            print(f"{key}: {value}")
    
        print("\n--- JSONパラメータの取得 ---")
    
        # 複数の方法でパラメータを取得
        found_params = False
        
        # 1. 'CONFIG'パラメータを確認
        if 'CONFIG' in os.environ:
            config_value = os.environ['CONFIG']
            print(f"環境変数CONFIG値: '{config_value}'")
            
            # 値が "Ref::CONFIG" の場合（パラメータ置換が失敗している）
            if config_value == "Ref::CONFIG":
                print("警告: 環境変数CONFIGの値が 'Ref::CONFIG' のままです。パラメータ置換が機能していません。")
            elif not config_value or config_value.strip() == "":
                print("警告: 環境変数CONFIGの値が空です。")
            else:
                try:
                    # JSON文字列をパースする
                    config = json.loads(config_value)
                    print("\nCONFIGパラメータの内容:")
                    print(json.dumps(config, indent=2, ensure_ascii=False))
                    found_params = True
                    
                    # 特定の値にアクセス
                    print("\n特定の値にアクセス:")
                    if 'inputFile' in config:
                        print(f"入力ファイル: {config['inputFile']}")
                    if 'outputPath' in config:
                        print(f"出力パス: {config['outputPath']}")
                    if 'settings' in config:
                        print(f"設定: {json.dumps(config['settings'], indent=2, ensure_ascii=False)}")
                        if 'batchSize' in config['settings']:
                            print(f"バッチサイズ: {config['settings']['batchSize']}")
                        if 'modelType' in config['settings']:
                            print(f"モデルタイプ: {config['settings']['modelType']}")
                except json.JSONDecodeError as e:
                    print(f"JSONパース中にエラーが発生しました: {e}", file=sys.stderr)
                    print(f"パース対象の文字列: '{config_value}'")
        else:
            print("CONFIG環境変数が見つかりません", file=sys.stderr)
        
        # 2. PARAM_で始まる環境変数を確認
        param_vars = {}
        for key, value in os.environ.items():
            if key.startswith('PARAM_'):
                param_name = key[6:].lower()  # PARAM_を除去して小文字に変換
                param_vars[param_name] = value
                
                # JSON形式の場合はパースを試みる
                try:
                    param_vars[param_name] = json.loads(value)
                except:
                    # パースできない場合は文字列のまま
                    pass
        
        if param_vars:
            print("\n個別のPARAM_環境変数:")
            print(json.dumps(param_vars, indent=2, ensure_ascii=False))
            found_params = True
            
            # 特定の値にアクセス
            if 'inputfile' in param_vars:
                print(f"入力ファイル: {param_vars['inputfile']}")
            if 'outputpath' in param_vars:
                print(f"出力パス: {param_vars['outputpath']}")
            if 'settings' in param_vars:
                print(f"設定: {json.dumps(param_vars['settings'], indent=2, ensure_ascii=False)}")
        
        if not found_params:
            print("パラメータが見つかりませんでした。以下のいずれかを確認してください:")
            print("1. AWS Batchのジョブ定義でパラメータ置換が正しく設定されているか")
            print("2. ジョブ送信時にcontainerOverridesで環境変数が設定されているか")
            print("3. ジョブ送信時にparametersで値が渡されているか")
            print("\n利用可能な環境変数:")
            for key in sorted(os.environ.keys()):
                print(f"  {key}")
        else:
            # 実際の処理を実行
            print("\n=== 処理開始 ===")
            print("パラメータを使った処理を実行します...")
            # 実際の処理コードをここに記述
            
            print("\n=== 処理完了 ===")
        
        # 成功したことをログに記録
        print("\n=== バッチジョブ正常終了 ===")
        
    except Exception as e:
        print(f"予期しないエラーが発生しました: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
