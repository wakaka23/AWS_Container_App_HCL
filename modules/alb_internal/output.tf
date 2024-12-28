output "alb_internal_dns_name" {
  value = aws_lb.internal.dns_name
}

output "alb_listener_internal_blue_arn" {
  value = aws_lb_listener.internal_blue.arn
}

output "alb_target_group_internal_blue_name" {
  value = aws_lb_target_group.internal_blue.name
}

output "alb_target_group_internal_blue_arn" {
  value = aws_lb_target_group.internal_blue.arn
}

output "alb_listener_internal_green_arn" {
  value = aws_lb_listener.internal_green.arn
}

output "alb_target_group_internal_green_name" {
  value = aws_lb_target_group.internal_green.name
}

output "alb_target_group_internal_green_arn" {
  value = aws_lb_target_group.internal_green.arn
}