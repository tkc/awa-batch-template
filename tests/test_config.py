import json
from pathlib import Path

import pytest
from pydantic import BaseModel, Field

# テスト対象のモジュールをインポート
from src.config import load_config_from_file

# テスト用の定数
TEST_BATCH_SIZE_FILE = 50
TEST_BATCH_SIZE_ENV = 200
TEST_INPUT_PATH_FILE = "/data/input"
TEST_OUTPUT_PATH_FILE = "/data/output"
TEST_INPUT_PATH_ENV = "/env/input"
TEST_OUTPUT_PATH_ENV = "/env/output"
TEST_OPTIONAL_PARAM_FILE = "test_value"
TEST_OPTIONAL_PARAM_ENV = "env_test"


# テスト用のシンプルなPydanticモデル
class ConfigTestModel(BaseModel):  # Renamed from TestParams
    input_path: str = Field(..., description="入力パス")
    output_path: str = Field(..., description="出力パス")
    batch_size: int = Field(100, description="バッチサイズ")
    debug: bool = Field(False, description="デバッグモード")
    optional_param: str | None = Field(None, description="オプションパラメータ")


# --- load_config_from_file のテスト ---


@pytest.fixture
def valid_config_file(tmp_path: Path) -> str:
    """有効な設定JSONファイルを作成するフィクスチャ"""
    config_data = {
        "input_path": TEST_INPUT_PATH_FILE,
        "output_path": TEST_OUTPUT_PATH_FILE,
        "batch_size": TEST_BATCH_SIZE_FILE,  # Use constant
        "debug": True,
        "optional_param": TEST_OPTIONAL_PARAM_FILE,
    }
    config_path = tmp_path / "valid_config.json"
    with open(config_path, "w") as f:
        json.dump(config_data, f)
    return str(config_path)


@pytest.fixture
def invalid_json_file(tmp_path: Path) -> str:
    """不正なJSON形式のファイルを作成するフィクスチャ"""
    config_path = tmp_path / "invalid_json.json"
    with open(config_path, "w") as f:
        f.write("{ invalid json ")
    return str(config_path)


@pytest.fixture
def invalid_schema_file(tmp_path: Path) -> str:
    """スキーマに合わないJSONファイルを作成するフィクスチャ"""
    config_data = {
        "input_path": TEST_INPUT_PATH_FILE,
        # output_path が欠けている
        "batch_size": "not_an_int",  # 型が違う
    }
    config_path = tmp_path / "invalid_schema.json"
    with open(config_path, "w") as f:
        json.dump(config_data, f)
    return str(config_path)


def test_load_config_from_file_success(valid_config_file: str):
    """正常系: 有効なJSONファイルから設定を読み込めるか"""
    params = load_config_from_file(
        ConfigTestModel, valid_config_file
    )  # Updated class name
    assert params.input_path == TEST_INPUT_PATH_FILE
    assert params.output_path == TEST_OUTPUT_PATH_FILE
    assert params.batch_size == TEST_BATCH_SIZE_FILE  # Use constant
    assert params.debug is True
    assert params.optional_param == TEST_OPTIONAL_PARAM_FILE


def test_load_config_from_file_not_found():
    """異常系: 存在しないファイルを指定した場合にFileNotFoundErrorが発生するか"""
    with pytest.raises(FileNotFoundError):
        load_config_from_file(
            ConfigTestModel, "non_existent_file.json"
        )  # Updated class name


def test_load_config_from_file_invalid_json(invalid_json_file: str):
    """異常系: 不正なJSONファイルを指定した場合にValueErrorが発生するか"""
    with pytest.raises(ValueError, match="Invalid JSON format"):
        load_config_from_file(ConfigTestModel, invalid_json_file)  # Updated class name


def test_load_config_from_file_invalid_schema(invalid_schema_file: str):
    """異常系: スキーマに合わないJSONファイルを指定した場合にValueErrorが発生するか"""
    with pytest.raises(ValueError, match="Configuration validation failed"):
        load_config_from_file(
            ConfigTestModel, invalid_schema_file
        )  # Updated class name


# --- load_config_from_env のテストは削除 ---
