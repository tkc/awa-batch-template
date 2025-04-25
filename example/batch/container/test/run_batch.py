#!/usr/bin/env python3
"""
AWS Batchコンテナ内でパラメータを取得するスクリプト - Pydantic版
"""
import sys
import os
import json
from typing import Optional, Literal
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings


# CONFIG パラメータ
# {
#   "inputFile": "s3://example-bucket/input/data.csv",
#   "outputPath": "s3://example-bucket/output/",
#   "settings": {
#     "batchSize": 64,
#     "modelType": "classification",
#     "maxIterations": 100,
#     "learningRate": 0.01
#   },
#   "metadata": {
#     "jobType": "batch-processing",
#     "version": "1.0.0",
#     "description": "サンプルバッチ処理ジョブ"
#   }
# }


class JobSettings(BaseModel):
    """バッチジョブの処理設定"""
    batchSize: int = 64
    modelType: Literal["classification"] = "classification"
    maxIterations: int = 100
    learningRate: float = 0.01


class Metadata(BaseModel):
    """ジョブのメタデータ情報"""
    jobType: str
    version: str
    description: str


class BatchJobConfig(BaseSettings):
    """バッチ処理ジョブの設定"""
    inputFile: str
    outputPath: str
    settings: JobSettings
    metadata: Metadata
    
    @classmethod
    def from_env(cls, env_var_name: str = "CONFIG"):
        """
        環境変数からJSONを読み込んでモデルを生成する
        
        Args:
            env_var_name: JSONを含む環境変数名
            
        Returns:
            BatchJobConfig: 設定モデル
            
        Raises:
            ValueError: 環境変数が見つからないか、JSONとして無効な場合
        """
        json_str = os.environ.get(env_var_name)
        if not json_str:
            raise ValueError(f"環境変数 {env_var_name} が設定されていません")
            
        try:
            config_dict = json.loads(json_str)
            return cls(**config_dict)
        except json.JSONDecodeError:
            raise ValueError(f"環境変数 {env_var_name} に有効なJSONが含まれていません")
        except Exception as e:
            raise ValueError(f"設定の解析中にエラーが発生しました: {str(e)}")


def main():
    try:
        print("=== バッチジョブ開始 ===")
        print("version: 1.0.6")
        
        # 基本的な環境変数を表示
        print("\n=== 基本環境変数 ===")
        print(f"ENVIRONMENT: {os.environ.get('ENVIRONMENT', '未設定')}")
        print(f"AWS_BATCH_JOB_ID: {os.environ.get('AWS_BATCH_JOB_ID', '未設定')}")
        print(f"AWS_BATCH_JOB_ATTEMPT: {os.environ.get('AWS_BATCH_JOB_ATTEMPT', '未設定')}")
        print(f"AWS_BATCH_JOB_QUEUE: {os.environ.get('AWS_BATCH_JOB_QUEUE', '未設定')}")
        
        # JSONパラメータの取得とPydanticモデル化
        print("\n=== JSONパラメータの取得（Pydanticモデル使用）===")
        try:
            # 生のJSONも出力
            config_json = os.environ.get('CONFIG', '{}')
            print("生のJSON:")
            print(config_json)
 
            # Pydanticモデルで処理
            config = BatchJobConfig.from_env()
            print("\nPydanticモデルで解析:")
            print(f"入力ファイル: {config.inputFile}")
            print(f"出力パス: {config.outputPath}")
            print(f"バッチサイズ: {config.settings.batchSize}")
            print(f"モデルタイプ: {config.settings.modelType}")
            print(f"最大イテレーション: {config.settings.maxIterations}")
            print(f"学習率: {config.settings.learningRate}")
            print(f"ジョブタイプ: {config.metadata.jobType}")
            print(f"バージョン: {config.metadata.version}")
            print(f"説明: {config.metadata.description}")
            
            # 検証済みモデルをJSON形式で出力
            print("\n検証済みモデル（JSON形式）:")
            print(config.model_dump_json(indent=2, ensure_ascii=False))
            
        except ValueError as e:
            print(f"設定の読み込み中にエラーが発生しました: {e}", file=sys.stderr)
        except Exception as e:
            print(f"予期しないエラーが発生しました: {e}", file=sys.stderr)
            
    except Exception as e:
        print(f"実行中にエラーが発生しました: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
