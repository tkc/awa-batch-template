from pydantic import BaseModel, Field


class Sample1Params(BaseModel):
    """sample1コマンドのパラメータ"""

    process_id: str = Field(..., description="処理ID (ログコンテキスト用)")
    csv_path: str = Field(..., description="入力CSVファイルパス")
