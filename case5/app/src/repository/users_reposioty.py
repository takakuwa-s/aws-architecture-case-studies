from model.db_model import User
from repository.base_table_repository import BaseTableRepository


class UsersRepository(BaseTableRepository):
    def __init__(self, dynamodb, redis_client=None):
        super().__init__(dynamodb=dynamodb, table_model=User, redis_client=redis_client)
