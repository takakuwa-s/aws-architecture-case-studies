import os
from listener.sqs_listener import SqsListener
from usecase.process_normal_user_usecase import ProcessNormalUserUsecase

queue_url = os.getenv("NORMAL_QUEUE_URL")

if __name__ == "__main__":
    listener = SqsListener(queue_url = queue_url, usecase=ProcessNormalUserUsecase())
    listener.poll_messages()