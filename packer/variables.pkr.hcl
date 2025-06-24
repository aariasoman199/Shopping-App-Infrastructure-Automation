variable "project_name" {
  type    = string
  default = "shopping"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "base_ami_id" {
  default = "ami-0b09627181c8d5778"
}

locals {
  image_timestamp = formatdate("DD-MM-YYYY-hh-mm", timestamp())
  ami_name        = "${var.project_name}-${var.environment}-${local.image_timestamp}"
}
