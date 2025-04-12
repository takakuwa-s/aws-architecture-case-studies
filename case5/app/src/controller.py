from fastapi import FastAPI
from model.db_model import Post
from usecase.api_usecase import ApiUsecase
from config.logger import get_app_logger

app = FastAPI()
logger = get_app_logger(__name__)
usecase = ApiUsecase()

@app.get("/")
def root_health():
    return {"message": "Hello, FastAPI!"}

@app.get("/api/")
def health():
    return {"message": "Hello, from API"}

@app.get("/api/feeds/{user_id}")
def feeds(user_id: str):
    return usecase.feeds(user_id)
    
@app.get("/api/users/{user_id}")
def get_user(user_id: str):
    return usecase.get_user(user_id)

@app.post("/api/post/")
def post(message: Post):
    logger.info(f"/api/post/ endpoint received, body: {message}")
    return usecase.post(message)