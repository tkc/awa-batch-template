import json
import os
import sys
from typing import Any, TypeVar

from pydantic import BaseModel, ValidationError

T = TypeVar("T", bound=BaseModel)


def load_config_from_file(model_class: type[T], config_file: str) -> T:
    """指定されたJSONファイルから設定を読み込む"""
    print(f"Loading config from JSON file: {config_file}")
    try:
        with open(config_file) as f:
            config_data = json.load(f)
        return model_class(**config_data)
    except FileNotFoundError:
        print(f"Error: Configuration file not found at {config_file}", file=sys.stderr)
        raise
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON from {config_file}: {e}", file=sys.stderr)
        raise ValueError("Invalid JSON format in configuration file.") from e
    except ValidationError as e:
        print(f"Error validating configuration from {config_file}:", file=sys.stderr)
        print(e, file=sys.stderr)
        raise ValueError("Configuration validation failed.") from e


def load_config_from_env(model_class: type[T], override: bool = False) -> T:
    """
    環境変数から設定を読み込む。
    モデルのフィールド名の大文字版を環境変数名として使用する。
    """
    print("Loading config from environment variables.")
    config_data: dict[str, Any] = {}
    env_vars_found = False

    for field_name in model_class.model_fields.keys():
        env_var_name = field_name.upper()
        if env_var_name in os.environ:
            config_data[field_name] = os.environ[env_var_name]
            env_vars_found = True

    if not env_vars_found:
        print(
            "No relevant environment variables found for configuration.",
            file=sys.stderr,
        )

    try:
        model_instance = model_class(**config_data)
        print("Configuration successfully loaded/validated from environment variables.")
        return model_instance
    except ValidationError as e:
        print(
            "Error validating configuration from environment variables:",
            file=sys.stderr,
        )
        print(e, file=sys.stderr)
        raise ValueError("Configuration validation failed.") from e


def load_config(model_class: type[T]) -> T:
    """
    AWS Batch スタイルの CONFIG_JSON 環境変数、または個別の環境変数から設定を読み込む。
    CONFIG_JSON が存在すれば優先される。
    (現在は直接使用されていないが、将来のために残しておく)
    """
    if "CONFIG_JSON" in os.environ:
        print("Loading config from CONFIG_JSON environment variable.")
        try:
            config_data = json.loads(os.environ["CONFIG_JSON"])
            return model_class(**config_data)
        except json.JSONDecodeError as e:
            print(f"Error decoding CONFIG_JSON: {e}", file=sys.stderr)
            raise ValueError("Invalid JSON format in CONFIG_JSON.") from e
        except ValidationError as e:
            print("Error validating configuration from CONFIG_JSON:", file=sys.stderr)
            print(e, file=sys.stderr)
            raise ValueError("Configuration validation failed.") from e
    else:
        return load_config_from_env(model_class)
