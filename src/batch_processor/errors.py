"""
エラー処理用のカスタム例外クラスを定義するモジュール
"""


class BatchProcessingError(Exception):
    """
    バッチ処理の基本例外クラス
    すべてのカスタム例外の基底クラスとして使用
    """

    def __init__(
        self, message: str, code: str = "E000", details: dict | None = None
    ):
        """
        初期化

        Args:
            message: エラーメッセージ
            code: エラーコード
            details: エラーの詳細情報を含む辞書
        """
        self.message = message
        self.code = code
        self.details = details or {}
        super().__init__(self.message)

    def __str__(self):
        return f"[{self.code}] {self.message}"


class ConfigError(BatchProcessingError):
    """
    設定関連のエラー
    パラメータのパース失敗など
    """

    def __init__(self, message: str, param_name: str | None = None, **kwargs):
        """
        初期化

        Args:
            message: エラーメッセージ
            param_name: 問題のあったパラメータ名
            **kwargs: その他の詳細情報
        """
        details = {"param_name": param_name, **kwargs} if param_name else kwargs
        super().__init__(message, code="E001", details=details)


class DataValidationError(BatchProcessingError):
    """
    データ検証エラー
    スキーマ検証失敗など
    """

    def __init__(self, message: str, schema_name: str | None = None, **kwargs):
        """
        初期化

        Args:
            message: エラーメッセージ
            schema_name: 問題のあったスキーマ名
            **kwargs: その他の詳細情報
        """
        details = {"schema_name": schema_name, **kwargs} if schema_name else kwargs
        super().__init__(message, code="E002", details=details)


class FileFormatError(BatchProcessingError):
    """
    ファイル形式エラー
    CSVフォーマットエラーなど
    """

    def __init__(
        self,
        message: str,
        file_path: str | None = None,
        line_number: int | None = None,
        **kwargs,
    ):
        """
        初期化

        Args:
            message: エラーメッセージ
            file_path: 問題のあったファイルパス
            line_number: 問題のあった行番号
            **kwargs: その他の詳細情報
        """
        details = kwargs
        if file_path:
            details["file_path"] = file_path
        if line_number is not None:
            details["line_number"] = line_number
        super().__init__(message, code="E003", details=details)


class ProcessingError(BatchProcessingError):
    """
    処理中のエラー
    データ処理中の問題など
    """

    def __init__(
        self,
        message: str,
        process_id: str | None = None,
        step: str | None = None,
        **kwargs,
    ):
        """
        初期化

        Args:
            message: エラーメッセージ
            process_id: 処理ID
            step: エラーが発生したステップ
            **kwargs: その他の詳細情報
        """
        details = kwargs
        if process_id:
            details["process_id"] = process_id
        if step:
            details["step"] = step
        super().__init__(message, code="E004", details=details)


class ResourceError(BatchProcessingError):
    """
    リソースエラー
    S3バケットアクセス失敗など
    """

    def __init__(
        self,
        message: str,
        resource_type: str | None = None,
        resource_name: str | None = None,
        **kwargs,
    ):
        """
        初期化

        Args:
            message: エラーメッセージ
            resource_type: リソースタイプ (s3、dynamodbなど)
            resource_name: リソース名
            **kwargs: その他の詳細情報
        """
        details = kwargs
        if resource_type:
            details["resource_type"] = resource_type
        if resource_name:
            details["resource_name"] = resource_name
        super().__init__(message, code="E005", details=details)
