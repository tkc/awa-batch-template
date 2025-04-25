# AWS Batch ジョブ送信スクリプト実行用 Makefile

# デフォルト設定値
EC2_JOB_QUEUE = awa-batch-dev-ec2
EC2_JOB_DEFINITION = awa-batch-dev-ec2-sample1
FARGATE_JOB_QUEUE = awa-batch-dev-fargate 
FARGATE_JOB_DEFINITION = awa-batch-dev-fargate-sample
REGION = ap-northeast-1
SHARE_ID = A1
SCHEDULING_PRIORITY = 10
ARRAY_SIZE = 2
VCPUS = 2
VCPU = 1
MEMORY = 2048
COMMAND = '["echo", "Hello from AWS Batch"]'
ENV = '{"TEST_KEY":"test_value"}'
PARAMS_FILE = parameters.json

# Python仮想環境のパス
VENV = .venv
PYTHON = $(VENV)/bin/python

# 仮想環境のアクティベート
.PHONY: activate
activate:
	source $(VENV)/bin/activate

# すべてのジョブを実行
.PHONY: run-all
run-all: ec2-simple fargate-simple ec2-overrides fargate-overrides \
         ec2-resource fargate-resource ec2-array fargate-array \
         ec2-params fargate-params

# すべてのEC2ジョブを実行
.PHONY: run-all-ec2
run-all-ec2: ec2-simple ec2-overrides ec2-resource ec2-array ec2-params

# すべてのFargateジョブを実行
.PHONY: run-all-fargate
run-all-fargate: fargate-simple fargate-overrides fargate-resource fargate-array fargate-params

# EC2 ジョブ
.PHONY: ec2-simple
ec2-simple:
	@echo "Submitting EC2 simple job..."
	$(PYTHON) ec2_simple_submit_job.py --job-queue $(EC2_JOB_QUEUE) --job-definition $(EC2_JOB_DEFINITION) --region $(REGION)

.PHONY: ec2-overrides
ec2-overrides:
	@echo "Submitting EC2 job with overrides..."
	$(PYTHON) ec2_submit_job_with_overrides.py --job-queue $(EC2_JOB_QUEUE) --job-definition $(EC2_JOB_DEFINITION) \
		--region $(REGION) --command $(COMMAND) --environment $(ENV)

.PHONY: ec2-resource
ec2-resource:
	@echo "Submitting EC2 job with resource settings..."
	$(PYTHON) ec2_submit_resource_job.py --job-queue $(EC2_JOB_QUEUE) --job-definition $(EC2_JOB_DEFINITION) \
		--region $(REGION) --vcpus $(VCPUS) --memory $(MEMORY)

.PHONY: ec2-array
ec2-array:
	@echo "Submitting EC2 array job..."
	$(PYTHON) ec2_submit_array_job.py --job-queue $(EC2_JOB_QUEUE) --job-definition $(EC2_JOB_DEFINITION) \
		--region $(REGION) --array-size $(ARRAY_SIZE)

# Fargate ジョブ
.PHONY: fargate-simple
fargate-simple:
	@echo "Submitting Fargate simple job..."
	$(PYTHON) fargate_simple_submit_job.py --job-queue $(FARGATE_JOB_QUEUE) --job-definition $(FARGATE_JOB_DEFINITION) \
		--region $(REGION)

.PHONY: fargate-overrides
fargate-overrides:
	@echo "Submitting Fargate job with overrides..."
	$(PYTHON) fargate_submit_job_with_overrides.py --job-queue $(FARGATE_JOB_QUEUE) --job-definition $(FARGATE_JOB_DEFINITION) \
		--region $(REGION) --command $(COMMAND) --environment $(ENV)

.PHONY: fargate-resource
fargate-resource:
	@echo "Submitting Fargate job with resource settings..."
	$(PYTHON) fargate_submit_resource_job.py --job-queue $(FARGATE_JOB_QUEUE) --job-definition $(FARGATE_JOB_DEFINITION) \
		--region $(REGION) --vcpu $(VCPU) --memory $(MEMORY)

.PHONY: fargate-array
fargate-array:
	@echo "Submitting Fargate array job..."
	$(PYTHON) fargate_submit_array_job.py --job-queue $(FARGATE_JOB_QUEUE) --job-definition $(FARGATE_JOB_DEFINITION) \
		--region $(REGION) --array-size $(ARRAY_SIZE)

# パラメータファイルを使用するジョブ
.PHONY: ec2-params
ec2-params:
	@echo "Submitting EC2 job with parameters file..."
	$(PYTHON) ec2_submit_job_with_params.py --job-queue $(EC2_JOB_QUEUE) --job-definition $(EC2_JOB_DEFINITION) \
		--region $(REGION) --params-file $(PARAMS_FILE)

.PHONY: fargate-params
fargate-params:
	@echo "Submitting Fargate job with parameters file..."
	$(PYTHON) fargate_submit_job_with_params.py --job-queue $(FARGATE_JOB_QUEUE) --job-definition $(FARGATE_JOB_DEFINITION) \
		--region $(REGION) --params-file $(PARAMS_FILE)

