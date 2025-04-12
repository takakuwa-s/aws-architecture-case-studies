import os
from listener.sqs_listener import SqsListener
from usecase.process_celebrity_user_usecase import ProcessCelebrityUserUsecase

queue_url = os.getenv("CELEBRITY_QUEUE_URL")

if __name__ == "__main__":
    listener = SqsListener(queue_url = queue_url, usecase=ProcessCelebrityUserUsecase())
    listener.poll_messages()