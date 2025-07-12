project_name               = "shopping"
project_environment        = "production"
domain_name                = "chottu.shop"
hostname                   = "shopping-app"
vpc_cidr_block             = "172.16.0.0/16"
enable_nat_gw              = true
loadbalancer_ingress_ports = ["80", "443"]
ami_id                     = "ami-0b09627181c8d5778"
asg_details = {
  min_size     = 2
  max_size     = 2
  desired_size = 2
}
asg_enable_elb_health_check = false
