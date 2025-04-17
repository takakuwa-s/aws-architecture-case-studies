# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
resource "aws_eks_cluster" "main" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.iam_roles["eks_cluster_role"].arn

  vpc_config {
    subnet_ids = var.network.private_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
# resource "aws_eks_node_group" "eks_node_group" {
#   cluster_name    = aws_eks_cluster.main.name
#   node_group_name = "eks-node-group"
#   node_role_arn   = aws_iam_role.iam_roles["eks_node_role"].arn
#   subnet_ids      = var.network.private_subnet_ids

#   scaling_config {
#     desired_size = 1
#     max_size     = 3
#     min_size     = 1
#   }

#   instance_types = ["t3.medium"]

#   depends_on = [
#     aws_iam_role_policy_attachment.node_worker_node_policy,
#     aws_iam_role_policy_attachment.cni_policy,
#     aws_iam_role_policy_attachment.registry_readonly
#   ]
# }
