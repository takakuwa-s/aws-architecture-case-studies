#!/bin/bash

# 引数チェック
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <ECR_REPO_URL> <CLUSTER_NAME>"
  exit 1
fi

# 引数から変数に代入
ECR_REPO_URL=$1
CLUSTER_NAME=$2

echo "----- docker build -----"
docker build -t server-api .

echo "----- ecr get-login-password  -----"
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${ECR_REPO_URL}

echo "----- docker tag -----"
docker tag server-api:latest ${ECR_REPO_URL}:latest

echo "----- docker push -----"
docker push ${ECR_REPO_URL}:latest

echo "----- remove stopped docker containers -----"
docker container prune -f

echo "----- remove docker image -----"
docker image prune -f

echo "----- get list services -----"
SERVICES=$(aws ecs list-services --cluster ${CLUSTER_NAME} --region ap-northeast-1 --output text --query 'serviceArns[*]' | tr '\t' '\n' | awk -F'/' '{print $NF}')
echo ${SERVICES}

echo "----- ecr update -----"
for SERVICE in $SERVICES; do
  aws ecs update-service --cluster ${CLUSTER_NAME} --service ${SERVICE} --force-new-deployment --region ap-northeast-1 --no-cli-pager
done