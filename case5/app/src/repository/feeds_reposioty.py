from model.db_model import Feed, Post
from repository.base_table_repository import BaseTableRepository


class FeedsRepository(BaseTableRepository):
    def __init__(self, dynamodb, redis_client=None):
        super().__init__(dynamodb=dynamodb, table_model=Feed, redis_client=redis_client)

    def add_feed(self, user_id: str, post: Post):
        """
        指定されたユーザーにフィードを追加します。

        Args:
            user_id (str): ユーザーのID
            post (Post): 投稿オブジェクト
        """
        feed = Feed(
            user_id=user_id,
            post_id=post.post_id,
            post_user_id=post.user_id,
            message=post.message,
        )
        self.put_item(feed.model_dump())
