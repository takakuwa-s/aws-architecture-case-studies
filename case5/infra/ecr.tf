# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
resource "aws_ecr_repository" "server" {
  name                 = "server-app"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
}

# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    command = <<EOT
      echo "----- ecr get-login-password  -----"
      aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.server.repository_url}

      echo "----- docker build -----"
      docker build -t server-api ../app/

      echo "----- docker tag server-api:latest ${aws_ecr_repository.server.repository_url}:latest -----"
      docker tag server-api:latest ${aws_ecr_repository.server.repository_url}:latest

      echo "----- docker push ${aws_ecr_repository.server.repository_url}:latest -----"
      docker push ${aws_ecr_repository.server.repository_url}:latest
    EOT
  }

  depends_on = [aws_ecr_repository.server]

  triggers = {
    file_content_sha1 = filesha1("../app/Dockerfile")
  }
}