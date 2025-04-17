# Pythonの公式イメージを使用
FROM python:3.11-slim

# 作業ディレクトリを作成
WORKDIR /app

# 必要なファイルをコンテナにコピー
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# AWS SSM Agent のインストール
RUN apt-get update && apt-get install -y \
    curl unzip && \
    curl -o /tmp/amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb && \
    dpkg -i /tmp/amazon-ssm-agent.deb && \
    rm -f /tmp/amazon-ssm-agent.deb && \
    apt-get clean

# アプリケーションのコードをコピー
COPY ./src .

# SSM Agent をバックグラウンドで起動
CMD nohup amazon-ssm-agent &
