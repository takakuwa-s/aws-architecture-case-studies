output "eks_cluster_name" {
  description = "EKSのクラスター名"
  value       = aws_eks_cluster.main.name
}