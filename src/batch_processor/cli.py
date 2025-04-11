import sys  # Add sys import

import fire

from batch_processor.config import load_config_from_file
from batch_processor.main import sample1
from batch_processor.models import Sample1Params


class CliCommands:
    """ローカル実行用CLIコマンド群"""

    def sample1(self, config_file: str):
        """sample1 コマンドを実行"""
        try:
            # Load config using the updated Sample1Params model (now with process_id)
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
