output "instance_ids" {
  value = values(aws_instance.main)[*].id
}