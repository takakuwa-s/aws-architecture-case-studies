import requests
from config.logger import get_app_logger

class ApiAdaptor:
    def __init__(self):
        self.logger = get_app_logger(__name__)

    def send_get_request(self, url, params=None) -> str:
        try:
            self.logger.info(f"get request start, URL: {url}, パラメータ: {params}")
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            self.logger.info(f"request success! status code: {response.status_code}, response: {response.text}")
            return response.text
        except requests.exceptions.RequestException as e:
            self.logger.error(f"request error: {e}")
