from model.db_model import Post
from repository.base_table_repository import BaseTableRepository


class PostsRepository(BaseTableRepository):
    def __init__(self, dynamodb, redis_client=None):
        super().__init__(dynamodb=dynamodb, table_model=Post, redis_client=redis_client)
