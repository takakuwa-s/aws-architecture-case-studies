from contextvars import ContextVar
from datetime import datetime
import json
from logging import config, Formatter, getLogger
import os
from model.log_model import LogExtraInfo, LogMessage

ENV_CONTEXT = os.environ["ENV_CONTEXT"]

class LogContext:
    context: ContextVar = ContextVar("logging_context", default=LogExtraInfo())

    @classmethod
    def set(
        cls,
        user_id: str = None,
    ):
        """ログコンテキストを設定する"""
        info: LogExtraInfo = LogContext.context.get()
        if user_id:
            info.user_id = user_id
        cls.context.set(info)


class CustomFormatter(Formatter):
    def format(self, record):
        """ログレコードのフォーマットをカスタマイズする
            参考: https://docs.python.org/ja/3.13/library/logging.html#logrecord-attributes
        Args:
            record (LogRecord): ログレコード
        Returns:
            str: フォーマット後のログメッセージ
        """
        info: LogExtraInfo = LogContext.context.get()
        # ログメッセージのモデルをJSON形式で作成
        message = LogMessage(
            timestamp=datetime.fromtimestamp(record.created).isoformat(),
            level=record.levelname,
            message=record.getMessage(),
            env_context=ENV_CONTEXT,
            file=record.filename,
            line=record.lineno,
            function=record.funcName,
            extra_info=info,
        )
        return message.model_dump_json(exclude_none=True)


def get_app_logger(name=None):
    """アプリケーション用のロガーを取得する
    Args:
        name (str): ロガー名
    Returns:
        Logger: ロガー
    """
    with open("./config/log_config.json", "r") as f:
        json_config = json.load(f)
    config.dictConfig(json_config)
    return getLogger(name)


if __name__ == "__main__":
    logger = get_app_logger(__name__)
    logger.info("test")
