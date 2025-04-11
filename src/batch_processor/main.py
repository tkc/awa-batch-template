import pandas as pd
import structlog  # Import structlog

from batch_processor.errors import (
    BatchProcessingError,
    ConfigError,
    DataValidationError,
    FileFormatError,
    ProcessingError,
    ResourceError,
)
from batch_processor.logger_config import get_logger
from batch_processor.models import Sample1Params
from batch_processor.schemas import (
    validate_sample1_data,
)

logger = get_logger(__name__)


def sample1(params: Sample1Params) -> None:
    """
    サンプル処理1: CSVファイルを読み込み、検証し、処理を行う

    Args:
        params: 処理パラメータ

    Raises:
        ConfigError: パラメータ不正時
        FileFormatError: ファイル形式不正時
        DataValidationError: データ検証失敗時
        ProcessingError: 処理中エラー時
        ResourceError: リソースエラー時
    """
    try:
        # Bind process_id to logger context
        structlog.contextvars.bind_contextvars(process_id=params.process_id)
        logger.info("sample1処理を開始します", params=params.model_dump())

        csv_path = params.csv_path
        if not csv_path:
            raise ConfigError("csv_path が指定されていません", param_name="csv_path")

        logger.info(
            f"入力CSVファイル: {csv_path}"
        )  # process_id will be automatically included by structlog

        try:
            df = pd.read_csv(csv_path)

            # Panderaによるスキーマ検証 (関数を呼び出す)
            df = validate_sample1_data(df)  # Validate using the imported function
            logger.info("データ検証に成功しました")
            print("done sample1 validation")  # Example output

            avg_score = df[
                "score"
            ].mean()  # Assuming 'score' column exists based on StudentDataSchema
            logger.info("スコアの平均値を計算しました", avg_score=avg_score)

        except ResourceError:
            # リソースエラーはそのまま再raise
            raise
        except FileFormatError:
            # ファイル形式エラーはそのまま再raise
            raise
        except DataValidationError:
            # データ検証エラーはそのまま再raise
            raise
        except Exception as e:
            # その他の例外は処理エラーとしてラップ
            logger.exception("データ処理中に予期せぬエラーが発生しました")
            raise ProcessingError(
                message=f"データ処理中に予期せぬエラーが発生しました: {str(e)}",
                process_id=params.process_id,  # Add process_id back
                step="data_processing",
            ) from e

        logger.info(
            "sample1処理が正常に完了しました"
        )  # process_id will be automatically included

    except BatchProcessingError as e:
        # カスタムエラーはログを出力して再raise
        logger.error(
            f"エラーが発生しました: {e}",
            error_code=e.code,
            error_message=e.message,
            error_details=e.details,
        )
        raise

    except Exception as e:
        # 未分類のエラーは BatchProcessingError でラップ
        logger.exception("予期せぬエラーが発生しました")
        raise BatchProcessingError(
            message=f"予期せぬエラーが発生しました: {str(e)}",
            code="E999",
            details={
                "original_error": str(e),
                "process_id": params.process_id,
            },  # Add process_id to details
        ) from e
    finally:
        # Clear logger context after processing
        structlog.contextvars.clear_contextvars()
