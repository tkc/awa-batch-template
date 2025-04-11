# AWS Batch開発ガイド

このドキュメントはAWS Batchジョブの開発とデプロイに関するガイドラインを提供します。

## パラメーター利用方法

AWS Batchジョブでは、ジョブの実行時に様々なパラメーターを渡す必要があります。ローカル開発時とクラウド実行時の両方で使える効率的なパラメーター管理方法を以下に説明します。

### Pydanicを活用したパラメーター管理

Pydanicを使用すると、強力な型チェックと検証を行いながらパラメーターを管理できます。以下の方法は、ローカル開発環境とAWS Batch環境の両方で一貫して使用できる方法です。

#### 1. 基本的なアプローチ

以下のコードは、コマンドライン引数からJSONファイルを読み込む方法とAWS Batch環境変数からパラメーターを取得する方法をシンプルに統合したものです：

```python
import json
import os
import sys
import argparse
from typing import Optional, Dict, Any, Type, TypeVar
from pydantic import BaseModel

# シンプルなPydanicモデルの定義例
class Config(BaseModel):
    input_path: str
    output_path: str
    batch_size: int
    debug: bool = False

T = TypeVar('T', bound=BaseModel)

def load_config(model_class: Type[T]) -> T:
    """
    コマンドライン引数またはAWS Batch環境変数からコンフィグを読み込む
    
    ローカル実行: python main.py --param_json config.json
    AWS Batch: 環境変数 CONFIG_JSON に設定値がある場合
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('--param_json', type=str, help='Path to JSON parameter file')
    args, _ = parser.parse_known_args()
    
    config_data: Dict[str, Any] = {}
    
    # 1. まずコマンドライン引数をチェック
    if args.param_json and os.path.exists(args.param_json):
        print(f"Loading config from local file: {args.param_json}")
        with open(args.param_json, 'r') as f:
            config_data = json.load(f)
    
    # 2. JSON文字列の環境変数をチェック
    elif 'CONFIG_JSON' in os.environ:
        print("Loading config from environment variable CONFIG_JSON")
        config_data = json.loads(os.environ['CONFIG_JSON'])
    
    # 3. 設定が見つからない場合はエラー
    else:
        raise ValueError("No configuration found. Please provide --param_json argument or set CONFIG_JSON environment variable.")
    
    # Pydanicモデルに変換してバリデーション
    return model_class(**config_data)

def main():
    # 設定を読み込む
    try:
        config = load_config(Config)
        print("Configuration loaded successfully!")
        print(f"Input path: {config.input_path}")
        print(f"Output path: {config.output_path}")
        print(f"Batch size: {config.batch_size}")
        print(f"Debug mode: {config.debug}")
        
        # ここに実際の処理を記述
        # ...
        
    except Exception as e:
        print(f"Error loading configuration: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

#### 2. 使用方法

##### ローカル開発環境での使用方法

1. シンプルなJSONファイルでパラメーターを定義
   
   `config.json`:
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

##### AWS CLI経由でのBatch実行方法

1. ローカルにジョブ定義ファイルを作成
   
   `job.json`:
   ```json
   {
     "jobName": "MyBatchJob",
     "jobQueue": "my-job-queue",
     "jobDefinition": "my-job-definition",
     "parameters": {
       "CONFIG_JSON": "{\"input_path\":\"s3://my-bucket/input/\",\"output_path\":\"s3://my-bucket/output/\",\"batch_size\":200,\"debug\":false}"
     }
   }
   ```

2. AWS CLIを使用してジョブを送信
   ```bash
   aws batch submit-job --cli-input-json file://job.json
   ```

#### 3. メリット

このアプローチには以下のメリットがあります：

- **シンプルさ**: 最低限の設定読み込み方法に絞ることで複雑さが減少
- **環境間の一貫性**: ローカル開発環境とAWS Batch環境で同じコードが使える
- **型安全性**: Pydanicによる堅牢な型チェックとバリデーション
- **エラー処理**: 設定値の問題を早期に検出
- **可読性**: 設定値の構造が明確で理解しやすい

#### 4. 注意点

- AWS Batchで実行する場合、必要なIAMアクセス権限を設定する必要があります
- 機密情報を含むパラメーターの場合は、AWS Systems ManagerのParameter StoreやAWS Secrets Managerの使用も検討してください
- 大規模なプロジェクトでは、設定モジュールを別のファイルとして分離し、再利用可能にすることを推奨します

## 複数リポジトリのコードを利用する方法

AWS Batchでは、複数のリポジトリのコードを組み合わせてパイプラインを実行することができます。以下に主要なアプローチをいくつか紹介します。

### 1. Dockerイメージ内に複数リポジトリを含める

AWS Batchはコンテナベースで動作するため、カスタムDockerイメージを作成して複数のリポジトリのコードを一つのイメージに含めることができます。

```Dockerfile
FROM python:3.9

