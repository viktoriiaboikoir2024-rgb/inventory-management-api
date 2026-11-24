variable "db_username" {
  description = "Database administrator username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}
variable "image_tag" {
  description = "Docker image tag in Amazon ECR"
  type        = string
  default     = "bootstrap"
}