# creating vpc
resource "aws_vpc" "main" {

  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-${var.project_environment}"
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.project_environment}"
  }
}

resource "aws_subnet" "public_subnets" {

  count = 3

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-${var.project_environment}-public_${count.index + 1}"
  }
}


resource "aws_subnet" "private_subnets" {

  count = 3

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 4, "${count.index + 3}")
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-${var.project_environment}-private_${count.index + 1}"
  }
}


# public route table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.project_environment}-public"
  }
}

resource "aws_route_table_association" "public_subnets" {

  count          = 3
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}



resource "aws_eip" "nat" {

  count  = var.enable_nat_gw == true ? 1 : 0
  domain = "vpc"
  tags = {
    Name = "${var.project_name}-${var.project_environment}-nat"
  }
}


resource "aws_nat_gateway" "ngw" {

  count = var.enable_nat_gw == true ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_subnets[0].id
  tags = {
    Name = "${var.project_name}-${var.project_environment}"
  }
  depends_on = [aws_internet_gateway.igw]

}


# private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.project_environment}-private"
  }
}


resource "aws_route" "nat_gw_route" {
  count                  = var.enable_nat_gw == true ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw[0].id
}


resource "aws_route_table_association" "private_subnets" {
  count          = 3
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_key_pair" "ssh_auth_key" {

  key_name   = "${var.project_name}-${var.project_environment}"
  public_key = file("${var.project_name}-${var.project_environment}.pub")
  tags = {

    "Name"        = "${var.project_name}-${var.project_environment}"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
}

# security group for bastion server

resource "aws_security_group" "bastion" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_environment}-bastion"
  description = "${var.project_name}-${var.project_environment}-bastion"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-bastion"
  }
}


resource "aws_security_group_rule" "bastion_ingress_ssh" {

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.bastion.id

}

# security group for loadbalancer server

resource "aws_security_group" "loadbalancer" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_environment}-loadbalancer"
  description = "${var.project_name}-${var.project_environment}-loadbalancer"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-loadbalancer"
  }
}


resource "aws_security_group_rule" "loadbalancer_ingress_rule" {
  for_each          = toset(var.loadbalancer_ingress_ports)
  type              = "ingress"
  from_port         = each.key
  to_port           = each.key
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.loadbalancer.id

}

# security group for loadbalancer server

resource "aws_security_group" "backend" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_environment}-backend"
  description = "${var.project_name}-${var.project_environment}-backend"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "${var.project_name}-${var.project_environment}-backend"
  }
}


resource "aws_security_group_rule" "backend_ingress_http" {

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.loadbalancer.id
  security_group_id        = aws_security_group.backend.id

}

resource "aws_security_group_rule" "backend_ingress_ssh" {

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.backend.id

}


resource "aws_instance" "bastion_instance" {

  subnet_id              = aws_subnet.public_subnets[1].id
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ssh_auth_key.key_name
  vpc_security_group_ids = [aws_security_group.backend.id]
  tags = {
    "Name"        = "${var.project_name}-${var.project_environment}-bastion"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_launch_template" "backend_instance_template" {

  name                   = "${var.project_name}-${var.project_environment}-template"
  description            = "${var.project_name}-${var.project_environment}-template"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ssh_auth_key.key_name
  image_id               = data.aws_ami.latest_image.image_id
  vpc_security_group_ids = [aws_security_group.backend.id]
  tags = {
    "Name"        = "${var.project_name}-${var.project_environment}-backend"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
}


resource "aws_autoscaling_group" "backend_instance_autoscaling_group" {
  name                      = "${var.project_name}-${var.project_environment}"
  max_size                  = var.asg_details["max_size"]
  min_size                  = var.asg_details["min_size"]
  health_check_grace_period = 120
  health_check_type         = var.asg_enable_elb_health_check ? "ELB" : "EC2"
  desired_capacity          = var.asg_details["desired_size"]
  vpc_zone_identifier       = aws_subnet.private_subnets[*].id



  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.project_environment}-backend"
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.backend_instance_template.id
    version = aws_launch_template.backend_instance_template.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120

    }
  }

}


resource "aws_lb_target_group" "frontend" {
  name                 = "${var.project_name}-${var.project_environment}-frontend"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 10

  health_check {

    path                = "/health.html"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }
}


resource "aws_autoscaling_attachment" "backend_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.backend_instance_autoscaling_group.id
  lb_target_group_arn    = aws_lb_target_group.frontend.arn
}

resource "aws_lb" "frontend" {
  name               = "${var.project_name}-${var.project_environment}-frontend"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer.id]
  subnets            = aws_subnet.public_subnets[*].id

  enable_deletion_protection = true

  tags = {
    Environment = "${var.project_name}-${var.project_environment}-frontend"
  }
}

resource "aws_lb_listener" "front_end_https_listner" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.elb_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "frontend_http_listner" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


resource "aws_route53_record" "frontend" {

  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "${var.hostname}.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.frontend.dns_name
    zone_id                = aws_lb.frontend.zone_id
    evaluate_target_health = true
  }
}

