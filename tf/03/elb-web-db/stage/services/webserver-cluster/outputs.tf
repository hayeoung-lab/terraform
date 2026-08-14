output "alb_dns_name" {
  description = "The domain name of the load balancer"
  value       = "http://${aws_lb.myALB.dns_name}"
}

