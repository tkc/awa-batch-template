import sys  # Add sys import

import fire

from src.config import load_config_from_file  # Remove load_config_from_env
from src.main import sample1
from src.models import Sample1Params


class CliCommands:
    """ローカル実行用CLIコマンド群"""

    def sample1(
        self, config_file: str
    ):  # Make config_file required, remove override_env
        """sample1 コマンドを実行"""
        try:
            # Always load from config_file
            params = load_config_from_file(Sample1Params, config_file)
            sample1(params)
        except (ValueError, FileNotFoundError) as e:
            print(f"エラー: {e}", file=sys.stderr)
            sys.exit(1)


def main():
    """CLIのエントリポイント"""
    fire.Fire(CliCommands())


if __name__ == "__main__":
    main()
