output "api_gateway_info" {
  description = "API Gatewayの情報"
  value = {
    ecs = {
      health = "curl -X GET ${module.ecs_app.api_gateway_url}/api/"
      ec2    = "curl -X GET ${module.ecs_app.api_gateway_url}/api/ec2"
      eks    = "curl -X GET ${module.ecs_app.api_gateway_url}/api/eks"
      url    = module.ecs_app.api_gateway_url
    }
    ec2 = "curl -X GET ${module.ec2_app.api_gateway_url}"
    eks = {
      health = "curl -X GET ${module.ecs_app.api_gateway_url}/api/"
    }
  }
}

output "ecs_commands" {
  description = "ECSのコマンド集"
  value = {
    update_task_images = <<EOT
      ./deploy.sh \
        ${aws_ecr_repository.ecr.repository_url} \
        ${module.ecs_app.ecs_cluster_name}
    EOT
    ssm_comand         = <<EOT
      aws ecs execute-command \
        --cluster ${module.ecs_app.ecs_cluster_name} \
        --command "/bin/sh" \
        --interactive \
        --task 
    EOT
  }
}

output "ecr_image_url" {
  description = "ECRのイメージURL"
  value       = local.ecr_image_url
}

output "eks_commands" {
  description = "EKSのコマンド集"
  value       = <<EOT
    aws eks update-kubeconfig --region ${local.aws_region} --name ${module.eks_app.eks_cluster_name}
    EOT
}