import io
import logging

import pytest


@pytest.fixture
def log_stream():
    """テスト用にログ出力を StringIO にキャプチャするフィクスチャ"""
    # ルートロガーとbatch_jobロガーを取得
    # (structlogがラップしているため、ラップ前のロガーを取得する必要がある場合があるが、
    #  ここでは get_logger を使って設定を上書きする)
    log_capture_string = io.StringIO()
    test_handler = logging.StreamHandler(log_capture_string)

    # get_logger を使用して、テスト用ハンドラを持つロガーを取得・設定
    # プロジェクト内の主要なロガーを取得してハンドラを設定
    loggers_to_reconfigure = [
        "src.main",  # Updated from batch_job.main
        "src.logger_config",  # Updated from batch_job.logger_config
        # '__main__' # main.pyが直接実行される場合のロガー名
    ]
    original_handlers = {}

    for logger_name in loggers_to_reconfigure:
        logger_instance = logging.getLogger(logger_name)
        original_handlers[logger_name] = logger_instance.handlers[
            :
        ]  # 元のハンドラを保存
        # get_logger は structlog ラッパーを返すので、ラップ前のロガーにアクセスするか、
        # get_logger がハンドラ差し替えをサポートするように修正が必要。
        # 今回は logger_config.py を修正済みと仮定。
        # get_logger(logger_name, handler=test_handler) # これは structlog ラッパーを返す

        # 代わりに、取得したロガーのハンドラを直接操作する
        logger_instance.handlers.clear()
        logger_instance.addHandler(test_handler)
        # 必要であれば structlog の再設定も行う
        # structlog.configure(...)

    yield log_capture_string  # テスト関数に StringIO オブジェクトを渡す

    # テスト終了後、元のハンドラに戻す
    for logger_name, handlers in original_handlers.items():
        logger_instance = logging.getLogger(logger_name)
        logger_instance.handlers.clear()
        for handler in handlers:
            logger_instance.addHandler(handler)

    log_capture_string.close()
