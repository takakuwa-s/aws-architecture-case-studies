import os
from config.logger import get_app_logger
from adaptor.api_adaptor import ApiAdaptor

EC2_ENDPOINT = os.getenv("EC2_ENDPOINT")
ECS_ENDPOINT = os.getenv("ECS_ENDPOINT")
EKS_ENDPOINT = os.getenv("EKS_ENDPOINT")

class ApiUsecase:
    def __init__(self):
        self.logger = get_app_logger(__name__)
        self.adaptor = ApiAdaptor()
    
    def call_ec2(self):
        return self.adaptor.send_get_request(EC2_ENDPOINT)
    
    def call_ecs(self):
        return self.adaptor.send_get_request(ECS_ENDPOINT)

    def call_eks(self):
        return self.adaptor.send_get_request(EKS_ENDPOINT)