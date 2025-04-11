from pathlib import Path

import pytest
from batch_processor.errors import (
    ProcessingError,
)
from batch_processor.main import sample1
from batch_processor.models import Sample1Params
from pydantic import ValidationError

# Define path to sample data relative to this test file
SAMPLE_DATA_DIR = Path(__file__).parent.parent / "data"
VALID_CSV = SAMPLE_DATA_DIR / "sample1_data.csv"


# Fixture for invalid CSV (schema violation)
@pytest.fixture
def invalid_schema_csv(tmp_path):
    invalid_data = (
        "id,name,age,score\n1,Alice,twenty,100"  # age is not int, score is ok
    )
    file_path = tmp_path / "invalid_schema.csv"
    file_path.write_text(invalid_data)
    return str(file_path)


# Fixture for invalid CSV format (not CSV)
@pytest.fixture
def invalid_format_csv(tmp_path):
    file_path = tmp_path / "invalid_format.txt"
    file_path.write_text("this is not a csv file")
    return str(file_path)


def test_sample1_success(log):
    """正常なパラメータと有効なCSVでsample1を実行"""
    params = Sample1Params(process_id="test_success", csv_path=str(VALID_CSV))
    sample1(params)
    # pytest-structlog の log フィクスチャでログを検証
    assert log.has("sample1処理を開始します", process_id="test_success")
    assert log.has(f"入力CSVファイル: {VALID_CSV}", process_id="test_success")
    assert log.has("データ検証に成功しました", process_id="test_success")
    assert log.has("sample1処理が正常に完了しました", process_id="test_success")


def test_sample1_missing_value():
    """必須パラメータ 'csv_path' または 'process_id' が欠けている場合にエラーが発生するか"""
    with pytest.raises(ValidationError) as excinfo:
        _ = Sample1Params(process_id="test_missing_csv")  # csv_path is missing
    assert "csv_path" in str(excinfo.value)
    assert "Field required" in str(excinfo.value)

    with pytest.raises(ValidationError) as excinfo:
        _ = Sample1Params(csv_path="dummy.csv")  # process_id is missing
    assert "process_id" in str(excinfo.value)
    assert "Field required" in str(excinfo.value)


def test_sample1_invalid_param_type():
    """不正な型のパラメータでモデル作成時にエラーが発生するか"""
    with pytest.raises(ValidationError) as excinfo:
        _ = Sample1Params(
            process_id="test_invalid_type", csv_path=123
        )  # csv_path is int
    assert "csv_path" in str(excinfo.value)
    assert "Input should be a valid string" in str(excinfo.value)

    with pytest.raises(ValidationError) as excinfo:
        _ = Sample1Params(process_id=123, csv_path="dummy.csv")  # process_id is int
    assert "process_id" in str(excinfo.value)
    assert "Input should be a valid string" in str(excinfo.value)


def test_sample1_file_not_found(log):
    """存在しないCSVファイルパスでsample1を実行し、ProcessingErrorが発生するか"""
    params = Sample1Params(
        process_id="test_not_found", csv_path="non_existent_file.csv"
    )
    # Expect ProcessingError because main.py wraps FileNotFoundError
    with pytest.raises(ProcessingError) as excinfo:
        sample1(params)
    # Check the wrapped exception message
    assert "No such file or directory: 'non_existent_file.csv'" in str(excinfo.value)
    # Check for the specific log message indicating the wrapped error
    assert log.has(
        "データ処理中に予期せぬエラーが発生しました",
        process_id="test_not_found",
        level="error",
    )
    # Optionally check if the original exception type is mentioned in the log event's details
    # This depends on how structlog is configured to handle exceptions
    # assert any("FileNotFoundError" in event.get("exception", "") for event in log.events)


def test_sample1_invalid_format(log, invalid_format_csv):
    """不正な形式のCSVファイルでsample1を実行し、ProcessingErrorが発生するか"""
    params = Sample1Params(
        process_id="test_invalid_format", csv_path=invalid_format_csv
    )
    # Expect ProcessingError because SchemaError during validation is wrapped
    with pytest.raises(ProcessingError) as excinfo:
        sample1(params)
    # Check the wrapped exception message
    assert "column 'this is not a csv file' not in DataFrameSchema" in str(
        excinfo.value
    )
    # Check for the specific log message indicating the wrapped error
    assert log.has(
        "データ処理中に予期せぬエラーが発生しました",
        process_id="test_invalid_format",
        level="error",
    )
    # Optionally check if the original exception type is mentioned
    # assert any("pandera.errors.SchemaError" in event.get("exception", "") for event in log.events)


def test_sample1_invalid_schema(log, invalid_schema_csv):
    """スキーマ違反のCSVでsample1を実行し、ProcessingErrorが発生するか"""
    params = Sample1Params(
        process_id="test_invalid_schema", csv_path=invalid_schema_csv
    )
    # Expect ProcessingError because SchemaError during validation is wrapped
    with pytest.raises(ProcessingError) as excinfo:
        sample1(params)
    # Check the wrapped exception message
    assert "Error while coercing 'age' to type int64" in str(excinfo.value)
    # Check for the specific log message indicating the wrapped error
    assert log.has(
        "データ処理中に予期せぬエラーが発生しました",
        process_id="test_invalid_schema",
        level="error",
    )
    # Optionally check if the original exception type is mentioned
    # assert any("pandera.errors.SchemaError" in event.get("exception", "") for event in log.events)
