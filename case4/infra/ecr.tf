# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
resource "aws_ecr_repository" "server" {
  name                 = "server-api"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
}

# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.server.repository_url}
      docker build -t server-api ../app/
      docker tag server-api:latest ${aws_ecr_repository.server.repository_url}:${var.ecr_image_version}
      docker push ${aws_ecr_repository.server.repository_url}:${var.ecr_image_version}
    EOT
  }

  depends_on = [aws_ecr_repository.server]

  triggers = {
    file_content_sha1 = filesha1("../app/Dockerfile")
  }
}