# 1つ目のリポジトリをクローン
RUN git clone https://github.com/your-org/repo1.git /app/repo1
WORKDIR /app/repo1
RUN pip install -r requirements.txt

# 2つ目のリポジトリをクローン
RUN git clone https://github.com/your-org/repo2.git /app/repo2
WORKDIR /app/repo2
RUN pip install -r requirements.txt

# メインのワーキングディレクトリを設定
WORKDIR /app

# エントリポイントスクリプト（両方のリポジトリのコードを実行するスクリプト）
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
```

エントリポイントスクリプト例（`entrypoint.sh`）:
```bash
#!/bin/bash
set -e

# PYTHONPATHに両方のリポジトリを追加
export PYTHONPATH=$PYTHONPATH:/app/repo1:/app/repo2

# パイプラインスクリプトを実行
python /app/repo1/src/pipeline.py "$@"
```

#### メリット
- シンプルな実装でコード全体を一つのイメージに統合
- リポジトリ間の依存関係が明示的に管理可能

#### デメリット
- コードが更新されるたびにイメージの再ビルドが必要
- イメージサイズが大きくなる可能性がある

### 2. Git Submodulesを使用する

メインリポジトリから他のリポジトリを参照するためにGit Submodulesを使用できます。

```bash
# メインリポジトリのルートディレクトリで実行
git submodule add https://github.com/your-org/repo1.git lib/repo1
git submodule add https://github.com/your-org/repo2.git lib/repo2
git submodule update --init --recursive
```

Dockerfileの例:
```Dockerfile
FROM python:3.9

# リポジトリをコピー（サブモジュールを含む）
COPY . /app
WORKDIR /app

# サブモジュールのセットアップ
RUN git submodule update --init --recursive

# 各リポジトリの依存関係をインストール
RUN pip install -r lib/repo1/requirements.txt
RUN pip install -r lib/repo2/requirements.txt

# メインスクリプトを実行
ENTRYPOINT ["python", "src/main.py"]
```

メインスクリプト例（`src/main.py`）:
```python
import sys
import os

# サブモジュールをimport可能にする
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'lib', 'repo1'))
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'lib', 'repo2'))

# 各リポジトリのモジュールをインポート
from repo1.module import function1
from repo2.module import function2

def run_pipeline():
    # 両方のリポジトリの機能を組み合わせたパイプライン処理
    function1()
    function2()

if __name__ == "__main__":
    run_pipeline()
```

#### メリット
- リポジトリのバージョン管理が明示的
- 単一のリポジトリで開発することができる
- モジュール間の相互参照が容易

#### デメリット
- サブモジュールの管理が複雑になる可能性がある
- サブモジュールの更新が煩雑になることがある

### 3. 実行時にコードをダウンロード

ジョブ実行時に必要なリポジトリをダウンロードするスクリプトを作成できます：

```python
import os
import sys
import subprocess
import argparse

def setup_repos():
    """必要なリポジトリをクローンしセットアップする"""
    # 作業ディレクトリを作成
    os.makedirs("/tmp/workspace", exist_ok=True)
    
    # リポジトリ1をクローン
    repo1_path = "/tmp/workspace/repo1"
    if not os.path.exists(repo1_path):
        subprocess.run([
            "git", "clone", 
            "https://github.com/your-org/repo1.git", 
            repo1_path
        ], check=True)
    
    # リポジトリ2をクローン
    repo2_path = "/tmp/workspace/repo2"
    if not os.path.exists(repo2_path):
        subprocess.run([
            "git", "clone", 
            "https://github.com/your-org/repo2.git", 
            repo2_path
        ], check=True)
    
    # 依存関係をインストール
    subprocess.run([
        "pip", "install", "-r", 
        os.path.join(repo1_path, "requirements.txt")
    ], check=True)
    
    subprocess.run([
        "pip", "install", "-r", 
        os.path.join(repo2_path, "requirements.txt")
    ], check=True)
    
    # PYTHONPATHを更新
    sys.path.append(repo1_path)
    sys.path.append(repo2_path)
    os.environ["PYTHONPATH"] = f"{os.environ.get('PYTHONPATH', '')}:{repo1_path}:{repo2_path}"
    
    print(f"Repositories set up successfully in {'/tmp/workspace'}")
    return repo1_path, repo2_path

