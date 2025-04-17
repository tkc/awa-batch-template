# AWS Batch 運用ガイド

このリポジトリは、AWS Batch の効率的な運用と管理のためのガイドラインを提供します。小規模および大規模処理の両方に対応するための戦略、コンテナーバージョンの更新方法、スケーリング設定などについて詳しく解説しています。

## コンテンツ一覧

このリポジトリには以下のドキュメントが含まれています：

### [BLUE_GREEN.md](BLUE_GREEN.md)

AWS Batch のコンテナーバージョン更新ガイド。既存環境を維持しながら安全に新バージョンへ移行するためのブルー/グリーンデプロイメント方式について解説しています。EC2 コンピューティング環境と Fargate コンピューティング環境の両方の更新手順、移行のベストプラクティス、トラブルシューティングのヒントが含まれています。

### [EC2_SCALING_STRATEGY.md](EC2_SCALING_STRATEGY.md)

AWS Batch EC2 シンプルスケーリング設定ガイド。単一環境でさまざまなワークロードに対応するための基本的なスケーリング設定について説明しています。EC2 環境でのスケーリングのメカニズムから各ワークロードタイプに最適なスケーリング設定、モニタリングとチューニングのベストプラクティスまでカバーしています。

### [FARGATE_SCALING_STRATEGY.md](FARGATE_SCALING_STRATEGY.md)

AWS Batch Fargate スケーリング設定ガイド。サーバーレスコンピューティングを利用した Fargate でのスケーリング設定について解説しています。Fargate の特徴、基本的なスケーリング設定、Fargate Spot の活用方法、ワークロード別のリソース設定などを含みます。

### [EC2_FARGATE_DIFFERENCES.md](EC2_FARGATE_DIFFERENCES.md)

AWS Batch の EC2 と Fargate のオートスケーリング比較。両環境のスケーリングアプローチの根本的な違い、機能比較、ユースケース別の選択ガイド、性能とコストの考慮点について詳しく解説しています。

## ディレクトリ構造

```bash
├── README.md
└── example                  # サンプル実装
    └── batch                # AWS Batch関連のリソース
        ├── container        # コンテナ定義
        │   ├── latest       # 最新バージョンのコンテナ
        │   │   ├── Dockerfile           # コンテナイメージ定義
        │   │   ├── README.md            # コンテナの説明
        │   │   ├── build_and_push.sh    # ビルド＆ECRプッシュスクリプト
        │   │   ├── pyproject.toml       # Pythonプロジェクト設定
        │   │   ├── run_batch.py         # バッチ処理メインスクリプト
        │   │   └── uv.lock              # 依存関係ロックファイル
        │   └── test         # テスト用コンテナ
        │       ├── Dockerfile           # テスト用コンテナ定義
        │       ├── README.md            # テストコンテナの説明
        │       ├── build_and_push.sh    # テスト用ビルドスクリプト
        │       └── run_batch.py         # テスト用バッチスクリプト
        ├── job             # ジョブ定義とサブミットスクリプト
        │   └── version_test # バージョンテスト用ジョブ
        │       ├── Makefile             # ビルド・デプロイ用Makefile
        │       ├── README.md            # ジョブの説明
        │       ├── config.py            # 設定ファイル
        │       ├── ec2_simple_submit_job.py         # EC2用シンプルジョブ投入
        │       ├── ec2_submit_array_job.py          # EC2用配列ジョブ投入
        │       ├── ec2_submit_job_with_overrides.py # パラメータ上書きジョブ
        │       ├── ec2_submit_job_with_params.py    # パラメータ付きジョブ
        │       ├── ec2_submit_resource_job.py       # リソース指定ジョブ
        │       ├── fargate_simple_submit_job.py     # Fargate用シンプルジョブ
        │       ├── fargate_submit_array_job.py      # Fargate用配列ジョブ
        │       ├── fargate_submit_job_with_env_override.py # 環境変数上書き
        │       ├── fargate_submit_job_with_overrides.py    # パラメータ上書き
        │       ├── fargate_submit_job_with_params.py       # パラメータ付き
        │       ├── fargate_submit_resource_job.py          # リソース指定
        │       ├── parameters.json      # ジョブパラメータ定義
        │       ├── pyproject.toml       # Pythonプロジェクト設定
        │       ├── run_batch.py         # バッチ実行スクリプト
        │       └── uv.lock              # 依存関係ロックファイル
        └── terraform        # インフラ定義（Terraform）
            ├── Makefile              # Terraform操作用Makefile
            ├── README.md             # Terraformの説明
            ├── environments          # 環境別設定
            │   └── dev               # 開発環境設定
            └── modules               # Terraformモジュール
                ├── ecr               # ECRリポジトリ設定
                ├── iam               # IAMロールとポリシー
                ├── network           # VPCとネットワーク設定
                ├── resources_ec2     # EC2コンピュートリソース
                └── resources_fargate # Fargateコンピュートリソース
```

### 主要ディレクトリの説明

- **example/batch/container/**: バッチジョブ実行用の Docker コンテナ定義

  - **latest/**: 最新バージョンのコンテナイメージ定義
  - **test/**: テスト用のコンテナイメージ定義

- **example/batch/job/**: ジョブ定義と投入スクリプト

  - **version_test/**: 様々なタイプのジョブをテストするための実装例
    - EC2 と Fargate の両方のコンピュートタイプのサンプルを含む
    - 単純なジョブ、配列ジョブ、パラメータ付きジョブなど様々なパターン

- **example/batch/terraform/**: AWS リソースをコードとして定義
  - **environments/**: 環境別（開発・本番など）の設定
  - **modules/**: 再利用可能な Terraform モジュール
    - ECR、IAM、ネットワーク、コンピュートリソースなどの定義
