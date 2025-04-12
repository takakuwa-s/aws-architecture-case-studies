from usecase.queue_usecase import QueueUsecase

class ProcessCelebrityUserUsecase(QueueUsecase):
    def __init__(self):
        super().__init__()
        self.target_user = "celebrity"