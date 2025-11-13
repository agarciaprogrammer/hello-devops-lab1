variable "region" {
  type        = string
  description = "The AWS region to deploy resources in."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "The name of the project."
  default     = "hello-devops-lab1"
}