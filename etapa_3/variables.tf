variable "aws_region" {
  description = "Región AWS del Learner Lab"
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo de recursos Innovatech"
  default     = "innovatech"
}

variable "cluster_name" {
  description = "Nombre del clúster EKS"
  default     = "innovatech-cluster"
}

variable "node_instance_type" {
  description = "Tipo de instancia para los nodos worker"
  default     = "t3.medium"
}

variable "node_desired_size" {
  default = 2
}

variable "node_min_size" {
  default = 1
}

variable "node_max_size" {
  default = 3
}
