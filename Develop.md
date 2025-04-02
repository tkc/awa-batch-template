# AWS Batch 開発ガイド

このドキュメントは AWS Batch ジョブの開発とデプロイに関するガイドラインを提供します。

## パラメーター利用方法

AWS Batch ジョブでは、ジョブの実行時に様々なパラメーターを渡す必要があります。ローカル開発時とクラウド実行時の両方で使える効率的なパラメーター管理方法を以下に説明します。

### Pydanic を活用したパラメーター管理

Pydanic を使用すると、強力な型チェックと検証を行いながらパラメーターを管理できます。以下の方法は、ローカル開発環境と AWS Batch 環境の両方で一貫して使用できる方法です。

#### 1. 改善されたアプローチ

以下のコードは、複数のソース（コマンドライン引数、個別の環境変数、JSON 環境変数）から設定を読み込み、Pydantic モデルで検証する改善されたアプローチです。

```python
import json
import os
import sys
import argparse
from typing import Optional, Dict, Any, Type, TypeVar
from pydantic import BaseModel, ValidationError

# シンプルなPydanicモデルの定義例
class Config(BaseModel):
    input_path: str
    output_path: str
    batch_size: int
    debug: bool = False

T = TypeVar('T', bound=BaseModel)

def load_config(model_class: Type[T]) -> T:
    """
    複数のソースから設定を読み込み、Pydanticモデルで検証する。
    優先順位: コマンドライン引数 > 個別環境変数 > JSON環境変数

    ローカル実行例:
    - python main.py --param_json config.json
    - INPUT_PATH=data/input/ OUTPUT_PATH=data/output/ BATCH_SIZE=100 python main.py

    AWS Batch実行例:
    - 環境変数 CONFIG_JSON に JSON 文字列を設定
    - または、個別の環境変数 (INPUT_PATH, OUTPUT_PATH など) を設定
    """
    parser = argparse.ArgumentParser(description="Load configuration for batch job.")
    parser.add_argument('--param_json', type=str, help='Path to JSON parameter file.')
    args, _ = parser.parse_known_args()

    config_data: Dict[str, Any] = {}
    source_description = "Defaults"

    # 1. コマンドライン引数 (--param_json) から読み込み
    if args.param_json:
        if os.path.exists(args.param_json):
            print(f"Loading config from JSON file: {args.param_json}")
            with open(args.param_json, 'r') as f:
                config_data = json.load(f)
            source_description = f"JSON file ({args.param_json})"
        else:
            print(f"Warning: Specified JSON file not found: {args.param_json}", file=sys.stderr)

    # 2. 個別の環境変数から読み込み (JSONファイルがない場合、または上書き)
    #    モデルのフィールド名に基づいて環境変数名を大文字で検索
    env_vars_found = False
    temp_env_config: Dict[str, Any] = {}
    for field_name in model_class.model_fields.keys():
        env_var_name = field_name.upper()
        if env_var_name in os.environ:
            temp_env_config[field_name] = os.environ[env_var_name]
            env_vars_found = True

    if env_vars_found:
        # JSONファイルより環境変数を優先する場合、またはJSONファイルがない場合
        if not config_data or os.environ.get("OVERRIDE_CONFIG_WITH_ENV", "false").lower() == "true":
             print("Loading/Overriding config from individual environment variables.")
             config_data.update(temp_env_config) # update は既存のキーを上書き
             source_description = "Individual environment variables"

    # 3. JSON 文字列の環境変数 (CONFIG_JSON) から読み込み (上記で見つからない場合)
    elif 'CONFIG_JSON' in os.environ:
        print("Loading config from CONFIG_JSON environment variable.")
        try:
            config_data = json.loads(os.environ['CONFIG_JSON'])
            source_description = "CONFIG_JSON environment variable"
        except json.JSONDecodeError as e:
            print(f"Error decoding CONFIG_JSON: {e}", file=sys.stderr)
            # エラーが発生しても、空の辞書で続行し、Pydanticの検証に任せる

    # 4. Pydanticモデルで検証
    try:
        model_instance = model_class(**config_data)
        print(f"Configuration loaded successfully from: {source_description}")
        return model_instance
    except ValidationError as e:
        print(f"Error validating configuration from {source_description}:", file=sys.stderr)
        print(e, file=sys.stderr)
        # どの設定が不足しているか、型が違うかなどの詳細が表示される
        raise ValueError("Configuration validation failed.") from e
    except Exception as e:
        print(f"An unexpected error occurred during configuration loading: {e}", file=sys.stderr)
        raise

def main():
    # 設定を読み込む
    try:
        config = load_config(Config)
        print("\n--- Configuration ---")
        print(f"Input path: {config.input_path}")
        print(f"Output path: {config.output_path}")
        print(f"Batch size: {config.batch_size}")
        print(f"Debug mode: {config.debug}")
        print("---------------------\n")

        # ここに実際の処理を記述
        # ...
        print("Batch job logic would run here.")

    except ValueError as e: # load_config で発生したエラーを捕捉
        print(f"\nConfiguration Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\nAn unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

#### 2. 使用方法

##### ローカル開発環境での使用方法

1.  **JSON ファイルを使用する場合**:

    `config.json`:

    ```json
    {
      "input_path": "data/input/",
      "output_path": "data/output/",
      "batch_size": 100,
      "debug": true
    }
    ```

    実行:

    ```bash
    python main.py --param_json config.json
    ```

2.  **個別の環境変数を使用する場合**:

    実行:

    ```bash
    INPUT_PATH="data/input/" OUTPUT_PATH="data/output/" BATCH_SIZE=100 DEBUG=true python main.py
    ```

    _(注意: 環境変数は通常文字列として渡されるため、`BATCH_SIZE` や `DEBUG` は Pydantic が適切に型変換します)_

3.  **JSON 環境変数を使用する場合**:

    実行:

    ```bash
    CONFIG_JSON='{"input_path": "data/input/", "output_path": "data/output/", "batch_size": 100, "debug": true}' python main.py
    ```

##### AWS CLI 経由での Batch 実行方法

1.  **個別のパラメータを使用する場合 (推奨)**:

    `job_params.json` (AWS CLI の `--parameters` オプション用):

    ```json
    {
      "INPUT_PATH": "s3://my-bucket/input/",
      "OUTPUT_PATH": "s3://my-bucket/output/",
      "BATCH_SIZE": "200",
      "DEBUG": "false"
    }
    ```

    _(注意: Batch パラメータは文字列として渡されるため、Pydantic で型変換が必要です)_

    ジョブ定義 (`my-job-definition`) でこれらのパラメータを受け付けるように設定し、ジョブを送信:

    ```bash
    aws batch submit-job \
        --job-name MyBatchJob \
        --job-queue my-job-queue \
        --job-definition my-job-definition \
        --parameters file://job_params.json
    ```

2.  **JSON 文字列パラメータを使用する場合**:

    `job_config_json.json` (AWS CLI の `--parameters` オプション用):

```json
{
  "input_path": "data/input/",
  "output_path": "data/output/",
  "batch_size": 100,
  "debug": true
}
```

2. スクリプトを実行

```bash
   python main.py --param_json config.json
