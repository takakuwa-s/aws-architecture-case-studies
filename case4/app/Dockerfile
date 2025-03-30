# ベースイメージとしてAmazon Linux 2を使用
FROM amazonlinux:2

# 必要なパッケージをインストール
RUN yum update -y && \
    amazon-linux-extras install -y epel && \
    yum install -y nginx

# ファイルをコピー
COPY index.html /usr/share/nginx/html/index.html
COPY index2.html /usr/share/nginx/html/index2.html
COPY index.html /usr/share/nginx/html/app1/index.html
COPY index2.html /usr/share/nginx/html/app2/index.html
COPY test.json /usr/share/nginx/html/app1/test.json
COPY test2.json /usr/share/nginx/html/app2/test2.json

# nginxを起動
CMD ["nginx", "-g", "daemon off;"]

# 80番ポートを公開
EXPOSE 80