variable "project_name" {

  description = "my project name"
  type        = string
}

variable "project_environment" {

  description = "my project environment"
  type        = string
}

variable "domain_name" {

  description = "domain name"
  type        = string
}

variable "hostname" {

  description = "my hostname"
  type        = string

}

variable "vpc_cidr_block" {

  description = "vpc cidr block"
  type        = string
}

variable "enable_nat_gw" {

  description = "Set true to enable nat gw"
  type        = bool
}

variable "loadbalancer_ingress_ports" {

  description = "loadbalancer ingress ports"
  type        = list(string)
}

variable "ami_id" {
  description = "ami id for bastion instance"
  type        = string
}

variable "asg_details" {
  description = "Autoscaling group min, max and desired sixe"
  type        = map(any)
}

variable "asg_enable_elb_health_check" {
  description = "Set true to enable health check type to ELB"
  type        = bool
}
