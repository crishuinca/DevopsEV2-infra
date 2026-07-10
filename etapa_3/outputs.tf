output "cluster_name" {
  description = "Nombre del clúster EKS (secret CLUSTER_NAME en GitHub Actions)"
  value       = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  description = "Endpoint del API server de EKS"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_arn" {
  description = "ARN del clúster EKS"
  value       = aws_eks_cluster.eks.arn
}

output "aws_region" {
  description = "Región donde corre el clúster"
  value       = var.aws_region
}

output "vpc_id" {
  description = "ID de la VPC del clúster"
  value       = aws_vpc.eks_vpc.id
}

output "eks_cluster_security_group_id" {
  description = "Security group del control plane EKS"
  value       = aws_security_group.eks_cluster_sg.id
}

output "eks_node_security_group_id" {
  description = "Security group de los nodos worker"
  value       = aws_security_group.eks_node_sg.id
}

output "cloudwatch_log_group" {
  description = "Log group de CloudWatch para logs del cluster EKS"
  value       = aws_cloudwatch_log_group.eks.name
}

output "configure_kubectl" {
  description = "Comando para conectar kubectl al clúster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.eks.name}"
}
