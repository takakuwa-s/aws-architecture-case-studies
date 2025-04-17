output "api_gateway_info" {
  description = "API Gatewayの情報"
  value = {
    health = "curl -X GET ${module.ecs_app.api_gateway_url}/api/"
    url    = module.ecs_app.api_gateway_url
  }
}

output "ecs_ssm_session_info" {
  description = "ECSにSSMセッションを開始するための必要な情報"
  value       = <<EOT
    aws ecs execute-command \
      --cluster ${module.ecs_app.ecs_cluster_name} \
      --command "/bin/sh" \
      --interactive \
      --task 
    EOT
}

output "ecs_commands" {
  description = "ECSのコマンド集"
  value = {
    update_task_images = <<EOT
      ./deploy.sh \
        ${aws_ecr_repository.ecr.repository_url} \
        ${module.ecs_app.ecs_cluster_name}
    EOT
  }
}

output "eks_commands" {
  description = "EKSのコマンド集"
  value       = <<EOT
    aws eks update-kubeconfig --region ${local.aws_region} --name ${module.eks_app.eks_cluster_name}
    EOT
}