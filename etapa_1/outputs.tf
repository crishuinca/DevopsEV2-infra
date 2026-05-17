output "ecr_ventas" {
  value = aws_ecr_repository.backend_ventas.repository_url
}

output "ecr_despachos" {
  value = aws_ecr_repository.backend_despachos.repository_url
}

output "ecr_frontend" {
  value = aws_ecr_repository.frontend.repository_url
}
