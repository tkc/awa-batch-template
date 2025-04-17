# 必須変数 (variables.tf で default が設定されていないもの)
ecr_repository_name = "awa-batch-dev-batch"                                                        # ★実際のECRリポジトリ名に要変更★
container_image     = "950534109392.dkr.ecr.ap-northeast-1.amazonaws.com/awa-batch-dev-batch:test" # ★実際のコンテナイメージURIに要変更★

# 基本設定（必要に応じて変更）
aws_region   = "ap-northeast-1"
environment  = "dev"
project_name = "awa-batch"

# Batch設定
batch_job_definition_name      = "batch-job" # ジョブ定義名のベース
batch_job_queue_name           = "batch-job-queue"
batch_compute_environment_name = "batch-compute-env"
instance_types                 = ["m4.large"]
max_vcpus                      = 4
min_vcpus                      = 1 # 元の設定から変更
desired_vcpus                  = 2 # 元の設定から変更
common_env_var_value           = "dev-value"
