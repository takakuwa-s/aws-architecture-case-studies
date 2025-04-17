from config.logger import get_app_logger

class ApiUsecase:
    def __init__(self):
        self.logger = get_app_logger(__name__)
