AWS Batch ジョブへの JSON パラメータ渡しの作業整理
作業の背景と目的
AWS Batch ジョブに対して JSON パラメータを渡し、コンテナ内でそれを受け取って処理することが目的でした。
問題の発見と分析

最初の問題: 当初実装したパラメータ渡しでは、コンテナ内で環境変数 CONFIG が見つからなかった
原因分析:

Terraform で定義された AWS Batch のジョブキューにフェアシェアスケジューリングが設定されていた
ジョブ定義にパラメータ置換の設定が不足していた
コンテナ環境変数にパラメータ参照設定がなかった

実装した解決策

1. Terraform の修正

ジョブ定義に parameters フィールドを追加して初期値を設定
コンテナ環境変数に CONFIG を追加して Ref::CONFIG でパラメータ参照

hclparameters = {
"CONFIG" = "{}" # デフォルト値を空の JSON に設定
}

environment = concat(
[
{
name = "CONFIG"
value = "Ref::CONFIG" # パラメータ参照を追加
}
],
var.additional_environment_variables
) 2. コンテナオーバーライド方式の実装
パラメータ置換が機能しなかったため、より直接的な方法を実装:

containerOverrides を使用して環境変数に JSON データを直接設定

pythonresponse = batch.submit_job(
jobName=job_name,
jobQueue=args.job_queue,
jobDefinition=args.job_definition,
containerOverrides={
'environment': [
{
'name': 'CONFIG',
'value': json.dumps(config_data)
}
]
}
) 3. 新しい送信スクリプトの作成

fargate*submit_job_with_env_override.py: 環境変数オーバーライドで JSON パラメータを送信
JSON データをそのまま CONFIG 環境変数に設定
フラット化したパラメータも PARAM*プレフィックスで環境変数に設定

4. コンテナスクリプトの改善

run_batch.py を改善して複数の方法でパラメータを取得できるように
CONFIG 環境変数が"Ref::CONFIG"のままの場合もエラーメッセージを表示
より詳細なエラーハンドリングとデバッグ情報の提供

5. テスト用の Makefile ターゲット追加

test-env-override: 環境変数オーバーライド方式のテスト実行
パラメータファイルの指定や実行オプションを設定可能に

最終的な成果

動作確認: 環境変数オーバーライド方式で JSON パラメータの送信が成功
ログ確認: コンテナ内でパラメータが正しく受け取られ、処理されていることを確認
柔軟性: さまざまなパラメータ形式に対応できる堅牢なスクリプト群
再利用性: 今後の開発のためのテンプレートとして活用可能

今後の推奨アプローチ

環境変数オーバーライド方式を標準とする（信頼性高）
コンテナスクリプトは複数の形式でパラメータを受け取れるように実装
Terraform はシンプルな設定を維持し、複雑なロジックはプログラム側で対応

学んだこと

AWS Batch のパラメータ置換機能は注意が必要で、フェアシェアスケジューリングなど他の機能との連携に制約がある
環境変数オーバーライドを使った直接的な方法が最も確実
スクリプト内でのエラーハンドリングと詳細なログ出力が問題解決に重要

この作業を通じて、AWS Batch ジョブへの複雑なパラメータ渡しが可能になり、より柔軟なジョブ実行環境が整いました。