def run_pipeline():
    """パイプライン処理を実行する"""
    # リポジトリをセットアップ
    repo1_path, repo2_path = setup_repos()
    
    # ここで各リポジトリのモジュールをインポート
    sys.path.append(repo1_path)
    sys.path.append(repo2_path)
    
    from repo1.src.module import function1
    from repo2.src.module import function2
    
    # 処理を実行
    function1()
    function2()
    
    print("Pipeline execution completed")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run pipeline using multiple repositories")
    parser.add_argument("--config", help="Path to configuration file")
    args = parser.parse_args()
    
    # 設定ファイルが指定されている場合はそれを使用
    if args.config:
        print(f"Using configuration from {args.config}")
    
    run_pipeline()
```

#### メリット
- 柔軟に最新のコードを取得できる
- リポジトリが大きすぎる場合にコンテナイメージサイズを削減できる
- リポジトリのブランチやコミットハッシュを動的に指定できる

#### デメリット
- 実行時間が長くなる可能性がある（クローン処理のため）
- ネットワーク接続やGitリポジトリへのアクセス権が必要
- 実行時の依存関係に問題が発生する可能性がある

### 4. AWS CodeArtifactを使用したプライベートパッケージ管理

各リポジトリをプライベートPythonパッケージとしてAWS CodeArtifactに公開し、依存関係として利用する方法：

1. 各リポジトリをパッケージ化：
   ```bash
   # setup.pyを作成し、パッケージをビルド
   python setup.py sdist bdist_wheel
   
   # AWS CodeArtifactにパッケージをアップロード
   pip install twine
   export AWS_CODEARTIFACT_TOKEN=$(aws codeartifact get-authorization-token --domain your-domain --domain-owner YOUR_AWS_ACCOUNT_ID --query authorizationToken --output text)
   twine upload --repository-url https://your-domain-YOUR_AWS_ACCOUNT_ID.d.codeartifact.region.amazonaws.com/pypi/your-repo/ dist/*
   ```

2. バッチジョブのDockerfileでパッケージをインストール：
   ```Dockerfile
   FROM python:3.9
   
   # AWS CodeArtifactの認証設定
   RUN pip install awscli
   RUN aws configure set region your-region
   
   # プライベートパッケージをインストール
   RUN AWS_CODEARTIFACT_TOKEN=$(aws codeartifact get-authorization-token --domain your-domain --domain-owner YOUR_AWS_ACCOUNT_ID --query authorizationToken --output text) \
       pip install --index-url https://aws:$AWS_CODEARTIFACT_TOKEN@your-domain-YOUR_AWS_ACCOUNT_ID.d.codeartifact.region.amazonaws.com/pypi/your-repo/simple/ \
       repo1-package repo2-package
   
   # アプリケーションコードをコピー
   COPY . /app
   WORKDIR /app
   
   # エントリポイント
   ENTRYPOINT ["python", "main.py"]
   ```

3. アプリケーションコードで各パッケージを利用：
   ```python
   # 各パッケージからモジュールをインポート
   from repo1_package import module1
   from repo2_package import module2
   
   def run_pipeline():
       # 両方のパッケージの機能を利用
       module1.function1()
       module2.function2()
   
   if __name__ == "__main__":
       run_pipeline()
   ```

#### メリット
- モジュール化されたアプローチで各リポジトリを独立して管理
- バージョン管理が明示的でシンプル
- 依存関係の解決がPythonのパッケージマネージャに任せられる
- コードの再利用が容易

#### デメリット
- 初期設定が複雑
- パッケージのビルドとアップロードのプロセスが必要
- AWS CodeArtifactの費用が発生

### 選択ガイド

以下の基準でアプローチを選択すると良いでしょう：

1. **シンプルさ重視の場合**：「Dockerイメージ内に複数リポジトリを含める」方法
2. **バージョン管理重視の場合**：「Git Submodules」方法
3. **柔軟性重視の場合**：「実行時にコードをダウンロード」方法
4. **大規模プロジェクト向け**：「AWS CodeArtifactを使用したプライベートパッケージ管理」方法

実際のニーズに応じてこれらの方法を組み合わせることも可能です。例えば、主要なコードはCodeArtifactパッケージとして管理し、頻繁に変更される設定スクリプトはGit Submodulesとして管理するなどの組み合わせが考えられます。
