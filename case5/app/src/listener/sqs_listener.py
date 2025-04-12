import boto3
import json
import time
from config.logger import get_app_logger
from usecase.queue_usecase import QueueUsecase

class SqsListener:
    def __init__(self, queue_url: str, usecase: QueueUsecase):
        self.queue_url = queue_url
        self.usecase = usecase
        self.sqs = boto3.client("sqs")
        self.logger = get_app_logger(__name__)

    def poll_messages(self):
        while True:
            # https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sqs/client/receive_message.html
            response = self.sqs.receive_message(
                QueueUrl=self.queue_url,
                MaxNumberOfMessages=10,
                WaitTimeSeconds=20
            )

            messages = response.get('Messages', [])
            if not messages:
                self.logger.info("メッセージなし。待機中...")

                # メッセージがない時に、無駄なAPIコールを避けるために、少し待機
                time.sleep(1)
                continue

            for message in messages:
                self.logger.info("successfully receive the message: %s", message)
                try:
                    receipt_handle = message['ReceiptHandle']
                    sqs_body = json.loads(message['Body'])
                    dynamodb_event = sqs_body['detail']

                    # メッセージを処理
                    self.usecase.process_message(dynamodb_event)

                    # 処理後に削除
                    self.sqs.delete_message(
                        QueueUrl=self.queue_url,
                        ReceiptHandle=receipt_handle
                    )

                    self.logger.info("メッセージを削除しました。")

                except Exception as e:
                    self.logger.error("処理中にエラー:", str(e))