# 環境変数オーバーライドを使用するジョブ（テスト用）
.PHONY: fargate-env-override
fargate-env-override:
	@echo "Submitting Fargate job with environment variable overrides..."
	$(PYTHON) fargate_submit_job_with_env_override.py --job-queue $(FARGATE_JOB_QUEUE) --job-definition $(FARGATE_JOB_DEFINITION) \
		--region $(REGION) --params-file $(PARAMS_FILE)

# 個別のパラメータ送信テスト - 環境変数オーバーライド方式
.PHONY: test-env-override
test-env-override:
	@echo "Testing parameter passing using environment variable overrides..."
	$(PYTHON) fargate_submit_job_with_env_override.py --job-queue $(FARGATE_JOB_QUEUE) --job-definition $(FARGATE_JOB_DEFINITION) \
		--region $(REGION) --params-file $(PARAMS_FILE)
	@echo "Submitting job with environment variable overrides completed. Check CloudWatch Logs for results."

.PHONY: run-with-venv
run-with-venv:
	@echo "Running all jobs with activated virtual environment..."
	source $(VENV)/bin/activate && $(MAKE) run-all

# ヘルプ表示
.PHONY: help
help:
	@echo "AWS Batch ジョブ送信スクリプト実行用 Makefile"
	@echo ""
	@echo "利用可能なコマンド:"
	@echo "  make activate          - 仮想環境をアクティベート"
	@echo "  make run-all           - すべてのジョブを実行"
	@echo "  make run-all-ec2       - すべてのEC2ジョブを実行"
	@echo "  make run-all-fargate   - すべてのFargateジョブを実行"
	@echo "  make run-with-venv     - 仮想環境を活性化してすべてのジョブを実行"
	@echo "  make ec2-simple        - EC2シンプルジョブを実行"
	@echo "  make ec2-overrides     - EC2オーバーライドジョブを実行"
	@echo "  make ec2-resource      - EC2リソース設定ジョブを実行"
	@echo "  make ec2-array         - EC2配列ジョブを実行"
	@echo "  make fargate-simple    - Fargateシンプルジョブを実行"
	@echo "  make fargate-overrides - Fargateオーバーライドジョブを実行"
	@echo "  make fargate-resource  - Fargateリソース設定ジョブを実行"
	@echo "  make fargate-array     - Fargate配列ジョブを実行"
	@echo "  make ec2-params        - EC2パラメータファイル付きジョブを実行"
	@echo "  make fargate-params    - Fargateパラメータファイル付きジョブを実行"
	@echo "  make fargate-env-override - 環境変数オーバーライド方式でFargateジョブを実行"
	@echo "  make test-env-override - 環境変数オーバーライド方式でのパラメータ渡しをテスト"
	@echo "  make help              - このヘルプを表示"
	@echo ""
	@echo "オプション:"
	@echo "  EC2_JOB_QUEUE          - EC2ジョブキュー名 (デフォルト: $(EC2_JOB_QUEUE))"
	@echo "  EC2_JOB_DEFINITION     - EC2ジョブ定義名 (デフォルト: $(EC2_JOB_DEFINITION))"
	@echo "  FARGATE_JOB_QUEUE      - Fargateジョブキュー名 (デフォルト: $(FARGATE_JOB_QUEUE))"
	@echo "  FARGATE_JOB_DEFINITION - Fargateジョブ定義名 (デフォルト: $(FARGATE_JOB_DEFINITION))"
	@echo "  REGION                 - AWSリージョン (デフォルト: $(REGION))"
	@echo "  SHARE_ID               - シェア識別子 (デフォルト: $(SHARE_ID))"
	@echo "  SCHEDULING_PRIORITY    - スケジューリング優先度 (デフォルト: $(SCHEDULING_PRIORITY))"
	@echo "  ARRAY_SIZE             - 配列ジョブサイズ (デフォルト: $(ARRAY_SIZE))"
	@echo "  VCPUS                  - EC2 vCPUs数 (デフォルト: $(VCPUS))"
	@echo "  VCPU                   - Fargate vCPU数 (デフォルト: $(VCPU))"
	@echo "  MEMORY                 - メモリサイズ(MB) (デフォルト: $(MEMORY))"
	@echo "  COMMAND                - コマンド (デフォルト: $(COMMAND))"
	@echo "  ENV                    - 環境変数 (デフォルト: $(ENV))"
	@echo "  PARAMS_FILE            - パラメータファイル (デフォルト: $(PARAMS_FILE))"
	@echo ""
	@echo "例:"
	@echo "  make ec2-simple EC2_JOB_QUEUE=my-queue EC2_JOB_DEFINITION=my-definition"
	@echo "  make fargate-resource VCPU=2 MEMORY=4096"
	@echo "  make test-env-override PARAMS_FILE=custom_parameters.json"

# デフォルトターゲット
.DEFAULT_GOAL := help
