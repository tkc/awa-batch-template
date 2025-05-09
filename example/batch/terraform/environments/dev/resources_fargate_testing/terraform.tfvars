# Terraform 変数値のサンプルファイル
# 実際の環境に合わせて値を変更してください

# 必須変数 (variables.tf で default が設定されていないもの)
ecr_repository_name = "awa-batch-testing-batch"                                                        # ★実際のECRリポジトリ名に要変更★
container_image     = "950534109392.dkr.ecr.ap-northeast-1.amazonaws.com/awa-batch-testing-batch:test" # ★実際のコンテナイメージURIに要変更★

# 基本設定（必要に応じて変更）
aws_region   = "ap-northeast-1"
environment  = "testing"
project_name = "awa-batch"

# Batch設定
batch_job_definition_name      = "batch-job" # ジョブ定義名のベース
batch_job_queue_name           = "batch-job-queue"
batch_compute_environment_name = "batch-compute-env"
max_vcpus                      = 4

# Fargate固有の設定
fargate_vcpu         = 1    # 0.25, 0.5, 1, 2, 4 などの値から選択
fargate_memory       = 2048 # 512, 1024, 2048, 3072, 4096 などから選択
common_env_var_value = "testing-value"

# Slack通知設定
slack_webhook_url = "https://hooks.slack.com/services/XXXXXXXXX/YYYYYYYYY/ZZZZZZZZZZZZZZZZZZZZZZZZ" # ★実際のSlack Webhook URLに要変更★