```

##### AWS CLI 経由での Batch 実行方法

1. ローカルにジョブ定義ファイルを作成

   ```json
   {
     "CONFIG_JSON": "{\"input_path\":\"s3://my-bucket/input/\",\"output_path\":\"s3://my-bucket/output/\",\"batch_size\":200,\"debug\":false}"
   }
   ```

   ジョブ定義 (`my-job-definition`) で `CONFIG_JSON` パラメータを受け付けるように設定し、ジョブを送信:

   ```bash
   aws batch submit-job \
       --job-name MyBatchJob \
       --job-queue my-job-queue \
       --job-definition my-job-definition \
       --parameters file://job_config_json.json
   ```

#### 3. メリット

この改善されたアプローチには以下のメリットがあります：

- **柔軟性**: 複数の設定ソース（ファイル、個別環境変数、JSON 環境変数）をサポート
- **明確な優先順位**: 設定値がどこから来たのか、どの値が優先されるかが明確
- **環境間の一貫性**: ローカルと AWS Batch で同じコードベースを使用可能
- **堅牢な検証**: Pydantic による強力な型チェックとバリデーション、エラーメッセージの改善
- **AWS Batch との親和性**: 個別の環境変数でのパラメータ渡しに対応し、AWS Batch の標準的な使い方に適合しやすい
- **可読性**: 設定の読み込みロジックと Pydantic モデル定義により、設定構造が理解しやすい

#### 3. メリット

このアプローチには以下のメリットがあります：

#### 4. 注意点

- AWS Batch で実行する場合、必要な IAM アクセス権限を設定する必要があります
- 機密情報を含むパラメーターの場合は、AWS Systems Manager の Parameter Store や AWS Secrets Manager の使用も検討してください
- 大規模なプロジェクトでは、設定モジュールを別のファイルとして分離し、再利用可能にすることを推奨します

## CLI ツールの実行

`cli` コマンド (ローカル実行用) と `batch-cli` コマンド (AWS Batch 実行用) を提供します。どちらも `sample1`, `sample2`, `sample3` サブコマンドを持ちます。

### ローカル実行 (`cli` コマンド)

`poetry run cli <サブコマンド> [オプション]` の形式で実行します。

**設定ファイルを使用する場合:**

```bash
# sample1 を設定ファイルで実行
poetry run cli sample1 --config_file=samples/params_sample1.json

