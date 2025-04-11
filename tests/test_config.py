import json
from pathlib import Path

import pytest

# テスト対象のモジュールをインポート
from batch_processor.config import load_config_from_file
from batch_processor.models import Sample1Params

# sys.path 操作は不要なため削除

# テスト用の定数
TEST_PROCESS_ID_FILE = "test_config_process_id"
TEST_CSV_PATH_FILE = "data/sample_test.csv"


# --- load_config_from_file のテスト ---


@pytest.fixture
def valid_config_file(tmp_path: Path) -> str:
    """有効な設定JSONファイルを作成するフィクスチャ"""
    config_data = {
        "process_id": TEST_PROCESS_ID_FILE,
        "csv_path": TEST_CSV_PATH_FILE,
    }
    config_path = tmp_path / "valid_config.json"
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config_data, f)
    return str(config_path)


@pytest.fixture
def invalid_json_file(tmp_path: Path) -> str:
    """不正なJSON形式のファイルを作成するフィクスチャ"""
    config_path = tmp_path / "invalid_json.json"
    with open(config_path, "w", encoding="utf-8") as f:
        f.write("{ invalid json ")
    return str(config_path)


@pytest.fixture
def invalid_schema_file(tmp_path: Path) -> str:
    """スキーマに合わないJSONファイルを作成するフィクスチャ (必須フィールド欠損)"""
    config_data = {
        "csv_path": TEST_CSV_PATH_FILE  # process_id が欠けている
    }
    config_path = tmp_path / "invalid_schema.json"
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config_data, f)
    return str(config_path)


def test_load_config_from_file_success(valid_config_file: str):
    """正常系: 有効なJSONファイルから設定を読み込めるか"""
    params = load_config_from_file(Sample1Params, valid_config_file)
    assert isinstance(params, Sample1Params)
    assert params.process_id == TEST_PROCESS_ID_FILE
    assert params.csv_path == TEST_CSV_PATH_FILE


def test_load_config_from_file_not_found():
    """異常系: 存在しないファイルを指定した場合にFileNotFoundErrorが発生するか"""
    with pytest.raises(FileNotFoundError):
        load_config_from_file(Sample1Params, "non_existent_file.json")


def test_load_config_from_file_invalid_json(invalid_json_file: str):
    """異常系: 不正なJSONファイルを指定した場合にValueErrorが発生するか"""
    with pytest.raises(ValueError, match="Invalid JSON format"):
        load_config_from_file(Sample1Params, invalid_json_file)


def test_load_config_from_file_invalid_schema(invalid_schema_file: str):
    """異常系: スキーマに合わないJSONファイルを指定した場合にValueErrorが発生するか"""
    # Expect ValueError because load_config_from_file wraps ValidationError
    with pytest.raises(ValueError, match="Configuration validation failed"):
        load_config_from_file(Sample1Params, invalid_schema_file)
