output "frontend_elb_public_dns" {
   value = aws_lb.frontend.dns_name
}

output "frontend_elb_http_url" {
   value = "http://${var.hostname}.${var.domain_name}"
}

output "frontend_elb_https_url" {
  value = "https://${var.hostname}.${var.domain_name}"
}
