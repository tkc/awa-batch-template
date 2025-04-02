import json
from pathlib import Path

import pytest

from src.main import sample1  # batch_job. -> src.
from src.models import Sample1Params  # batch_job. -> src.

SAMPLE_DATA_DIR = Path(__file__).parent.parent / "samples"
VALID_CSV = SAMPLE_DATA_DIR / "sample1_data.csv"
INVALID_CSV_SCORE = SAMPLE_DATA_DIR / "sample1_invalid_score.csv"
PARAMS_JSON = SAMPLE_DATA_DIR / "params_sample1.json"


@pytest.fixture(scope="module", autouse=True)
def create_invalid_csv():
    invalid_data = """id,name,age,score
1,Alice,20,150.0
2,Bob,22,-10.5
"""
    INVALID_CSV_SCORE.write_text(invalid_data)
    yield
    INVALID_CSV_SCORE.unlink()


def test_sample1_valid_data_from_json(log_stream):
    """正常なデータとJSONパラメータでsample1を実行"""
    with open(PARAMS_JSON) as f:
        params_dict = json.load(f)
    params_dict["input_path"] = str(VALID_CSV)
    params = Sample1Params(**params_dict)

    sample1(params)

    log_output = log_stream.getvalue()
    assert "sample1コマンドを実行します" in log_output
    assert "データ検証に成功しました" in log_output


def test_sample1_valid_data_with_filters(log_stream):
    """フィルタリング条件付きで正常なデータでsample1を実行"""
    params_dict = {
        "input_path": str(VALID_CSV),
        "output_path": "output/test_filter_output.csv",
        "min_score": 80,
        "max_age": 21,
        "target_grades": [1],
    }
    params = Sample1Params(**params_dict)

    sample1(params)

    log_output = log_stream.getvalue()
    assert "sample1コマンドを実行します" in log_output
    assert "データ検証に成功しました" in log_output


def test_sample1_invalid_schema(log_stream):
    """スキーマ違反のデータでsample1を実行"""
    params_dict = {
        "input_path": str(INVALID_CSV_SCORE),
        "output_path": "output/test_invalid_schema_output.csv",
    }
    params = Sample1Params(**params_dict)

    sample1(params)

    log_output = log_stream.getvalue()
    # Check for the core message, allowing for additional details
    assert "データ検証に失敗しました" in log_output
    assert "SchemaError" in log_output  # Keep checking for SchemaError details


def test_sample1_file_not_found(log_stream):
    """存在しない入力ファイルでsample1を実行"""
    params_dict = {
        "input_path": "non_existent_file.csv",
        "output_path": "output/test_not_found_output.csv",
    }
    params = Sample1Params(**params_dict)

    sample1(params)

    log_output = log_stream.getvalue()
    # Check for the core message, allowing for additional details
    assert "sample1 処理中に予期せぬエラーが発生しました" in log_output
    assert (
        "FileNotFoundError" in log_output
    )  # Keep checking for FileNotFoundError details


def test_sample1_invalid_param_type():
    """不正な型のパラメータでモデル作成時にエラーが発生するか"""
    invalid_params_dict = {
        "input_path": str(VALID_CSV),
        "output_path": "output/test_invalid_type_output.csv",
        "min_score": "eighty",
    }
    with pytest.raises(ValueError) as excinfo:
        _ = Sample1Params(**invalid_params_dict)

    assert "min_score" in str(excinfo.value)
