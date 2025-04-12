import datetime
from pydantic import Field
from model.common_model import CommonModel
from ulid import ULID


class BaseTable(CommonModel):
    @staticmethod
    def get_name() -> str:
        raise NotImplementedError

    @staticmethod
    def get_parttion_key() -> str:
        """
        パーティションキーを持つ場合は、パーティションキー名を返す。
        パーティションキーが存在しない場合はNoneを返す
        """
        raise NotImplementedError

    @staticmethod
    def get_sort_key() -> str:
        """
        ソートキーを持つ場合は、ソートキー名を返す。
        ソートキーが存在しない場合はNoneを返す
        """
        raise NotImplementedError

    @staticmethod
    def get_current_timestamp() -> str:
        """
        現在のタイムスタンプを取得する
        """
        return datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).isoformat()


class User(BaseTable):
    user_id: str = Field(default="")  # パーティションキー
    name: str = Field(default="")
    follower: list[str] = Field(default=[])
    followee: list[str] = Field(default=[])

    @staticmethod
    def get_name() -> str:
        return "case5_users"

    @staticmethod
    def get_parttion_key() -> str:
        return "user_id"

    @staticmethod
    def get_sort_key() -> str:
        return None

class Post(BaseTable):
    post_id: str = Field(default_factory=lambda: str(ULID()))  # パーティションキー
    user_id: str = Field(default="")
    message: str = Field(default="")
    is_celebrity: bool = Field(default=False)
    timestamp: str = Field(default_factory=BaseTable.get_current_timestamp)

    @staticmethod
    def get_name() -> str:
        return "case5_posts"

    @staticmethod
    def get_parttion_key() -> str:
        return "post_id"

    @staticmethod
    def get_sort_key() -> str:
        return None

class Feed(BaseTable):
    user_id: str = Field(default="")  # パーティションキー
    timestamp: str = Field(default_factory=BaseTable.get_current_timestamp)  # ソートキー
    post_id: str = Field(default="")
    post_user_id: str = Field(default="")
    message: str = Field(default="")

    @staticmethod
    def get_name() -> str:
        return "case5_feeds"

    @staticmethod
    def get_parttion_key() -> str:
        return "user_id"

    @staticmethod
    def get_sort_key() -> str:
        return "timestamp"

