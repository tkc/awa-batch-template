import pandas as pd
from pandera.errors import SchemaError

from src.logger_config import get_logger
from src.models import Sample1Params
from src.schemas import validate_sample1_data

logger = get_logger(__name__)


def sample1(params: Sample1Params) -> None:
    logger.info("sample1コマンドを実行します")  # Add expected log message
    logger.info("params", params=params.model_dump())

    input_path = params.input_path
    logger.info(f"入力ファイル: {input_path}")

    try:
        df = pd.read_csv(input_path)
        logger.info(f"CSVファイルを読み込みました: {df.shape[0]}行 x {df.shape[1]}列")

        try:
            df = validate_sample1_data(df)
            logger.info("データ検証に成功しました")
            print("done sample1")
        except SchemaError as e:
            logger.exception("データ検証に失敗しました", error_details=str(e))
            return

    except Exception:
        logger.exception("sample1 処理中に予期せぬエラーが発生しました")
        return

    logger.info("sample1コマンドが完了しました")
