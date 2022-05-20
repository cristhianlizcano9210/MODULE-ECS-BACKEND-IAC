output "this_task_definition_arn" {
  description = "Full ARN of the Task Definition"
  value       = module.task_definition.this_task_definition_arn
}

output "this_task_definition_family" {
  description = "The family of the Task Definition"
  value       = module.task_definition.this_task_definition_family
}

output "this_task_definition_revision" {
  description = "The revision of the task in a particular family"
  value       = module.task_definition.this_task_definition_revision
}

output "this_service_id" {
  description = "The Amazon Resource Name (ARN) that identifies the service"
  value       = module.service.this_service_id
}

output "this_service_name" {
  description = "The name of the service"
  value       = module.service.this_service_name
}

output "this_service_cluster" {
  description = "The Amazon Resource Name (ARN) of cluster which the service runs on"
  value       = module.service.this_service_cluster
}

output "this_service_iam_role" {
  description = "The ARN of IAM role used for ELB"
  value       = module.service.this_service_iam_role
}

output "this_service_desired_count" {
  description = "The number of instances of the task definition"
  value       = module.service.this_service_desired_count
}

output "this_ecr_arn" {
  description = "Full ARN of the repository"
  value       = module.ecr.this_ecr_arn
}

output "this_ecr_name" {
  description = "The name of the repository"
  value       = module.ecr.this_ecr_name
}

output "this_ecr_registry_id" {
  description = "The registry ID where the repository was created"
  value       = module.ecr.this_ecr_registry_id
}

output "this_ecr_repository_url" {
  description = "The URL of the repository"
  value       = module.ecr.this_ecr_repository_url
}

output "sg_id" {
  description = "Security group ID"
  value       = element(concat(aws_security_group.this.*.id, [""]), 0)
}
