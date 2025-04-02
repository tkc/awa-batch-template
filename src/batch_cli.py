import sys

import fire

from src.config import load_config_from_env
from src.main import sample1
from src.models import Sample1Params


class BatchCliCommands:
    """AWS Batch実行用CLIコマンド群"""

    def sample1(self):
        """sample1 コマンドを環境変数から実行"""
        try:
            params = load_config_from_env(Sample1Params)
            sample1(params)
        except ValueError as e:
            print(f"エラー: {e}", file=sys.stderr)
            sys.exit(1)


def main():
    """Batch CLIのエントリポイント"""
    fire.Fire(BatchCliCommands())


if __name__ == "__main__":
    main()
