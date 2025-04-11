#!/usr/bin/env python

import logging
import os  # os をインポート

import structlog
from pythonjsonlogger import jsonlogger


def get_logger(name):
    """structlogロガーを取得"""
    logger = logging.getLogger(name)
    handler = logging.StreamHandler()
    # JSON形式で出力、messageフィールドには純粋なメッセージのみ含める
    formatter = jsonlogger.JsonFormatter(
        "%(message)s %(filename)s %(lineno)d %(funcName)s %(exc_info)s"
    )
    handler.setFormatter(formatter)
    # 既存のハンドラをクリアしてから追加
    if logger.hasHandlers():
        logger.handlers.clear()
    logger.addHandler(handler)
    log_level_str = os.environ.get("LOG_LEVEL", "INFO").upper()
    log_level = getattr(logging, log_level_str, logging.INFO)
    logger.setLevel(log_level)
    return structlog.wrap_logger(logger)
