from fastapi import FastAPI
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

@app.get("/api/ec2")
def call_ec2():
    return usecase.call_ec2()

@app.get("/api/ecs")
def call_ecs():
    return usecase.call_ecs()

@app.get("/api/eks")
def call_eks():
    return usecase.call_eks()