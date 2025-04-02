from pydantic import BaseModel, Field


# 汎用的な設定の基底クラス
class Config(BaseModel):
    """共通の設定パラメータ (各SampleParamsが継承)"""

    debug: bool = Field(False, description="デバッグモード")
    output_to_s3: bool = Field(False, description="結果をS3にアップロードするかどうか")


class Sample1Params(Config):
    """sample1コマンドのパラメータ"""

    input_path: str = Field(..., description="入力CSVファイルパス")
    output_path: str = Field(..., description="出力ファイルパス")
    batch_size: int = Field(100, description="処理バッチサイズ")
    min_score: int | None = Field(None, description="フィルタリングする最小スコア")
    max_age: int | None = Field(None, description="フィルタリングする最大年齢")
    target_grades: list[int] | None = Field(None, description="処理対象の学年リスト")
