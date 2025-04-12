import boto3
import os
import redis
from config.logger import get_app_logger
from model.db_model import Post
from repository.posts_reposioty import PostsRepository
from repository.feeds_reposioty import FeedsRepository
from repository.users_reposioty import UsersRepository


queue_url = os.getenv("SQS_QUEUE_URL")
REDIS_HOST = os.getenv("REDIS_HOST")
REDIS_PORT = os.getenv("REDIS_PORT")
dynamodb = boto3.resource("dynamodb")
sqs = boto3.resource("sqs")

redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
# redis_client = None

class ApiUsecase:
    def __init__(self):
        self.posts_repository = PostsRepository(dynamodb, redis_client)
        self.feeds_repository = FeedsRepository(dynamodb, redis_client)
        self.users_repository = UsersRepository(dynamodb, redis_client)
        self.logger = get_app_logger(__name__)

    def feeds(self, user_id: str):
        try:
            items = self.feeds_repository.get_cache(user_id)
            if items:
                return items
            items = self.feeds_repository.query_items(user_id)
            return items
        except Exception as e:
            return {"error": str(e)}

    def get_user(self, user_id: str):
        try:
            items = self.users_repository.get_item(user_id)
            return items
        except Exception as e:
            return {"error": str(e)}

    def post(self, message: Post):
        try:
            self.posts_repository.put_item(message.model_dump())
            return {"message": "Item added successfully"}
        except Exception as e:
            return {"error": str(e)}