# sample2 を設定ファイルで実行
poetry run cli sample2 --config_file=samples/params_sample2.json

# sample3 を設定ファイルで実行
poetry run cli sample3 --config_file=samples/params_sample3.json
```

**ヘルプ表示:**

```bash
poetry run cli --help
poetry run cli sample1 --help
```

### AWS Batch 実行 (`batch-cli` コマンド)

AWS Batch では、`batch-cli` をエントリーポイントとして使用します。ジョブ定義の `command` で `poetry run batch-cli <サブコマンド>` を指定し、必要なパラメータを環境変数として渡します。

**例 (AWS CLI で sample1 を実行):**

ジョブ定義 (`your-job-definition-sample1`) のコマンド例:
`["poetry", "run", "batch-cli", "sample1"]`

ジョブ送信コマンド (パラメータは環境変数として渡される想定):

```bash
aws batch submit-job \
    --job-name MyBatchJobSample1 \
    --job-queue your-job-queue \
    --job-definition your-job-definition-sample1 \
    --container-overrides '{"environment":[{"name":"INPUT_PATH","value":"s3://your-bucket/input/sample1_data.csv"},{"name":"OUTPUT_PATH","value":"s3://your-bucket/output/sample1.csv"},{"name":"BATCH_SIZE","value":"200"},{"name":"DEBUG","value":"false"}]}'
```

_同様に `sample2`, `sample3` 用のジョブ定義と実行コマンドを作成します。_

## Pandera スキーマの拡張

新しいデータ形式に対応するには、`src/schemas.py` にスキーマ定義を追加します。新しいスキーマを作成する手順:

1. `pa.SchemaModel`を継承した新しいクラスを定義
2. 各列のデータ型と検証ルールを定義
3. 必要に応じてカスタム検証関数を追加
4. スキーマを使用する検証関数を作成

例:

```python
import pandera as pa
from pandera.typing import DataFrame, Series # 追加

class NewDataSchema(pa.SchemaModel):
    column1: Series[int] = pa.Field(gt=0)
    column2: Series[str] = pa.Field(str_length={'min': 1, 'max': 100})

    @pa.check("column1")
    def validate_column1(cls, column1: Series) -> Series:
        # カスタム検証ロジック
        return column1 % 2 == 0  # 偶数のみ許可する例

@pa.check_types
def validate_new_data(df: DataFrame[NewDataSchema]) -> DataFrame[NewDataSchema]:
    return df
```
