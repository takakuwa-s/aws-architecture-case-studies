import boto3
import os
import redis
from model.db_model import Post, User
from config.logger import get_app_logger
from repository.posts_reposioty import PostsRepository
from repository.feeds_reposioty import FeedsRepository
from repository.users_reposioty import UsersRepository


queue_url = os.getenv("SQS_QUEUE_URL")
REDIS_HOST = os.getenv("REDIS_HOST")
REDIS_PORT = os.getenv("REDIS_PORT")

# DynamoDBリソースの作成
dynamodb = boto3.resource("dynamodb")
sqs = boto3.resource("sqs")
redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)
# redis_client = None

class QueueUsecase:
    def __init__(self):
        self.target_user = ""
        self.posts_repository = PostsRepository(dynamodb, redis_client)
        self.feeds_repository = FeedsRepository(dynamodb, redis_client)
        self.users_repository = UsersRepository(dynamodb, redis_client)
        self.logger = get_app_logger(__name__)

    def process_message(self, message_body: dict):
        self.logger.info(f"{self.target_user}: start process_message, message_body: ${message_body}")
        post_id = message_body.get("dynamodb", {}).get("Keys", {}).get("post_id", {}).get("S")
        post: Post = self.posts_repository.get_item(post_id)
        user: User = self.users_repository.get_item(post.user_id)
        for follower_id in user.followee:
            self.feeds_repository.add_feed(follower_id, post)
        self.logger.info(f"{self.target_user}: end process_message")