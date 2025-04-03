import pytest
import sys # Keep sys import for potential future use
from pathlib import Path
from pydantic import ValidationError

# Import using src prefix
from src.main import sample1
from src.models import Sample1Params
from src.errors import FileFormatError, DataValidationError, ProcessingError # Import specific errors


# Define path to sample data relative to this test file
SAMPLE_DATA_DIR = Path(__file__).parent.parent / "data"
VALID_CSV = SAMPLE_DATA_DIR / "sample1_data.csv"

# Fixture for invalid CSV (schema violation)
@pytest.fixture
def invalid_schema_csv(tmp_path):
    invalid_data = "id,name,age,score\n1,Alice,twenty,100" # age is not int, score is ok
    file_path = tmp_path / "invalid_schema.csv"
    file_path.write_text(invalid_data)
    return str(file_path)

# Fixture for invalid CSV format (not CSV)
@pytest.fixture
def invalid_format_csv(tmp_path):
    file_path = tmp_path / "invalid_format.txt"
    file_path.write_text("this is not a csv file")
    return str(file_path)


def test_sample1_success(log_stream):
    """正常なパラメータと有効なCSVでsample1を実行"""
    params = Sample1Params(process_id="test_success", csv_path=str(VALID_CSV))
    sample1(params)
    log_output = log_stream.getvalue()
    assert "sample1処理を開始します" in log_output # Match the actual log message
    assert f"入力CSVファイル: {VALID_CSV}" in log_output
    assert "データ検証に成功しました" in log_output
    assert "sample1処理が正常に完了しました" in log_output # Match the actual log message


def test_sample1_missing_value():
    """必須パラメータ 'csv_path' または 'process_id' が欠けている場合にエラーが発生するか"""
    with pytest.raises(ValidationError) as excinfo:
        _ = Sample1Params(process_id="test_missing_csv") # csv_path is missing
    assert "csv_path" in str(excinfo.value)
    assert "Field required" in str(excinfo.value)

    with pytest.raises(ValidationError) as excinfo:
        _ = Sample1Params(csv_path="dummy.csv") # process_id is missing
    assert "process_id" in str(excinfo.value)
    assert "Field required" in str(excinfo.value)


def test_sample1_invalid_param_type():
    """不正な型のパラメータでモデル作成時にエラーが発生するか"""
    with pytest.raises(ValidationError) as excinfo:
        _ = Sample1Params(process_id="test_invalid_type", csv_path=123) # csv_path is int
    assert "csv_path" in str(excinfo.value)
    assert "Input should be a valid string" in str(excinfo.value)

    with pytest.raises(ValidationError) as excinfo:
        _ = Sample1Params(process_id=123, csv_path="dummy.csv") # process_id is int
    assert "process_id" in str(excinfo.value)
    assert "Input should be a valid string" in str(excinfo.value)


def test_sample1_file_not_found(log_stream):
    """存在しないCSVファイルパスでsample1を実行し、FileFormatErrorが発生するか"""
    params = Sample1Params(process_id="test_not_found", csv_path="non_existent_file.csv")
    # Expect FileFormatError because read_csv_with_validation raises it
    with pytest.raises(FileFormatError):
        sample1(params)
    log_output = log_stream.getvalue()
    # Check for the specific log message indicating file read failure
    assert "CSVファイルの読み込みに失敗しました" in log_output
    assert "No such file or directory" in log_output


def test_sample1_invalid_format(log_stream, invalid_format_csv):
    """不正な形式のCSVファイルでsample1を実行し、ProcessingErrorが発生するか"""
    params = Sample1Params(process_id="test_invalid_format", csv_path=invalid_format_csv)
    # Expect ProcessingError because SchemaError during validation is wrapped
    with pytest.raises(ProcessingError):
        sample1(params)
    log_output = log_stream.getvalue()
    # Check for the specific log message indicating schema validation failure within processing
    assert "データ処理中に予期せぬエラーが発生しました" in log_output
    assert "column 'this is not a csv file' not in DataFrameSchema" in log_output


def test_sample1_invalid_schema(log_stream, invalid_schema_csv):
    """スキーマ違反のCSVでsample1を実行し、ProcessingErrorが発生するか"""
    params = Sample1Params(process_id="test_invalid_schema", csv_path=invalid_schema_csv)
    # Expect ProcessingError because SchemaError during validation is wrapped
    with pytest.raises(ProcessingError):
        sample1(params)
    log_output = log_stream.getvalue()
    # Check for the specific log message indicating schema validation failure within processing
    assert "データ処理中に予期せぬエラーが発生しました" in log_output
    assert "Error while coercing 'age' to type int64" in log_output
