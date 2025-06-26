resource "aws_key_pair" "ssh_auth_key" {

  key_name   = "${var.project_name}-${var.project_environment}"
  public_key = file("${var.project_name}-${var.project_environment}.pub")
  tags = {

    "Name"        = "${var.project_name}-${var.project_environment}"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
}


resource "aws_security_group" "allow_webserver_traffic" {

  name        = "${var.project_name}-${var.project_environment}-webserver"
  description = "${var.project_name}-${var.project_environment}-webserver"

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name"        = "${var.project_name}-${var.project_environment}-webserver"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
}


resource "aws_instance" "webserver" {

  ami                    = data.aws_ami.latest_image.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.ssh_auth_key.key_name
  vpc_security_group_ids = [ aws_security_group.allow_webserver_traffic.id]
  tags = {
    "Name"        = "${var.project_name}-${var.project_environment}-webserver"
    "Project"     = var.project_name
    "Environment" = var.project_environment
  }
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_route53_record" "webserver_record" {

  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "${var.hostname}.${var.domain_name}"
  type    = "A"
  ttl     = 0
  records =  [ aws_instance.webserver.public_ip]

}
